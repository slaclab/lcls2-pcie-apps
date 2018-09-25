-------------------------------------------------------------------------------
-- File       : PgpLaneWrapper.vhd
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
use work.AxiPciePkg.all;
use work.Pgp2bPkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpLaneWrapper is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- QSFP[0] Ports
      qsfp0RefClkP    : in  slv(1 downto 0);
      qsfp0RefClkN    : in  slv(1 downto 0);
      qsfp0RxP        : in  slv(3 downto 0);
      qsfp0RxN        : in  slv(3 downto 0);
      qsfp0TxP        : out slv(3 downto 0);
      qsfp0TxN        : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP    : in  slv(1 downto 0);
      qsfp1RefClkN    : in  slv(1 downto 0);
      qsfp1RxP        : in  slv(3 downto 0);
      qsfp1RxN        : in  slv(3 downto 0);
      qsfp1TxP        : out slv(3 downto 0);
      qsfp1TxN        : out slv(3 downto 0);
      -- EVR GT Serial Ports
      evrRxP          : out slv(1 downto 0);
      evrRxN          : out slv(1 downto 0);
      evrTxP          : in  slv(1 downto 0);
      evrTxN          : in  slv(1 downto 0);
      -- DRP Clock and Reset
      drpClk          : in  sl;
      drpRst          : in  sl;
      -- DMA Interface (sysClk domain)
      dmaObMasters    : in  AxiStreamMasterArray(7 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(7 downto 0);
      -- Timing Interface (evrClk domain)
      evrClk          : in  sl;
      evrRst          : in  sl;
      evrTimingBus    : in  TimingBusType;
      -- AXI-Lite Interface (sysClk domain)
      sysClk          : in  sl;
      sysRst          : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- PGP TX OP-codes (pgpTxClk domains)
      pgpTxClk        : out slv(5 downto 0);
      pgpTxIn         : in  Pgp2bTxInArray(5 downto 0));      
end PgpLaneWrapper;

architecture mapping of PgpLaneWrapper is

   constant NUM_AXI_MASTERS_C : natural := 6;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal evrReset        : slv(NUM_AXI_MASTERS_C-1 downto 0);
   signal sysReset        : slv(NUM_AXI_MASTERS_C-1 downto 0);
   signal evrTimingBusDly : TimingBusArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal pgpRxP   : slv(NUM_AXI_MASTERS_C-1 downto 0);
   signal pgpRxN   : slv(NUM_AXI_MASTERS_C-1 downto 0);
   signal pgpTxP   : slv(NUM_AXI_MASTERS_C-1 downto 0);
   signal pgpTxN   : slv(NUM_AXI_MASTERS_C-1 downto 0);

   signal refClk : slv(3 downto 0);

   attribute dont_touch           : string;
   attribute dont_touch of refClk : signal is "TRUE";

begin

   -- Unused DMA lanes
   dmaObSlaves(7 downto 6)  <= (others => AXI_STREAM_SLAVE_FORCE_C);
   dmaIbMasters(7 downto 6) <= (others => AXI_STREAM_MASTER_INIT_C);

   -- Remapping for EVR[1] interface
   evrRxP(1)   <= qsfp1RxP(3);
   evrRxN(1)   <= qsfp1RxN(3);
   qsfp1TxP(3) <= evrTxP(1);
   qsfp1TxN(3) <= evrTxN(1);

   -- Remapping for EVR[0] interface
   evrRxP(0)   <= qsfp1RxP(2);
   evrRxN(0)   <= qsfp1RxN(2);
   qsfp1TxP(2) <= evrTxP(0);
   qsfp1TxN(2) <= evrTxN(0);

   -- Remapping for PGP[5] interface
   pgpRxP(5)   <= qsfp1RxP(1);
   pgpRxN(5)   <= qsfp1RxN(1);
   qsfp1TxP(1) <= pgpTxP(5);
   qsfp1TxN(1) <= pgpTxN(5);

   -- Remapping for PGP[4] interface
   pgpRxP(4)   <= qsfp1RxP(0);
   pgpRxN(4)   <= qsfp1RxN(0);
   qsfp1TxP(0) <= pgpTxP(4);
   qsfp1TxN(0) <= pgpTxN(4);

   -- Remapping for PGP[3:0] interface
   GEN_VEC : for i in 3 downto 0 generate
      pgpRxP(i)   <= qsfp0RxP(i);
      pgpRxN(i)   <= qsfp0RxN(i);
      qsfp0TxP(i) <= pgpTxP(i);
      qsfp0TxN(i) <= pgpTxN(i);
   end generate GEN_VEC;

   ------------------------
   -- Common PGP Clocking
   ------------------------
   GEN_REFCLK :
   for i in 1 downto 0 generate

      U_QsfpRef0 : IBUFDS_GTE3
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfp0RefClkP(i),
            IB    => qsfp0RefClkN(i),
            CEB   => '0',
            ODIV2 => open,
            O     => refClk((2*i)+0));

      U_QsfpRef1 : IBUFDS_GTE3
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfp1RefClkP(i),
            IB    => qsfp1RefClkN(i),
            CEB   => '0',
            ODIV2 => open,
            O     => refClk((2*i)+1));

   end generate GEN_REFCLK;

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

   ------------
   -- PGP Lanes
   ------------
   GEN_LANE : for i in NUM_AXI_MASTERS_C-1 downto 0 generate

      U_Lane : entity work.PgpLane
         generic map (
            TPD_G           => TPD_G,
            LANE_G          => (i),
            AXI_BASE_ADDR_G => AXI_CONFIG_C(i).baseAddr)
         port map (
            -- PGP Serial Ports
            pgpRxP          => pgpRxP(i),
            pgpRxN          => pgpRxN(i),
            pgpTxP          => pgpTxP(i),
            pgpTxN          => pgpTxN(i),
            pgpRefClk       => refClk(0),
            -- DRP Clock and Reset
            drpClk          => drpClk,
            drpRst          => drpRst,
            -- DMA Interface (sysClk domain)
            dmaObMaster     => dmaObMasters(i),
            dmaObSlave      => dmaObSlaves(i),
            dmaIbMaster     => dmaIbMasters(i),
            dmaIbSlave      => dmaIbSlaves(i),
            -- Timing Interface (evrClk domain)
            evrClk          => evrClk,
            evrRst          => evrReset(i),
            evrTimingBus    => evrTimingBusDly(i),
            -- AXI-Lite Interface (sysClk domain)
            sysClk          => sysClk,
            sysRst          => sysReset(i),
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i),
            -- PGP TX OP-codes (pgpTxClk domains)
            pgpTxClkOut     => pgpTxClk(i),
            appPgpTxIn      => pgpTxIn(i));

      U_evrRst : entity work.RstPipeline
         generic map (
            TPD_G => TPD_G)
         port map (
            clk    => evrClk,
            rstIn  => evrRst,
            rstOut => evrReset(i));

      U_sysRst : entity work.RstPipeline
         generic map (
            TPD_G => TPD_G)
         port map (
            clk    => sysClk,
            rstIn  => sysRst,
            rstOut => sysReset(i));

      -- U_evrBus : entity work.EvrPipeline
      -- generic map (
      -- TPD_G => TPD_G)
      -- port map (
      -- evrClk => evrClk,
      -- evrIn  => evrTimingBus,
      -- evrOut => evrTimingBusDly(i));

      evrTimingBusDly(i) <= evrTimingBus;

   end generate GEN_LANE;

end mapping;
