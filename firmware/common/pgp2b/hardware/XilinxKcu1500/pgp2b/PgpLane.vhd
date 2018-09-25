-------------------------------------------------------------------------------
-- File       : PgpLane.vhd
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
use work.AxiPciePkg.all;
use work.AppPkg.all;
use work.Pgp2bPkg.all;
use work.TimingPkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpLane is
   generic (
      TPD_G           : time                  := 1 ns;
      LANE_G          : positive range 0 to 7 := 0;
      AXI_BASE_ADDR_G : slv(31 downto 0)      := (others => '0'));
   port (
      -- PGP Serial Ports
      pgpTxP          : out sl;
      pgpTxN          : out sl;
      pgpRxP          : in  sl;
      pgpRxN          : in  sl;
      pgpRefClk       : in  sl;
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
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- PGP TX OP-codes (pgpTxClk domain)
      pgpTxClkOut     : out sl;
      appPgpTxIn      : in  Pgp2bTxInType);
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

   signal pgpTxIn  : Pgp2bTxInType;
   signal pgpTxOut : Pgp2bTxOutType;

   signal pgpRxIn  : Pgp2bRxInType;
   signal pgpRxOut : Pgp2bRxOutType;

   signal pgpTxMasters : AxiStreamMasterArray(3 downto 0);
   signal pgpTxSlaves  : AxiStreamSlaveArray(3 downto 0);

   signal pgpRxMasters : AxiStreamMasterArray(3 downto 0);
   signal pgpRxCtrl    : AxiStreamCtrlArray(3 downto 0);

   signal pgpTxOutClk : sl;
   signal pgpTxRst    : sl;
   signal pgpTxClk    : sl;

   signal pgpRxOutClk : sl;
   signal pgpRxClk    : sl;
   signal pgpRxRst    : sl;

   signal status : StatusType;
   signal config : ConfigType;
   
   signal evrPgpTxIn : Pgp2bTxInType := PGP2B_TX_IN_INIT_C;
   signal locTxIn    : Pgp2bTxInType := PGP2B_TX_IN_INIT_C;

begin

   pgpTxClkOut <= pgpTxClk;
   
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

   -----------
   -- PGP Core
   -----------
   U_Pgp : entity work.Pgp2bGthUltra
      generic map (
         TPD_G           => TPD_G,
         VC_INTERLEAVE_G => 1)          -- AxiStreamDmaV2 supports interleaving
      port map (
         -- GT Clocking
         stableClk       => drpClk,
         stableRst       => drpRst,
         gtRefClk        => pgpRefClk,
         -- Gt Serial IO
         pgpGtTxP        => pgpTxP,
         pgpGtTxN        => pgpTxN,
         pgpGtRxP        => pgpRxP,
         pgpGtRxN        => pgpRxN,
         -- Tx Clocking
         pgpTxReset      => pgpTxRst,
         pgpTxOutClk     => pgpTxOutClk,
         pgpTxClk        => pgpTxClk,
         pgpTxMmcmLocked => '1',
         -- Rx clocking
         pgpRxReset      => pgpRxRst,
         pgpRxOutClk     => pgpRxOutClk,
         pgpRxClk        => pgpRxClk,
         pgpRxMmcmLocked => '1',
         -- Non VC Rx Signals
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         -- Non VC Tx Signals
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         -- Frame Transmit Interface
         pgpTxMasters    => pgpTxMasters,
         pgpTxSlaves     => pgpTxSlaves,
         -- Frame Receive Interface
         pgpRxMasters    => pgpRxMasters,
         pgpRxCtrl       => pgpRxCtrl,
         -- AXI-Lite Interface 
         axilClk         => sysClk,
         axilRst         => sysRst,
         axilReadMaster  => axilReadMasters(GT_INDEX_C),
         axilReadSlave   => axilReadSlaves(GT_INDEX_C),
         axilWriteMaster => axilWriteMasters(GT_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(GT_INDEX_C));

   U_BUFG_TX : BUFG_GT
      port map (
         I       => pgpTxOutClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => pgpTxClk);


   U_BUFG_RX : BUFG_GT
      port map (
         I       => pgpRxOutClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => pgpRxClk);

   --------------         
   -- PGP Monitor
   --------------         
   U_PgpMon : entity work.Pgp2bAxi
      generic map (
         TPD_G              => TPD_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => false,
         WRITE_EN_G         => true,
         AXI_CLK_FREQ_G     => SYS_CLK_FREQ_C,
         STATUS_CNT_WIDTH_G => 16,
         ERROR_CNT_WIDTH_G  => 16)
      port map (
         -- TX PGP Interface (pgpTxClk)
         pgpTxClk        => pgpTxClk,
         pgpTxClkRst     => pgpTxRst,
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         locTxIn         => locTxIn,
         -- RX PGP Interface (pgpRxClk)
         pgpRxClk        => pgpRxClk,
         pgpRxClkRst     => pgpRxRst,
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => sysClk,
         axilRst         => sysRst,
         axilReadMaster  => axilReadMasters(MON_INDEX_C),
         axilReadSlave   => axilReadSlaves(MON_INDEX_C),
         axilWriteMaster => axilWriteMasters(MON_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(MON_INDEX_C));
         
   locTxIn.flush       <= appPgpTxIn.flush;
   locTxIn.opCodeEn    <= appPgpTxIn.opCodeEn or evrPgpTxIn.opCodeEn; 
   locTxIn.opCode      <= appPgpTxIn.opCode when(appPgpTxIn.opCodeEn = '1') else evrPgpTxIn.opCode;
   locTxIn.locData     <= appPgpTxIn.locData;
   locTxIn.flowCntlDis <= appPgpTxIn.flowCntlDis;
   locTxIn.resetTx     <= appPgpTxIn.resetTx;
   locTxIn.resetGt     <= appPgpTxIn.resetGt;
   
   ------------
   -- Misc Core
   ------------
   U_PgpMiscCtrl : entity work.PgpMiscCtrl
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Control/Status  (sysClk domain)
         status          => status,
         config          => config,
         txUserRst       => pgpTxRst,
         rxUserRst       => pgpRxRst,
         -- AXI Lite interface
         sysClk          => sysClk,
         sysRst          => sysRst,
         axilReadMaster  => axilReadMasters(CTRL_INDEX_C),
         axilReadSlave   => axilReadSlaves(CTRL_INDEX_C),
         axilWriteMaster => axilWriteMasters(CTRL_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(CTRL_INDEX_C));

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
         pgpTxClk     => pgpTxClk,
         pgpTxRst     => pgpTxRst,
         pgpRxOut     => pgpRxOut,
         pgpTxOut     => pgpTxOut,
         pgpTxMasters => pgpTxMasters,
         pgpTxSlaves  => pgpTxSlaves);

   ---------
   -- PGP RX
   ---------
   U_Rx : entity work.PgpLaneRx
      generic map (
         TPD_G          => TPD_G,
         CASCADE_SIZE_G => 4,
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
         pgpTxClk     => pgpTxClk,
         pgpTxRst     => pgpTxRst,
         pgpTxIn      => evrPgpTxIn,
         -- PGP RX Interface (pgpRxClk domain)
         pgpRxClk     => pgpRxClk,
         pgpRxRst     => pgpRxRst,
         pgpRxMasters => pgpRxMasters,
         pgpRxCtrl    => pgpRxCtrl);

end mapping;
