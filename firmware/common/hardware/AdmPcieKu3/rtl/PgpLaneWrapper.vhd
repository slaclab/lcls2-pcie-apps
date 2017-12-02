-------------------------------------------------------------------------------
-- File       : PgpLaneWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2017-11-27
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
use work.BuildInfoPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.TimingPkg.all;
use work.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpLaneWrapper is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := (others => '0'));
   port (
      -- QSFP[0] Ports
      qsfp0RefClkP    : in  sl;
      qsfp0RefClkN    : in  sl;
      qsfp0RxP        : in  slv(3 downto 0);
      qsfp0RxN        : in  slv(3 downto 0);
      qsfp0TxP        : out slv(3 downto 0);
      qsfp0TxN        : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP    : in  sl;
      qsfp1RefClkN    : in  sl;
      qsfp1RxP        : in  slv(3 downto 0);
      qsfp1RxN        : in  slv(3 downto 0);
      qsfp1TxP        : out slv(3 downto 0);
      qsfp1TxN        : out slv(3 downto 0);
      -- DRP Clock and Reset
      sysClk          : in  sl;
      sysRst          : in  sl;
      drpClk          : in  sl;
      drpRst          : in  sl;
      -- DMA Interface (sysClk domain)
      dmaObMasters    : in  AxiStreamMasterArray(7 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(7 downto 0);
      -- AXI-Lite Interface (sysClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpLaneWrapper;

architecture mapping of PgpLaneWrapper is

   constant NUM_AXI_MASTERS_C : natural := 8;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal pgpRxP    : slv(7 downto 0);
   signal pgpRxN    : slv(7 downto 0);
   signal pgpTxP    : slv(7 downto 0);
   signal pgpTxN    : slv(7 downto 0);
   signal pgpRefClk : slv(7 downto 0);
   signal refClk    : slv(1 downto 0);
   
   attribute dont_touch           : string;
   attribute dont_touch of refClk : signal is "TRUE";   

begin

   ------------------------
   -- Common PGP Clocking
   ------------------------
   U_QsfpRef0 : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => qsfp0RefClkP,
         IB    => qsfp0RefClkN,
         CEB   => '0',
         ODIV2 => open,
         O     => refClk(0));

   U_QsfpRef1 : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => qsfp1RefClkP,
         IB    => qsfp1RefClkN,
         CEB   => '0',
         ODIV2 => open,
         O     => refClk(1));

   --------------------------------
   -- Mapping QSFP[1:0] to PGP[7:0]
   --------------------------------
   MAP_QSFP : for i in 3 downto 0 generate
      -- QSFP[0] to PGP[3:0]
      pgpRefClk(i+0) <= refClk(0);
      pgpRxP(i+0)    <= qsfp0RxP(i);
      pgpRxN(i+0)    <= qsfp0RxN(i);
      qsfp0TxP(i)    <= pgpTxP(i+0);
      qsfp0TxN(i)    <= pgpTxN(i+0);
      -- QSFP[1] to PGP[7:4]
      pgpRefClk(i+4) <= refClk(1);
      pgpRxP(i+4)    <= qsfp1RxP(i);
      pgpRxN(i+4)    <= qsfp1RxN(i);
      qsfp1TxP(i)    <= pgpTxP(i+4);
      qsfp1TxN(i)    <= pgpTxN(i+4);
   end generate MAP_QSFP;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
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
   GEN_LANE : for i in 7 downto 0 generate

      U_Lane : entity work.PgpLane
         generic map (
            TPD_G            => TPD_G,
            LANE_G           => (i),
            AXI_BASE_ADDR_G  => AXI_CONFIG_C(i).baseAddr,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            -- PGP Serial Ports
            pgpRxP          => pgpRxP(i),
            pgpRxN          => pgpRxN(i),
            pgpTxP          => pgpTxP(i),
            pgpTxN          => pgpTxN(i),
            pgpRefClk       => pgpRefClk(i),
            -- DRP Clock and Reset
            sysClk          => sysClk,
            sysRst          => sysRst,
            drpClk          => drpClk,
            drpRst          => drpRst,
            -- DMA Interface (sysClk domain)
            dmaObMaster     => dmaObMasters(i),
            dmaObSlave      => dmaObSlaves(i),
            dmaIbMaster     => dmaIbMasters(i),
            dmaIbSlave      => dmaIbSlaves(i),
            -- Timing Interface (evrClk domain)
            evrClk          => '0',
            evrRst          => '1',
            evrTimingBus    => TIMING_BUS_INIT_C,
            -- AXI-Lite Interface (sysClk domain)
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i));

   end generate GEN_LANE;

end mapping;
