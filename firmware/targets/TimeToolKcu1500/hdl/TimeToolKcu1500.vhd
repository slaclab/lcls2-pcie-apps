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

entity TimeToolKcu1500 is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP : in  slv(1 downto 0);
      qsfp0RefClkN : in  slv(1 downto 0);
      qsfp0RxP     : in  slv(3 downto 0);
      qsfp0RxN     : in  slv(3 downto 0);
      qsfp0TxP     : out slv(3 downto 0);
      qsfp0TxN     : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP : in  slv(1 downto 0);
      qsfp1RefClkN : in  slv(1 downto 0);
      qsfp1RxP     : in  slv(3 downto 0);
      qsfp1RxN     : in  slv(3 downto 0);
      qsfp1TxP     : out slv(3 downto 0);
      qsfp1TxN     : out slv(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- System Ports
      emcClk       : in  sl;
      userClkP     : in  sl;
      userClkN     : in  sl;
      -- QSFP[0] Ports
      qsfp0RstL    : out sl;
      qsfp0LpMode  : out sl;
      qsfp0ModSelL : out sl;
      qsfp0ModPrsL : in  sl;
      -- QSFP[1] Ports
      qsfp1RstL    : out sl;
      qsfp1LpMode  : out sl;
      qsfp1ModSelL : out sl;
      qsfp1ModPrsL : in  sl;
      -- Boot Memory Ports 
      flashCsL     : out sl;
      flashMosi    : out sl;
      flashMiso    : in  sl;
      flashHoldL   : out sl;
      flashWp      : out sl;
      -- PCIe Ports
      pciRstL      : in  sl;
      pciRefClkP   : in  sl;
      pciRefClkN   : in  sl;
      pciRxP       : in  slv(7 downto 0);
      pciRxN       : in  slv(7 downto 0);
      pciTxP       : out slv(7 downto 0);
      pciTxN       : out slv(7 downto 0));
end TimeToolKcu1500;

architecture top_level of TimeToolKcu1500 is

   constant DMA_SIZE_C : positive := 1;

   constant NUM_AXI_MASTERS_C : positive := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, x"0080_0000", 23, 22);

   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);  -- 16 byte (128-bit) AXIS interface

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

begin

   U_Core : entity work.XilinxKcu1500Core
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G        => DMA_SIZE_C)
      port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------        
         userClk156     => userClk156,
         -- DMA Interfaces
         dmaClk         => dmaClk,
         dmaRst         => dmaRst,
         dmaObMasters   => dmaObMasters,
         dmaObSlaves    => dmaObSlaves,
         dmaIbMasters   => dmaIbMasters,
         dmaIbSlaves    => dmaIbSlaves,
         -- AXI-Lite Interface
         appClk         => dmaClk,
         appRst         => dmaRst,
         appReadMaster  => axilReadMaster,
         appReadSlave   => axilReadSlave,
         appWriteMaster => axilWriteMaster,
         appWriteSlave  => axilWriteSlave,
         --------------
         --  Core Ports
         --------------   
         -- System Ports
         emcClk         => emcClk,
         userClkP       => userClkP,
         userClkN       => userClkN,
         -- QSFP[0] Ports
         qsfp0RstL      => qsfp0RstL,
         qsfp0LpMode    => qsfp0LpMode,
         qsfp0ModSelL   => qsfp0ModSelL,
         qsfp0ModPrsL   => qsfp0ModPrsL,
         -- QSFP[1] Ports
         qsfp1RstL      => qsfp1RstL,
         qsfp1LpMode    => qsfp1LpMode,
         qsfp1ModSelL   => qsfp1ModSelL,
         qsfp1ModPrsL   => qsfp1ModPrsL,
         -- Boot Memory Ports 
         flashCsL       => flashCsL,
         flashMosi      => flashMosi,
         flashMiso      => flashMiso,
         flashHoldL     => flashHoldL,
         flashWp        => flashWp,
         -- PCIe Ports 
         pciRstL        => pciRstL,
         pciRefClkP     => pciRefClkP,
         pciRefClkN     => pciRefClkN,
         pciRxP         => pciRxP,
         pciRxN         => pciRxN,
         pciTxP         => pciTxP,
         pciTxN         => pciTxN);

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

   U_App : entity work.Hardware
      generic map (
         TPD_G             => TPD_G,
         DMA_SIZE_G        => DMA_SIZE_C,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         AXI_BASE_ADDR_G   => AXI_CONFIG_C(0).baseAddr)
      port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------         
         -- System Interfaces
         sysClk          => dmaClk,
         sysRst          => dmaRst,
         userClk156      => userClk156,
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => intReadMasters(0),
         axilReadSlave   => intReadSlaves(0),
         axilWriteMaster => intWriteMasters(0),
         axilWriteSlave  => intWriteSlaves(0),
         -- DMA Interface (sysClk domain)
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => hwIbMasters,
         dmaIbSlaves     => hwIbSlaves,
         -- Timing information (appTimingClk domain)
         appTimingClk    => dmaClk,
         appTimingRst    => dmaRst,
         appTimingBus    => timingBus,
         -- PGP TX OP-codes (pgpTxClk domains)
         pgpTxClk        => pgpTxClk,
         pgpTxIn         => pgpTxIn,
         ------------------
         --  Hardware Ports
         ------------------        
         -- QSFP[0] Ports
         qsfp0RefClkP    => qsfp0RefClkP,
         qsfp0RefClkN    => qsfp0RefClkN,
         qsfp0RxP        => qsfp0RxP,
         qsfp0RxN        => qsfp0RxN,
         qsfp0TxP        => qsfp0TxP,
         qsfp0TxN        => qsfp0TxN,
         -- QSFP[1] Ports
         qsfp1RefClkP    => qsfp1RefClkP,
         qsfp1RefClkN    => qsfp1RefClkN,
         qsfp1RxP        => qsfp1RxP,
         qsfp1RxN        => qsfp1RxN,
         qsfp1TxP        => qsfp1TxP,
         qsfp1TxN        => qsfp1TxN);

   -- Tap data destination
   U_Tap : entity work.AxiStreamTap
      generic map (
         TPD_G      => TPD_G,
         TAP_DEST_G => 1)
      port map (
         sAxisMaster  => hwIbMasters(0),
         sAxisSlave   => hwIbSlaves(0),
         mAxisMaster  => dmaIbMasters(0),
         mAxisSlave   => dmaIbSlaves(0),
         tmAxisMaster => appInMaster,
         tmAxisSlave  => appInSlave,
         tsAxisMaster => appOutMaster,
         tsAxisSlave  => appOutSlave,
         axisClk      => dmaClk,
         axisRst      => dmaRst);

   U_TimeToolCore : entity work.TimeToolCore
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
         axilReadMaster  => intReadMasters(1),
         axilReadSlave   => intReadSlaves(1),
         axilWriteMaster => intWriteMasters(1),
         axilWriteSlave  => intWriteSlaves(1),
         -- Timing information (sysClk domain)
         timingBus       => timingBus,
         -- PGP TX OP-codes (pgpTxClk domains)
         pgpTxClk        => pgpTxClk(0),
         pgpTxIn         => pgpTxIn(0));

end top_level;
