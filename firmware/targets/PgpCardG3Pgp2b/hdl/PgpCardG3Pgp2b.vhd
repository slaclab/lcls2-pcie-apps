-------------------------------------------------------------------------------
-- File       : PgpCardG3Pgp2b.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-09-28
-- Last update: 2018-03-15
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;

entity PgpCardG3Pgp2b is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      -- PGP GT Serial Ports
      pgpRefClkP : in    sl;
      pgpRefClkN : in    sl;
      pgpRxP     : in    slv(7 downto 0);
      pgpRxN     : in    slv(7 downto 0);
      pgpTxP     : out   slv(7 downto 0);
      pgpTxN     : out   slv(7 downto 0);
      -- EVR GT Serial Ports
      evrRefClkP : in    slv(1 downto 0);
      evrRefClkN : in    slv(1 downto 0);
      evrMuxSel  : out   slv(1 downto 0);
      evrRxP     : in    sl;
      evrRxN     : in    sl;
      evrTxP     : out   sl;
      evrTxN     : out   sl;
      -- User LEDs
      ledDbg     : out   sl;
      ledRedL    : out   slv(5 downto 0);
      ledBlueL   : out   slv(5 downto 0);
      ledGreenL  : out   slv(5 downto 0);
      -- FLASH Interface 
      flashAddr  : out   slv(28 downto 0);
      flashData  : inout slv(15 downto 0);
      flashAdv   : out   sl;
      flashCeL   : out   sl;
      flashOeL   : out   sl;
      flashWeL   : out   sl;
      -- PCIe Ports
      pciRstL    : in    sl;
      pciRefClkP : in    sl;            -- 100 MHz
      pciRefClkN : in    sl;            -- 100 MHz
      pciRxP     : in    slv(3 downto 0);
      pciRxN     : in    slv(3 downto 0);
      pciTxP     : out   slv(3 downto 0);
      pciTxN     : out   slv(3 downto 0));
end PgpCardG3Pgp2b;

architecture top_level of PgpCardG3Pgp2b is

   signal sysClk : sl;
   signal sysRst : sl;

   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal dmaObMasters : AxiStreamMasterArray(7 downto 0);
   signal dmaObSlaves  : AxiStreamSlaveArray(7 downto 0);
   signal dmaIbMasters : AxiStreamMasterArray(7 downto 0);
   signal dmaIbSlaves  : AxiStreamSlaveArray(7 downto 0);

begin

   U_Core : entity work.AxiPciePgpCardG3Core
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => BUILD_INFO_G,
         DMA_SIZE_G   => 8)
      port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------              
         -- System Clock and Reset
         sysClk         => sysClk,
         sysRst         => sysRst,
         -- DMA Interfaces
         dmaObMasters   => dmaObMasters,
         dmaObSlaves    => dmaObSlaves,
         dmaIbMasters   => dmaIbMasters,
         dmaIbSlaves    => dmaIbSlaves,
         -- AXI-Lite Interface
         appClk         => sysClk,
         appRst         => sysRst,
         appReadMaster  => axilReadMaster,
         appReadSlave   => axilReadSlave,
         appWriteMaster => axilWriteMaster,
         appWriteSlave  => axilWriteSlave,
         -------------------
         --  Top Level Ports
         -------------------             
         -- Boot Memory Ports 
         flashAddr      => flashAddr,
         flashData      => flashData,
         flashAdv       => flashAdv,
         flashCeL       => flashCeL,
         flashOeL       => flashOeL,
         flashWeL       => flashWeL,
         -- PCIe Ports 
         pciRstL        => pciRstL,
         pciRefClkP     => pciRefClkP,
         pciRefClkN     => pciRefClkN,
         pciRxP         => pciRxP,
         pciRxN         => pciRxN,
         pciTxP         => pciTxP,
         pciTxN         => pciTxN);

   U_App : entity work.Hardware
      generic map (
         TPD_G           => TPD_G,
         LANE_SIZE_G     => 8,
         AXI_BASE_ADDR_G => x"0080_0000")
      port map (
         -- System Clock and Reset
         sysClk          => sysClk,
         sysRst          => sysRst,
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- DMA Interface (sysClk domain)
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- Timing information (appTimingClk domain)
         appTimingClk    => sysClk,
         appTimingRst    => sysRst,       
         -- PGP GT Serial Ports
         pgpRefClkP      => pgpRefClkP,
         pgpRefClkN      => pgpRefClkN,
         pgpRxP          => pgpRxP,
         pgpRxN          => pgpRxN,
         pgpTxP          => pgpTxP,
         pgpTxN          => pgpTxN,
         -- EVR GT Serial Ports
         evrRefClkP      => evrRefClkP,
         evrRefClkN      => evrRefClkN,
         evrMuxSel       => evrMuxSel,
         evrRxP          => evrRxP,
         evrRxN          => evrRxN,
         evrTxP          => evrTxP,
         evrTxN          => evrTxN);

   ledDbg    <= '0';
   ledRedL   <= (others => '1');
   ledBlueL  <= (others => '1');
   ledGreenL <= (others => '1');

end top_level;

