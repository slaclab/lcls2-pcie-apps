-------------------------------------------------------------------------------
-- File       : Hardware.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-04
-- Last update: 2018-03-15
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'SLAC PGP Gen3 Card'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC PGP Gen3 Card', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.TimingPkg.all;

entity Hardware is
   generic (
      TPD_G           : time                 := 1 ns;
      LANE_SIZE_G     : natural range 0 to 8 := 8;
      AXI_BASE_ADDR_G : slv(31 downto 0)     := x"0080_0000");
   port (
      -- System Clock and Reset
      sysClk          : in  sl;
      sysRst          : in  sl;
      -- AXI-Lite Interface
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- DMA Interface
      dmaObMasters    : in  AxiStreamMasterArray(7 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(7 downto 0);
      -- PGP GT Serial Ports
      pgpRefClkP      : in  sl;
      pgpRefClkN      : in  sl;
      pgpRxP          : in  slv(7 downto 0);
      pgpRxN          : in  slv(7 downto 0);
      pgpTxP          : out slv(7 downto 0);
      pgpTxN          : out slv(7 downto 0);
      -- EVR GT Serial Ports
      evrRefClkP      : in  slv(1 downto 0);
      evrRefClkN      : in  slv(1 downto 0);
      evrMuxSel       : out slv(1 downto 0);
      evrRxP          : in  sl;
      evrRxN          : in  sl;
      evrTxP          : out sl;
      evrTxN          : out sl);
end Hardware;

architecture mapping of Hardware is

   constant NUM_AXI_MASTERS_C : natural := 2;

   constant PGP_INDEX_C : natural := 0;
   constant EVR_INDEX_C : natural := 1;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 21, 20);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal evrClk       : sl;
   signal evrRst       : sl;
   signal evrTimingBus : TimingBusType;

begin


   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
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
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   --------------
   -- PGP Modules
   --------------
   U_Pgp : entity work.PgpLaneWrapper
      generic map (
         TPD_G           => TPD_G,
         LANE_SIZE_G     => LANE_SIZE_G,
         AXI_BASE_ADDR_G => AXI_CONFIG_C(PGP_INDEX_C).baseAddr)
      port map (
         -- PGP GT Serial Ports
         pgpRefClkP      => pgpRefClkP,
         pgpRefClkN      => pgpRefClkN,
         pgpRxP          => pgpRxP,
         pgpRxN          => pgpRxN,
         pgpTxP          => pgpTxP,
         pgpTxN          => pgpTxN,
         -- DMA Interfaces (sysClk domain)
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- Timing Interface (evrClk domain)
         evrClk          => evrClk,
         evrRst          => evrRst,
         evrTimingBus    => evrTimingBus,
         -- AXI-Lite Interface (sysClk domain)
         sysClk          => sysClk,
         sysRst          => sysRst,
         axilReadMaster  => axilReadMasters(PGP_INDEX_C),
         axilReadSlave   => axilReadSlaves(PGP_INDEX_C),
         axilWriteMaster => axilWriteMasters(PGP_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PGP_INDEX_C));

   ------------------
   -- Timing Receiver
   ------------------
   U_Evr : entity work.EvrFrontEnd
      generic map (
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => AXI_CONFIG_C(EVR_INDEX_C).baseAddr)
      port map (
         -- Timing Interface (evrClk domain)
         evrClk          => evrClk,
         evrRst          => evrRst,
         evrTimingBus    => evrTimingBus,
         -- AXI-Lite Interface
         sysClk          => sysClk,
         sysRst          => sysRst,
         axilReadMaster  => axilReadMasters(EVR_INDEX_C),
         axilReadSlave   => axilReadSlaves(EVR_INDEX_C),
         axilWriteMaster => axilWriteMasters(EVR_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(EVR_INDEX_C),
         -- GT Serial Ports
         evrRefClkP      => evrRefClkP,
         evrRefClkN      => evrRefClkN,
         evrMuxSel       => evrMuxSel,
         evrRxP          => evrRxP,
         evrRxN          => evrRxN,
         evrTxP          => evrTxP,
         evrTxN          => evrTxN);

end mapping;
