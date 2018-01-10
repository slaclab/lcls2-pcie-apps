-------------------------------------------------------------------------------
-- File       : TimeToolKcu1500.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-24
-- Last update: 2017-11-27
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

entity TimeToolKcu1500 is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP : in    slv(1 downto 0);
      qsfp0RefClkN : in    slv(1 downto 0);
      qsfp0RxP     : in    slv(3 downto 0);
      qsfp0RxN     : in    slv(3 downto 0);
      qsfp0TxP     : out   slv(3 downto 0);
      qsfp0TxN     : out   slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP : in    slv(1 downto 0);
      qsfp1RefClkN : in    slv(1 downto 0);
      qsfp1RxP     : in    slv(3 downto 0);
      qsfp1RxN     : in    slv(3 downto 0);
      qsfp1TxP     : out   slv(3 downto 0);
      qsfp1TxN     : out   slv(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- System Ports
      emcClk       : in    sl;
      userClkP     : in    sl;
      userClkN     : in    sl;
      swDip        : in    slv(3 downto 0);
      led          : out   slv(7 downto 0);
      -- QSFP[0] Ports
      qsfp0RstL    : out   sl;
      qsfp0LpMode  : out   sl;
      qsfp0ModSelL : out   sl;
      qsfp0ModPrsL : in    sl;
      -- QSFP[1] Ports
      qsfp1RstL    : out   sl;
      qsfp1LpMode  : out   sl;
      qsfp1ModSelL : out   sl;
      qsfp1ModPrsL : in    sl;
      -- Boot Memory Ports 
      flashCsL     : out   sl;
      flashMosi    : out   sl;
      flashMiso    : in    sl;
      flashHoldL   : out   sl;
      flashWp      : out   sl;
      -- DDR Ports
      ddrClkP      : in    slv(3 downto 0);
      ddrClkN      : in    slv(3 downto 0);
      ddrOut       : out   DdrOutArray(3 downto 0);
      ddrInOut     : inout DdrInOutArray(3 downto 0);
      -- PCIe Ports
      pciRstL      : in    sl;
      pciRefClkP   : in    sl;
      pciRefClkN   : in    sl;
      pciRxP       : in    slv(7 downto 0);
      pciRxN       : in    slv(7 downto 0);
      pciTxP       : out   slv(7 downto 0);
      pciTxN       : out   slv(7 downto 0));
end TimeToolKcu1500;

architecture top_level of TimeToolKcu1500 is

   constant AXI_ERROR_RESP_C : slv(1 downto 0)  := BAR0_ERROR_RESP_C;
   constant AXI_BASE_ADDR_C  : slv(31 downto 0) := BAR0_BASE_ADDR_G;

   constant NUM_AXI_MASTERS_C : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_C, 22, 22);

   signal sysClk     : sl;
   signal sysRst     : sl;
   signal userClk156 : sl;
   signal userSwDip  : slv(3 downto 0);
   signal userLed    : slv(7 downto 0);

   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal intReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal intReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal intWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal intWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal dmaObMasters : AxiStreamMasterArray(7 downto 0);
   signal dmaObSlaves  : AxiStreamSlaveArray(7 downto 0);
   signal dmaIbMasters : AxiStreamMasterArray(7 downto 0);
   signal dmaIbSlaves  : AxiStreamSlaveArray(7 downto 0);

   signal hwIbMasters  : AxiStreamMasterArray(7 downto 0);
   signal hwIbSlaves   : AxiStreamSlaveArray(7 downto 0);

   signal appInMaster   : AxiStreamMasterType;
   signal appInSlave    : AxiStreamSlaveType;
   signal appOutMaster  : AxiStreamMasterType;
   signal appOutSlave   : AxiStreamSlaveType;

   signal memReady        : slv(3 downto 0);
   signal memWriteMasters : AxiWriteMasterArray(15 downto 0);
   signal memWriteSlaves  : AxiWriteSlaveArray(15 downto 0);
   signal memReadMasters  : AxiReadMasterArray(15 downto 0);
   signal memReadSlaves   : AxiReadSlaveArray(15 downto 0);

begin

   U_Core : entity work.XilinxKcu1500Core
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => BUILD_INFO_G,
         DMA_SIZE_G   => 8)
      port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------        
         -- System Clock and Reset
         sysClk          => sysClk,
         sysRst          => sysRst,
         userClk156      => userClk156,
         userSwDip       => userSwDip,
         userLed         => userLed,
         -- DMA Interfaces
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- AXI-Lite Interface
         appClk          => sysClk,
         appRst          => sysRst,
         appReadMaster   => axilReadMaster,
         appReadSlave    => axilReadSlave,
         appWriteMaster  => axilWriteMaster,
         appWriteSlave   => axilWriteSlave,
         -- Memory bus (sysClk domain)
         memReady        => memReady,
         memWriteMasters => memWriteMasters,
         memWriteSlaves  => memWriteSlaves,
         memReadMasters  => memReadMasters,
         memReadSlaves   => memReadSlaves,
         --------------
         --  Core Ports
         --------------   
         -- System Ports
         emcClk          => emcClk,
         userClkP        => userClkP,
         userClkN        => userClkN,
         swDip           => swDip,
         led             => led,
         -- QSFP[0] Ports
         qsfp0RstL       => qsfp0RstL,
         qsfp0LpMode     => qsfp0LpMode,
         qsfp0ModSelL    => qsfp0ModSelL,
         qsfp0ModPrsL    => qsfp0ModPrsL,
         -- QSFP[1] Ports
         qsfp1RstL       => qsfp1RstL,
         qsfp1LpMode     => qsfp1LpMode,
         qsfp1ModSelL    => qsfp1ModSelL,
         qsfp1ModPrsL    => qsfp1ModPrsL,
         -- Boot Memory Ports 
         flashCsL        => flashCsL,
         flashMosi       => flashMosi,
         flashMiso       => flashMiso,
         flashHoldL      => flashHoldL,
         flashWp         => flashWp,
         -- DDR Ports
         ddrClkP         => ddrClkP,
         ddrClkN         => ddrClkN,
         ddrOut          => ddrOut,
         ddrInOut        => ddrInOut,
         -- PCIe Ports 
         pciRstL         => pciRstL,
         pciRefClkP      => pciRefClkP,
         pciRefClkN      => pciRefClkN,
         pciRxP          => pciRxP,
         pciRxN          => pciRxN,
         pciTxP          => pciTxP,
         pciTxN          => pciTxN);

   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_C,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => sysClk,
         axiClkRst           => sysRst,
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
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C,
         AXI_BASE_ADDR_G  => AXI_BASE_ADDR_C)
      port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------         
         -- System Interfaces
         sysClk          => sysClk,
         sysRst          => sysRst,
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
         ---------------------
         --  Application Ports
         ---------------------         
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

   -- Unused memory signals
   --memReady        : slv(3 downto 0);
   memWriteMasters <= (others=>AXI_WRITE_MASTER_INIT_C);
   --memWriteSlaves  : AxiWriteSlaveArray(15 downto 0);
   memReadMasters  <= (others=>AXI_READ_MASTER_INIT_C);
   --memReadSlaves   : AxiReadSlaveArray(15 downto 0);

   -- Unused user signals
   --userSwDip  : slv(3 downto 0);
   userLed <= (others=>'0');

   dmaIbMasters(7 downto 1) <= hwIbmasters(7 downto 1);
   hwIbSlaves(7 downto 1)   <= dmaIbSlaves(7 downto 1);

   -- Tap data destination
   U_Tap: entity work.AxiStreamTap
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
         axisClk      => sysClk,
         axisRst      => sysRst);

   U_TimeToolCore: entity work.TimeToolCore
      generic map ( 
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C)
      port map (
         sysClk          => sysClk,
         sysRst          => sysRst,
         dataInMaster    => appInMaster,
         dataInSlave     => appInSlave,
         dataOutMaster   => appOutMaster,
         dataOutSlave    => appOutSlave,
         axilReadMaster  => intReadMasters(1),
         axilReadSlave   => intReadSlaves(1),
         axilWriteMaster => intWriteMasters(1),
         axilWriteSlave  => intWriteSlaves(1));

end top_level;

