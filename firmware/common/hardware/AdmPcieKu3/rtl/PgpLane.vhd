-------------------------------------------------------------------------------
-- File       : PgpLane.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-04
-- Last update: 2017-12-11
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
use work.AxiPciePkg.all;
use work.AppPkg.all;
use work.Pgp2bPkg.all;
use work.TimingPkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpLane is
   generic (
      TPD_G            : time                  := 1 ns;
      LANE_G           : positive range 0 to 7 := 0;
      ENABLE_G         : boolean               := true;
      AXI_ERROR_RESP_G : slv(1 downto 0)       := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0)      := (others => '0'));
   port (
      -- PGP Serial Ports
      pgpTxP          : out sl;
      pgpTxN          : out sl;
      pgpRxP          : in  sl;
      pgpRxN          : in  sl;
      pgpRefClk       : in  sl;
      pgpClk          : in  sl;
      pgpRst          : in  sl;
      -- DRP Clock and Reset
      sysClk          : in  sl;
      sysRst          : in  sl;
      drpClk          : in  sl;
      drpRst          : in  sl;
      -- DMA Interface (sysClk domain)
      dmaObMaster     : in  AxiStreamMasterType;
      dmaObSlave      : out AxiStreamSlaveType;
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- Timing Interface (evrClk domain)
      evrClk          : in  sl;
      evrRst          : in  sl;
      evrTimingBus    : in  TimingBusType;
      -- AXI-Lite Interface (sysClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpLane;

architecture mapping of PgpLane is

   constant NUM_AXI_MASTERS_C : natural := 3;

   constant GT_INDEX_C   : natural := 0;
   constant MON_INDEX_C  : natural := 1;
   constant CTRL_INDEX_C : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 16, 12);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal locTxIn  : Pgp2bTxInType;
   signal pgpTxIn  : Pgp2bTxInType;
   signal pgpTxOut : Pgp2bTxOutType;

   signal pgpRxIn  : Pgp2bRxInType;
   signal pgpRxOut : Pgp2bRxOutType;

   signal pgpTxMasters : AxiStreamMasterArray(3 downto 0);
   signal pgpTxSlaves  : AxiStreamSlaveArray(3 downto 0);

   signal rxMasters    : AxiStreamMasterArray(3 downto 0);
   signal pgpRxMasters : AxiStreamMasterArray(3 downto 0);
   signal pgpRxCtrl    : AxiStreamCtrlArray(3 downto 0);

   signal status : StatusType;
   signal config : ConfigType;

begin

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

   -----------
   -- PGP Core
   -----------
   U_PGP : entity work.AxisPgp2bGthCore
      generic map (
         TPD_G             => TPD_G,
         VC_INTERLEAVE_G   => 1)
      port map (
         stableClk       => sysClk,
         stableRst       => sysRst,
         gtRefClk        => pgpRefClk,
         pgpGtTxP        => pgpTxP,
         pgpGtTxN        => pgpTxN,
         pgpGtRxP        => pgpRxP,
         pgpGtRxN        => pgpRxN,
         pgpTxReset      => pgpRst,
         pgpTxClk        => pgpClk,
         pgpTxMmcmLocked => '1',
         pgpRxReset      => pgpRst,
         pgpRxClk        => pgpClk,
         pgpRxMmcmLocked => '1',
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         pgpTxMasters    => pgpTxMasters,
         pgpTxSlaves     => pgpTxSlaves,
         pgpRxMasters    => pgpRxMasters,
         pgpRxCtrl       => pgpRxCtrl);

   U_AxiLiteEmpty : entity work.AxiLiteEmpty
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         axiClk         => sysClk,
         axiClkRst      => sysRst,
         axiReadMaster  => axilReadMasters(GT_INDEX_C),
         axiReadSlave   => axilReadSlaves(GT_INDEX_C),
         axiWriteMaster => axilWriteMasters(GT_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(GT_INDEX_C));

   --------------         
   -- PGP Monitor
   --------------         
   U_PgpMon : entity work.Pgp2bAxi
      generic map (
         TPD_G              => TPD_G,
         AXI_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => false,
         WRITE_EN_G         => true,
         AXI_CLK_FREQ_G     => SYS_CLK_FREQ_C,
         STATUS_CNT_WIDTH_G => 16,
         ERROR_CNT_WIDTH_G  => 16)
      port map (
         -- TX PGP Interface (pgpTxClk)
         pgpTxClk        => pgpClk,
         pgpTxClkRst     => pgpRst,
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         locTxIn         => locTxIn,
         -- RX PGP Interface (pgpRxClk)
         pgpRxClk        => pgpClk,
         pgpRxClkRst     => pgpRst,
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => sysClk,
         axilRst         => sysRst,
         axilReadMaster  => axilReadMasters(MON_INDEX_C),
         axilReadSlave   => axilReadSlaves(MON_INDEX_C),
         axilWriteMaster => axilWriteMasters(MON_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(MON_INDEX_C));

   ------------
   -- Misc Core
   ------------
   U_PgpMiscCtrl : entity work.PgpMiscCtrl
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- Control/Status  (sysClk domain)
         status          => status,
         config          => config,
         -- AXI Lite interface
         sysClk          => sysClk,
         sysRst          => sysRst,
         axilReadMaster  => axilReadMasters(CTRL_INDEX_C),
         axilReadSlave   => axilReadSlaves(CTRL_INDEX_C),
         axilWriteMaster => axilWriteMasters(CTRL_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(CTRL_INDEX_C));

   -----------------------         
   -- RX VC Blowoff Filter
   -----------------------         
   BLOWOFF_FILTER : process (config, pgpRxMasters, pgpRxOut) is
      variable tmp : AxiStreamMasterArray(3 downto 0);
      variable i   : natural;
   begin
      tmp := pgpRxMasters;
      for i in 3 downto 0 loop
         if (config.rxVcBlowoff(i) = '1') or (pgpRxOut.linkReady = '0') then
            tmp(i).tValid := '0';
         end if;
      end loop;
      rxMasters <= tmp;
   end process;

   BUILD_FIFO : if (ENABLE_G = true) generate
      ---------
      -- PGP TX
      ---------
      U_Tx : entity work.PgpLaneTx
         generic map (
            TPD_G => TPD_G)
         port map (
            -- DMA Interface (sysClk domain)
            sysClk       => sysClk,
            sysRst       => sysRst,
            dmaObMaster  => dmaObMaster,
            dmaObSlave   => dmaObSlave,
            -- PGP Interface
            pgpTxClk     => pgpClk,
            pgpTxRst     => pgpRst,
            pgpTxMasters => pgpTxMasters,
            pgpTxSlaves  => pgpTxSlaves);

      ---------
      -- PGP RX
      ---------
      U_Rx : entity work.PgpLaneRx
         generic map (
            TPD_G          => TPD_G,
            -- CASCADE_SIZE_G => 4,
            CASCADE_SIZE_G => 1,
            LANE_G         => LANE_G)
         port map (
            -- DMA Interface (sysClk domain)
            sysClk       => sysClk,
            sysRst       => sysRst,
            dmaIbMaster  => dmaIbMaster,
            dmaIbSlave   => dmaIbSlave,
            -- Control/Status  (sysClk domain)
            config       => config,
            status       => status,
            -- Timing Interface (evrClk domain)
            evrClk       => evrClk,
            evrRst       => evrRst,
            evrTimingBus => evrTimingBus,
            -- PGP Trigger Interface (pgpTxClk domain)
            pgpTxClk     => pgpClk,
            pgpTxRst     => pgpRst,
            pgpTxIn      => locTxIn,
            -- PGP RX Interface (pgpRxClk domain)
            pgpRxClk     => pgpClk,
            pgpRxRst     => pgpRst,
            pgpRxMasters => rxMasters,
            pgpRxCtrl    => pgpRxCtrl);

   end generate;

   BYPASS_FIFO : if (ENABLE_G = false) generate
      -- PGP TX
      dmaObSlave   <= AXI_STREAM_SLAVE_FORCE_C;
      pgpTxMasters <= (others => AXI_STREAM_MASTER_INIT_C);
      -- PGP RX
      dmaIbMaster  <= AXI_STREAM_MASTER_INIT_C;
      status       <= STATUS_INIT_C;
      locTxIn      <= PGP2B_TX_IN_INIT_C;
      pgpRxCtrl    <= (others => AXI_STREAM_CTRL_UNUSED_C);
   end generate;

end mapping;
