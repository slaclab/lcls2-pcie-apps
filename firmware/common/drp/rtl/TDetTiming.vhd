-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : TDetTiming.vhd
-- Author     : Matt Weaver <weaver@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-08
-- Last update: 2018-10-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 XPM Core'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 XPM Core', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.TimingExtnPkg.all;
use work.EventPkg.all;
use work.TDetPkg.all;
use work.XpmPkg.all;

library unisim;
use unisim.vcomponents.all;

entity TDetTiming is
   generic (
      TPD_G               : time             := 1 ns;
      NDET_G              : natural          := 1;
      AXIL_BASEADDR_G     : slv(31 downto 0) := (others=>'0');
      AXIL_RINGB_G        : boolean          := true );
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk          : in  sl;
      axilRst          : in  sl;
      axilReadMaster   : in  AxiLiteReadMasterType;
      axilReadSlave    : out AxiLiteReadSlaveType;
      axilWriteMaster  : in  AxiLiteWriteMasterType;
      axilWriteSlave   : out AxiLiteWriteSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------      
      -- Timing Interface
      tdetClk          : in  sl;
      tdetTiming       : in  TDetTimingArray(NDET_G-1 downto 0);
      tdetEvent        : out TDetEventArray (NDET_G-1 downto 0);
      tdetStatus       : out TDetStatusArray(NDET_G-1 downto 0);
      ----------------
      -- Core Ports --
      ----------------   
      -- LCLS Timing Ports
      timingRxP        : in  sl;
      timingRxN        : in  sl;
      timingTxP        : out sl;
      timingTxN        : out sl;
      timingRefClkInP  : in  sl;
      timingRefClkInN  : in  sl);
end TDetTiming;

architecture mapping of TDetTiming is

   signal timingRefClk   : sl;
   signal rxControl      : TimingPhyControlType;
   signal rxStatus       : TimingPhyStatusType;
   signal rxCdrStable    : sl;
   signal rxUsrClk       : sl;
   signal rxData         : slv(15 downto 0);
   signal rxDataK        : slv(1 downto 0);
   signal rxDispErr      : slv(1 downto 0);
   signal rxDecErr       : slv(1 downto 0);
   signal rxOutClk       : sl;
   signal rxRst          : sl;
   signal txStatus       : TimingPhyStatusType := TIMING_PHY_STATUS_INIT_C;
   signal txUsrClk       : sl;
   signal txUsrRst       : sl;
   signal txOutClk       : sl;
   signal loopback       : slv(2 downto 0);
   signal timingPhy      : TimingPhyType;
   signal timingBus      : TimingBusType;

   signal appTimingHdr   : TimingHeaderType; -- aligned
   signal appExptBus     : ExptBusType;      -- aligned
   signal timingHdr      : TimingHeaderType; -- prompt
   signal triggerBus     : ExptBusType;      -- prompt
   signal fullOut        : slv(NPartitions-1 downto 0);
   
begin

   -------------------------------------------------------------------------------------------------
   -- Clock Buffers
   -------------------------------------------------------------------------------------------------
   TIMING_REFCLK_IBUFDS_GTE3 : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "01",    -- 2'b01: ODIV2 = Divide-by-2 version of O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => timingRefClkInP,
         IB    => timingRefClkInN,
         CEB   => '0',
         ODIV2 => open,
         O     => timingRefClk);

   -------------------------------------------------------------------------------------------------
   -- GTH Timing Receiver
   -------------------------------------------------------------------------------------------------
     TimingGthCoreWrapper_1 : entity work.TimingGtCoreWrapper
       generic map ( TPD_G            => TPD_G,
                     EXTREF_G         => true,
                     AXIL_BASE_ADDR_G => (others=>'0') )
       port map (
         axilClk        => axilClk,
         axilRst        => axilRst,
         axilReadMaster => AXI_LITE_READ_MASTER_INIT_C,
         axilReadSlave  => open,
         axilWriteMaster=> AXI_LITE_WRITE_MASTER_INIT_C,
         axilWriteSlave => open,
         stableClk      => axilClk,
         stableRst      => axilRst,
         gtRefClk       => timingRefClk,
         gtRefClkDiv2   => '0',
         gtRxP          => timingRxP,
         gtRxN          => timingRxN,
         gtTxP          => timingTxP,
         gtTxN          => timingTxN,
         rxControl      => rxControl,
         rxStatus       => rxStatus,
         rxUsrClkActive => '1',
         rxCdrStable    => rxCdrStable,
         rxUsrClk       => rxUsrClk,
         rxData         => rxData,
         rxDataK        => rxDataK,
         rxDispErr      => rxDispErr,
         rxDecErr       => rxDecErr,
         rxOutClk       => rxOutClk,
         txControl      => timingPhy.control,
         txStatus       => txStatus,
         txUsrClk       => txUsrClk,
         txUsrClkActive => '1',
         txData         => timingPhy.data,
         txDataK        => timingPhy.dataK,
         txOutClk       => txUsrClk,
         loopback       => loopback);

   txUsrRst         <= not (txStatus.resetDone);
   rxRst            <= not (rxStatus.resetDone);
   rxUsrClk         <= rxOutClk;
   
   TimingCore_1 : entity work.TimingCore
     generic map ( TPD_G             => TPD_G,
                   CLKSEL_MODE_G     => "LCLSII",
                   USE_TPGMINI_G     => false,
                   ASYNC_G           => false,
                   AXIL_BASE_ADDR_G  => AXIL_BASEADDR_G )
     port map (
         gtTxUsrClk      => txUsrClk,
         gtTxUsrRst      => txUsrRst,
         gtRxRecClk      => rxOutClk,
         gtRxData        => rxData,
         gtRxDataK       => rxDataK,
         gtRxDispErr     => rxDispErr,
         gtRxDecErr      => rxDecErr,
         gtRxControl     => rxControl,
         gtRxStatus      => rxStatus,
         gtLoopback      => loopback,
         appTimingClk    => rxOutClk,
         appTimingRst    => rxRst,
         appTimingBus    => timingBus,
         timingPhy       => open, -- TPGMINI
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave );

   timingHdr          <= toTimingHeader (timingBus);
   triggerBus.message <= ExptMessageType(timingBus.extn);
   triggerBus.valid   <= timingBus.extnValid;

   
   U_Realign : entity work.EventRealign
     port map ( clk            => rxOutClk,
                rst            => rxRst,
                timingI        => timingHdr,
                exptBusI       => triggerBus,
                timingO        => appTimingHdr,
                exptBusO       => appExptBus,
                delay          => open );

   GEN_DET : for i in 0 to NDET_G-1 generate
     U_HeaderCache : entity work.EventHeaderCache
       port map ( rst             => rxRst,
                  --  Cache Input
                  wrclk           => rxOutClk,
                  -- configuration
                  enable          => tdetTiming(i).enable,
--                cacheenable     : in  sl := '1';     -- caches headers --
                  partition       => tdetTiming(i).partition,
                  -- event input
                  timing_prompt   => timingHdr,
                  expt_prompt     => triggerBus,
                  timing_aligned  => appTimingHdr,
                  expt_aligned    => appExptBus,
                  -- trigger output
                  pdata           => open,
                  pdataV          => open,
                  -- status
                  cntL0           => tdetStatus(i).cntL0,
                  cntL1A          => tdetStatus(i).cntL1A,
                  cntL1R          => tdetStatus(i).cntL1R,
                  cntWrFifo       => tdetStatus(i).cntWrFifo,
                  rstFifo         => open,
                  msgDelay        => tdetStatus(i).msgDelay,
                  cntOflow        => tdetStatus(i).cntOflow,
                  --  Cache Output
                  rdclk           => tdetClk,
                  advance         => tdetTiming(i).ack,
                  valid           => tdetEvent (i).valid,
                  phdr            => tdetEvent (i).isEvent,
                  cntRdFifo       => tdetStatus(i).cntRdFifo,
                  hdrOut          => tdetEvent (i).header );
   end generate;

   fullp : process ( tdetTiming ) is
     variable vfull : slv(NPartitions-1 downto 0);
   begin
     vfull := (others=>'0');
     for i in 0 to NDET_G-1 loop
       if tdetTiming(i).enable='1' and tdetTiming(i).afull='1' then
         vfull(conv_integer(tdetTiming(i).partition)) := '1';
       end if;
     end loop;
     fullOut <= vfull;
   end process fullp;
     
   U_TimingFb : entity work.XpmTimingFb
     generic map ( DEBUG_G => true )
     port map ( clk            => txUsrClk,
                rst            => txUsrRst,
                status         => txStatus,
                pllReset       => rxControl.pllReset,
                phyReset       => rxControl.reset,
                id             => tdetTiming(0).id,
                l1input        => (others=>XPM_L1_INPUT_INIT_C),
                full           => fullOut,
                phy            => timingPhy );

   p_PAddr : process (rxOutClk) is
   begin
     if rising_edge(rxOutClk) then
       if (triggerBus.valid = '1' and timingBus.strobe = '1') then
         for i in 0 to NDET_G-1 loop
           tdetStatus(i).partitionAddr <= triggerBus.message.partitionAddr;
         end loop;
       end if;
     end if;
   end process p_PAddr;
   
end mapping;
