-------------------------------------------------------------------------------
-- File       : PgpLaneWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2018-06-23
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
use work.AxiPciePkg.all;
use work.Pgp3Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpLaneWrapper is
   generic (
      TPD_G            : time             := 1 ns;
      REFCLK_WIDTH_G   : positive         := 2;
      NUM_VC_G         : positive         := 16;
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
      -- DMA Interface (dmaClk domain)
      dmaClks         : out slv                 (3 downto 0);
      dmaRsts         : out slv                 (3 downto 0);
      dmaObMasters    : in  AxiStreamMasterArray(3 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray (3 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(3 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray (3 downto 0);
      dmaIbFull       : in  slv                 (3 downto 0);
      sAxisCtrl       : out AxiStreamCtrlArray  (3 downto 0);
       -- OOB Signals
      txOpCodeEn      : in  slv                 (3 downto 0) := (others=>'0');
      txOpCode        : in  Slv8Array           (3 downto 0) := (others=>X"00");
      rxOpCodeEn      : out slv                 (3 downto 0);
      rxOpCode        : out Slv8Array           (3 downto 0);
     -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpLaneWrapper;

architecture mapping of PgpLaneWrapper is

   constant NUM_AXI_MASTERS_C : natural := 4;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 18, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray (NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray (NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray  (NUM_AXI_MASTERS_C-1 downto 0);

   signal pgpRxP : slv(7 downto 0);
   signal pgpRxN : slv(7 downto 0);
   signal pgpTxP : slv(7 downto 0);
   signal pgpTxN : slv(7 downto 0);

   signal qpllLock   : Slv2Array(7 downto 0);
   signal qpllClk    : Slv2Array(7 downto 0);
   signal qpllRefclk : Slv2Array(7 downto 0);
   signal qpllRst    : Slv2Array(7 downto 0);

   signal obMasters : AxiStreamMasterArray(7 downto 0);
   signal obSlaves  : AxiStreamSlaveArray(7 downto 0);
   signal ibMasters : AxiStreamMasterArray(7 downto 0);
   signal ibSlaves  : AxiStreamSlaveArray(7 downto 0);

   signal refClk : slv((2*REFCLK_WIDTH_G)-1 downto 0);

   attribute dont_touch           : string;
   attribute dont_touch of refClk : signal is "TRUE";

begin

   ------------------------
   -- Common PGP Clocking
   ------------------------
   GEN_REFCLK :
   for i in REFCLK_WIDTH_G-1 downto 0 generate

      U_QsfpRef0 : IBUFDS_GTE3
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => qsfp0RefClkP,
            IB    => qsfp0RefClkN,
            CEB   => '0',
            ODIV2 => open,
            O     => refClk((2*i)+0));

   end generate GEN_REFCLK;

   GEN_PLLCLK :
   for i in 0 downto 0 generate

      U_QPLL : entity work.Pgp3GthUsQpll
         generic map (
            TPD_G             => TPD_G,
            AXIL_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            -- Stable Clock and Reset
            stableClk  => axilClk,
            stableRst  => axilRst,
            -- QPLL Clocking
            pgpRefClk  => refClk(i),
            qpllLock   => qpllLock  ((4*i)+3 downto (4*i)),
            qpllClk    => qpllClk   ((4*i)+3 downto (4*i)),
            qpllRefclk => qpllRefclk((4*i)+3 downto (4*i)),
            qpllRst    => qpllRst   ((4*i)+3 downto (4*i)));

   end generate GEN_PLLCLK;

   --------------------------------
   -- Mapping QSFP[1:0] to PGP[7:0]
   --------------------------------
   MAP_QSFP : for i in 3 downto 0 generate
      -- QSFP[0] to PGP[3:0]
      pgpRxP(i+0) <= qsfp0RxP(i);
      pgpRxN(i+0) <= qsfp0RxN(i);
      qsfp0TxP(i) <= pgpTxP(i+0);
      qsfp0TxN(i) <= pgpTxN(i+0);
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

   ------------
   -- PGP Lanes
   ------------
   GEN_LANE : for i in 3 downto 0 generate

      U_Lane : entity work.PgpLane
         generic map (
            TPD_G            => TPD_G,
            LANE_G           => i,
            NUM_VC_G         => NUM_VC_G,
            AXI_BASE_ADDR_G  => AXI_CONFIG_C(i).baseAddr,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
         port map (
            -- QPLL Interface
            qpllLock        => qpllLock(i),
            qpllClk         => qpllClk(i),
            qpllRefclk      => qpllRefclk(i),
            qpllRst         => qpllRst(i),
            -- PGP Serial Ports
            pgpRxP          => pgpRxP(i),
            pgpRxN          => pgpRxN(i),
            pgpTxP          => pgpTxP(i),
            pgpTxN          => pgpTxN(i),
            -- DMA Interface (dmaClk domain)
            dmaClk          => dmaClks  (i),
            dmaRst          => dmaRsts  (i),
            dmaObMaster     => obMasters(i),
            dmaObSlave      => obSlaves (i),
            dmaIbMaster     => ibMasters(i),
            dmaIbSlave      => ibSlaves (i),
            dmaIbFull       => dmaIbFull(i),
            sAxisCtrl       => sAxisCtrl(i),
             -- OOB Signals
            txOpCodeEn      => txOpCodeEn(i),
            txOpCode        => txOpCode  (i),
            rxOpCodeEn      => rxOpCodeEn(i),
            rxOpCode        => rxOpCode  (i),
           -- AXI-Lite Interface (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i));

      obMasters(i)   <= dmaObMasters(i);
      dmaObSlaves(i) <= obSlaves(i);

      dmaIbMasters(i) <= ibMasters(i);
      ibSlaves(i)     <= dmaIbSlaves(i);

   end generate GEN_LANE;

end mapping;
