-------------------------------------------------------------------------------
-- File       : AxiVersionTb.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation Testbed for testing the AxiVersionTb module
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC Firmware Standard Library', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.BuildInfoPkg.all;

use work.AxiStreamPkg.all;
use work.TimingPkg.all;
use work.Pgp2bPkg.all;

entity TimeToolCoreTB is end TimeToolCoreTB;

architecture testbed of TimeToolCoreTB is

   constant DMA_SIZE_C : positive := 1;
   constant NUM_AXI_MASTERS_C : natural := 2;
   constant AXI_BASE_ADDR_G   : slv(31 downto 0)    := x"0000_0000";

   constant GET_BUILD_INFO_C : BuildInfoRetType := toBuildInfo(BUILD_INFO_C);
   constant MOD_BUILD_INFO_C : BuildInfoRetType := (
      buildString => GET_BUILD_INFO_C.buildString,
      fwVersion   => GET_BUILD_INFO_C.fwVersion,
      gitHash     => x"1111_2222_3333_4444_5555_6666_7777_8888_9999_AAAA");  -- Force githash
   constant SIM_BUILD_INFO_C : slv(2239 downto 0) := toSlv(MOD_BUILD_INFO_C);

   constant CLK_PERIOD_G : time := 10 ns;
   constant TPD_G        : time := CLK_PERIOD_G/4;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, x"0080_0000", 23, 22);

   --constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_CONFIG_TimeToolKcu1500vhd(1).baseAddr, 21, 20);

   signal dmaClk          : sl                     := '0';
   signal dmaRst          : sl                     := '0';

   signal axilClk         : sl                     := '0';
   signal axilRst         : sl                     := '0';

   signal axilWriteMaster : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
   signal axilWriteSlave  : AxiLiteWriteSlaveType  := AXI_LITE_WRITE_SLAVE_INIT_C;
   signal axilReadMaster  : AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
   signal axilReadSlave   : AxiLiteReadSlaveType   := AXI_LITE_READ_SLAVE_INIT_C;

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

begin

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
         clkP => axilClk,
         rst  => axilRst);

   -----------------------
   -- Module to be tested
   -----------------------
   --U_Version : entity work.AxiVersion
   --   generic map (
   --      TPD_G        => TPD_G,
   --      BUILD_INFO_G => SIM_BUILD_INFO_C)
   --   port map (
         -- AXI-Lite Interface
   --      axiClk         => axilClk,
   --      axiRst         => axilRst,
   --      axiReadMaster  => axilReadMaster,
   --      axiReadSlave   => axilReadSlave,
   --      axiWriteMaster => axilWriteMaster,
   --      axiWriteSlave  => axilWriteSlave);

   -----------------------
   -- Module to be tested
   -----------------------

   U_Version : entity work.TimeToolCore
      generic map (
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => AXI_CONFIG_C(1).baseAddr)
      port map (
         -- System Clock and Reset
         sysClk          => dmaClk,
         sysRst          => dmaRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => appInMaster,
         dataInSlave     => appInSlave,
         dataOutMaster   => appOutMaster,
         dataOutSlave    => appOutSlave,
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- Timing information (sysClk domain)
         timingBus       => timingBus,
         -- PGP TX OP-codes (pgpTxClk domains)
         pgpTxClk        => pgpTxClk(0),
         pgpTxIn         => pgpTxIn(0));

  
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
      wait until axilRst = '1';
      wait until axilRst = '0';

      axiLiteBusSimRead (axilClk, axilReadMaster, axilReadSlave, x"0000_0600", debugData, true);
      axiLiteBusSimRead (axilClk, axilReadMaster, axilReadSlave, x"0000_0604", debugData, true);
      axiLiteBusSimRead (axilClk, axilReadMaster, axilReadSlave, x"0000_0608", debugData, true);
      axiLiteBusSimRead (axilClk, axilReadMaster, axilReadSlave, x"0000_060C", debugData, true);
      axiLiteBusSimRead (axilClk, axilReadMaster, axilReadSlave, x"0000_0610", debugData, true);


      axiLiteBusSimWrite (axilClk, axilWriteMaster, axilWriteSlave, x"0000_0000", x"1234_5678", true);

   end process test;

end testbed;
