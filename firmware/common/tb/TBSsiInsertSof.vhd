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
use work.TestingPkg.all;

entity TBSsiInsertSof is end TBSsiInsertSof;

architecture testbed of TBSsiInsertSof is

   constant AXI_BASE_ADDR_G   : slv(31 downto 0) := x"00C0_0000";

   constant TPD_G             : time             := 1 ns;

   constant DMA_SIZE_C        : positive         := 1;

   constant NUM_AXI_MASTERS_C : positive         := 3;
   constant NUM_MASTERS_G     : positive         := 3;

   ----------------------------
   ----------------------------
   ----------------------------
   constant NUM_AXIL_MASTERS_C : natural := NUM_MASTERS_G;

   constant PRESCALE_INDEX_C    : natural := 0;
   constant NULL_FILTER_INDEX_C : natural := 1;
   constant HEADER_APPENDER_C   : natural := 2;

   subtype AXIL_INDEX_RANGE_C is integer range NUM_AXIL_MASTERS_C-1 downto 0;

   constant AXIL_CONFIG_C  : AxiLiteCrossbarMasterConfigArray(AXIL_INDEX_RANGE_C) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 20, 16);

 
   ----------------------------
   ----------------------------
   ----------------------------


   constant DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);

   constant CLK_PERIOD_G : time := 10 ns;

   constant SRC_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 4, -- 128 bits
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_FIRST_LAST_C);

   signal userClk156   : sl;
   signal dmaClk       : sl;
   signal dmaRst       : sl;

   signal appInMaster  : AxiStreamMasterType;
   signal appInSlave   : AxiStreamSlaveType;
   signal appOutMaster : AxiStreamMasterType;
   signal appOutSlave  : AxiStreamSlaveType;

   signal PrescalerToNullFilterMaster  : AxiStreamMasterType;
   signal PrescalerToNullFilterSlave   : AxiStreamSlaveType;

   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;
   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;

   signal axilWriteMasters : AxiLiteWriteMasterArray(AXIL_INDEX_RANGE_C);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_INDEX_RANGE_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(AXIL_INDEX_RANGE_C);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(AXIL_INDEX_RANGE_C);



   signal axiClk   : sl;
   signal axiRst   : sl;

   signal axilClk   : sl;
   signal axilRst   : sl;

begin

   appOutSlave.tReady <= '1';
   axilClk            <= axiClk;
   axilRst            <= axiRst;
   
   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

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


      U_CamOutput : entity work.FileToAxiStreamSim
         generic map (
            TPD_G         => TPD_G,
            BYTE_SIZE_C   => 2+1,
            AXIS_CONFIG_G => SRC_CONFIG_C)
         port map (
            axiClk      => axiClk,
            axiRst      => axiRst,
            mAxisMaster => appInMaster,
            mAxisSlave  => appInSlave);

   --------------------
   -- Modules to be tested
   --------------------  


   U_TimeToolPrescaler : entity work.TimeToolPrescaler
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- System Clock and Reset
         sysClk          => dmaClk,
         sysRst          => dmaRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => appInMaster,
         dataInSlave     => appInSlave,
         dataOutMaster   => PrescalerToNullFilterMaster,
         dataOutSlave    => PrescalerToNullFilterSlave,
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(PRESCALE_INDEX_C),
         axilReadSlave   => axilReadSlaves(PRESCALE_INDEX_C),
         axilWriteMaster => axilWriteMasters(PRESCALE_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PRESCALE_INDEX_C));

   U_HEADER_APPENDER : entity work.SsiInsertSof
      generic map (
         COMMON_CLK_G       => true,
         INSERT_USER_HDR_G  => true,
         SLAVE_FIFO_G       => false,
         MASTER_FIFO_G      => false)
      port map (
         -- System Clock and Reset
         sAxisClk        => dmaClk,
         SAxisRst        => dmaRst,
         mAxisClk        => dmaClk,
         mAxisRst        => dmaRst,
         -- DMA Interface (sysClk domain)
         sAxisMaster     => PrescalerToNullFilterMaster,
         sAxisSlave      => PrescalerToNullFilterSlave,
         mUserHdr        => (5 downto 3 =>'1',others => '0'),
         mAxisMaster     => appOutMaster,
         mAxisSlave      => appOutSlave);  
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

      axiLiteBusSimWrite (axiClk, axilWriteMaster, axilWriteSlave, x"00C0_0004", x"7", true);

   end process test;

end testbed;
