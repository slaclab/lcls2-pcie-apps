-------------------------------------------------------------------------------
-- File       : TimeToolKcu1500.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-24
-- Last update: 2018-11-08
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-dev'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-dev', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPciePkg.all;
use work.TimingPkg.all;
use work.Pgp2bPkg.all;
use work.SsiPkg.all;

use STD.textio.all;
use ieee.std_logic_textio.all;

entity TBIIR_filter is end TBIIR_filter;

architecture testbed of TBIIR_filter is

   constant TPD_G                    : time := 1 ns;
   --constant BUILD_INFO_G           : BuildInfoType;

   constant DMA_SIZE_C               : positive := 1;

   constant NUM_AXI_MASTERS_C        : positive := 2;

   constant AXI_CONFIG_C             : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, x"0080_0000", 23, 22);

   constant DMA_AXIS_CONFIG_C        : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);  -- 16 byte (128-bit) AXIS interface

   constant CLK_PERIOD_G : time      := 10 ns;

   constant INT_CONFIG_C             : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes=>16,tDestBits=>0);
   constant DMA_AXIS_CONFIG_G        : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);
   constant SRC_CONFIG_C             : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 16, -- 128 bits
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_FIRST_LAST_C);

   signal userClk156   : sl;
   signal dmaClk       : sl;
   signal dmaRst       : sl;
   signal dmaObMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0);
   signal dmaObSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0);
   signal dmaIbMasters : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0);
   signal dmaIbSlaves  : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0);
   signal hwIbMasters  : AxiStreamMasterArray(DMA_SIZE_C-1 downto 0);
   signal hwIbSlaves   : AxiStreamSlaveArray(DMA_SIZE_C-1 downto 0);

   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal intReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal intReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal intWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal intWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal appInMaster  : AxiStreamMasterType;
   signal appInSlave   : AxiStreamSlaveType;
   signal appOutMaster : AxiStreamMasterType;
   signal appOutSlave  : AxiStreamSlaveType;

   signal timingBus : TimingBusType;

   signal pgpTxClk : slv(DMA_SIZE_C-1 downto 0);
   signal pgpTxIn  : Pgp2bTxInArray(DMA_SIZE_C-1 downto 0);

   signal axiClk   : sl;
   signal axiRst   : sl;

   signal testInMaster    : AxiStreamMasterType;

   file file_RESULTS : text;

   begin

         appOutSlave.tReady <= '1';      -- this is NOT crashing simulation

         --------------------
         -- Clocks and Resets
         --------------------
         U_axilClk_2 : entity work.ClkRst
            generic map (
               CLK_PERIOD_G      => CLK_PERIOD_G,
               RST_START_DELAY_G => 0 ns,
               RST_HOLD_TIME_G   => 1000 ns)
            port map (
               clkP => dmaClk,
               rst  => dmaRst);


         --------------------
         -- Clocks and Resets
         --------------------
         U_axilClk : entity work.ClkRst
            generic map (
               CLK_PERIOD_G      => CLK_PERIOD_G,
               RST_START_DELAY_G => 0 ns,
               RST_HOLD_TIME_G   => 1000 ns)
            port map (
               clkP => axiClk,
               rst  => axiRst);

         --------------------
         -- Test data
         --------------------  

            U_PackTx : entity work.FileToAxiStreamSim
               generic map (
                  TPD_G         => TPD_G,
                  BYTE_SIZE_C   => 2+1,
                  AXIS_CONFIG_G => SRC_CONFIG_C)
               port map (
                  axiClk      => dmaClk,
                  axiRst      => dmaRst,
                  mAxisMaster => appInMaster);

         U_OutFifo: entity work.AxiStreamFifoV2
            generic map (
               TPD_G               => TPD_G,
               SLAVE_READY_EN_G    => false,
               GEN_SYNC_FIFO_G     => true,
               FIFO_ADDR_WIDTH_G   => 9,
               FIFO_PAUSE_THRESH_G => 500,
               SLAVE_AXI_CONFIG_G  => INT_CONFIG_C,
               MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
            port map (
               sAxisClk    => dmaClk,
               sAxisRst    => dmaRst,
               sAxisMaster => appInMaster,
               --sAxisCtrl   => outCtrl,
               mAxisClk    => dmaClk,
               mAxisRst    => dmaRst,
               mAxisMaster => appOutMaster,
               mAxisSlave  => appOutSlave);

         --------------------
         -- Modules to be tested
         --------------------  

         U_XBAR : entity work.AxiLiteCrossbar
            generic map (
               TPD_G              => TPD_G,
               NUM_SLAVE_SLOTS_G  => 1,
               NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
               MASTERS_CONFIG_G   => AXI_CONFIG_C)
            port map (
               axiClk              => dmaClk,
               axiClkRst           => dmaRst,
               sAxiWriteMasters(0) => axilWriteMaster,
               sAxiWriteSlaves(0)  => axilWriteSlave,
               sAxiReadMasters(0)  => axilReadMaster,
               sAxiReadSlaves(0)   => axilReadSlave,
               mAxiWriteMasters    => intWriteMasters,
               mAxiWriteSlaves     => intWriteSlaves,
               mAxiReadMasters     => intReadMasters,
               mAxiReadSlaves      => intReadSlaves);

   

   ---------------------------------
   -- AXI-Lite Register Transactions
   ---------------------------------
   test : process is
      variable debugData : slv(31 downto 0) := (others => '0');
   begin
      debugData := x"1111_1111";
      ------------------------------------------
      -- Wait for the AXI-Lite reset to complete
      ------------------------------------------
      wait until axiRst = '1';
      wait until axiRst = '0';

      axiLiteBusSimWrite (axiClk, axilWriteMaster, axilWriteSlave, x"00d0_0000", x"3", true);
      axiLiteBusSimWrite (axiClk, axilWriteMaster, axilWriteSlave, x"00c0_0000", x"aa", true);

   end process test;


   ---------------------------------
   -- save_file
   ---------------------------------
   save_to_file : process is
      variable to_file              : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      variable v_OLINE              : line; 
      constant c_WIDTH              : natural := 8;
      constant test_data_to_file    : slv(c_WIDTH -1 downto 0) := (others => '0');

   begin

      to_file := appOutMaster;

      file_open(file_RESULTS, "output_results.txt", write_mode);

      while true loop

            write(v_OLINE, appOutMaster.tData(7 downto 0), right, c_WIDTH);   -- only seven bits to reduce file writing size
            writeline(file_RESULTS, v_OLINE);

            wait for CLK_PERIOD_G;

      end loop;
      
      file_close(file_RESULTS);

   end process save_to_file;


end testbed;
