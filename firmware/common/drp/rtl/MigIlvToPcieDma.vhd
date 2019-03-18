------------------------------------------------------------------------------
-- File       : MigIlvToPcieDma.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2019-02-11
-------------------------------------------------------------------------------
-- Description: Receives transfer requests representing data buffers pending
-- in local DRAM and moves data to CPU host memory over PCIe AXI interface.
-- Captures histograms of local DRAM buffer depth and PCIe target address FIFO
-- depth.  Needs an AxiStream to AXI channel to write histograms to host memory.
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiDmaPkg.all;
use work.AppMigPkg.all;

entity MigIlvToPcieDma is
   generic (  MONCLKS_G        : integer          := 4;
              AXI_CONFIG_G     : AxiConfigType;
              AXIS_CONFIG_G    : AxiStreamConfigType;
              DEBUG_G          : boolean          := false );
   port    ( -- Clock and reset
             axiClk           : in  sl; -- 200MHz
             axiRst           : in  sl; -- need a user reset to clear the pipeline
             usrRst           : out sl;
             seqError         : out sl;
             -- AXI4 Interfaces to MIG
             axiReadMaster    : out AxiReadMasterType;
             axiReadSlave     : in  AxiReadSlaveType;
             -- DMA Desc Interfaces from MIG
             rdDescReq        : in  AxiReadDmaDescReqType;
             rdDescAck        : out sl;
             rdDescRet        : out AxiReadDmaDescRetType;
             rdDescRetAck     : in  sl;
             -- AXIStream Interface to PCIe
             axisMasters      : out AxiStreamMasterType;
             axisSlaves       : in  AxiStreamSlaveType;
             axisOflow        : in  sl;
--             hwIbOflow        : in  slv(31 downto 0);
             -- AXI Lite Interface
             axilClk          : in  sl;
             axilRst          : in  sl;
             axilWriteMaster  : in  AxiLiteWriteMasterType;
             axilWriteSlave   : out AxiLiteWriteSlaveType;
             axilReadMaster   : in  AxiLiteReadMasterType;
             axilReadSlave    : out AxiLiteReadSlaveType;
             --
             monClk           : in  slv(MONCLKS_G-1 downto 0);
             -- (axiClk domain)
             migConfig        : out MigConfigType;
             migStatus        : in  MigStatusType );
end MigIlvToPcieDma;

architecture mapping of MigIlvToPcieDma is

  signal sAxilReadMaster  : AxiLiteReadMasterType;
  signal sAxilReadSlave   : AxiLiteReadSlaveType;
  signal sAxilWriteMaster : AxiLiteWriteMasterType;
  signal sAxilWriteSlave  : AxiLiteWriteSlaveType;
  signal taxisMasters     : AxiStreamMasterType;

  signal axisCtrl         : AxiStreamCtrlType;
  signal cntOflow         : SlVectorArray(1 downto 0,7 downto 0);
  
  type RegType is record
    axilWriteSlave : AxiLiteWriteSlaveType;
    axilReadSlave  : AxiLiteReadSlaveType;
    migConfig      : MigConfigType;
    readQueCnt     : slv                 ( 7 downto 0);
    writeQueCnt    : slv                 ( 7 downto 0);
    -- Diagnostics control
    monEnable      : sl;
    monSampleInt   : slv                 (15 downto 0);
    monReadoutInt  : slv                 (19 downto 0);
    monSample      : sl;
    monSampleCnt   : slv                 (15 downto 0);
    monReadout     : sl;
    monReadoutCnt  : slv                 (19 downto 0);
  end record;

  constant REG_INIT_C : RegType := (
    axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
    axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
    migConfig      => MIG_CONFIG_INIT_C,
    readQueCnt     => (others=>'0'),
    writeQueCnt    => (others=>'0'),
    monEnable      => '0',
    monSampleInt   => toSlv(200,16),     -- 1MHz
    monReadoutInt  => toSlv(1000000,20), -- 1MHz -> 1Hz
    monSample      => '0',
    monSampleCnt   => (others=>'0'),
    monReadout     => '0',
    monReadoutCnt  => (others=>'0') );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal monClkRate : Slv29Array(MONCLKS_G-1 downto 0);
  signal monClkSlow : slv       (MONCLKS_G-1 downto 0);
  signal monClkFast : slv       (MONCLKS_G-1 downto 0);
  signal monClkLock : slv       (MONCLKS_G-1 downto 0);

begin

  axisMasters <= taxisMasters;
  
  usrRst <= axiRst;
  
  U_AxilAsync : entity work.AxiLiteAsync
    port map ( sAxiClk         => axilClk,
               sAxiClkRst      => axilRst,
               sAxiReadMaster  => axilReadMaster,
               sAxiReadSlave   => axilReadSlave,
               sAxiWriteMaster => axilWriteMaster,
               sAxiWriteSlave  => axilWriteSlave,
               mAxiClk         => axiClk,
               mAxiClkRst      => axiRst,
               mAxiReadMaster  => sAxilReadMaster,
               mAxiReadSlave   => sAxilReadSlave,
               mAxiWriteMaster => sAxilWriteMaster,
               mAxiWriteSlave  => sAxilWriteSlave );

   U_DmaRead : entity work.AxiStreamDmaV2Read
     generic map ( AXIS_READY_EN_G => true,
                   AXIS_CONFIG_G   => AXIS_CONFIG_G,
                   AXI_CONFIG_G    => AXI_CONFIG_G )
     port map ( axiClk          => axiClk,
                axiRst          => axiRst,
                dmaRdDescReq    => rdDescReq,
                dmaRdDescAck    => rdDescAck,
                dmaRdDescRet    => rdDescRet,
                dmaRdDescRetAck => rdDescRetAck,
                dmaRdIdle       => open,
                axiCache        => x"3",
                axisMaster      => taxisMasters,
                axisSlave       => axisSlaves ,
                axisCtrl        => axisCtrl   ,
                axiReadMaster   => axiReadMaster,
                axiReadSlave    => axiReadSlave  );

  U_SeqTest : entity work.AppSeqTest
    port map ( axisClk    => axiClk,
               axisRst    => axiRst,
               axisMaster => taxisMasters,
               axisSlave  => axisSlaves,
               seqError   => seqError );
  
  GEN_MONCLK : for i in 0 to MONCLKS_G-1 generate
    U_MONCLK : entity work.SyncClockFreq
     generic map (
             REF_CLK_FREQ_G    => 200.0E+6,
             CLK_LOWER_LIMIT_G =>  25.0E+6,
             CLK_UPPER_LIMIT_G => 260.0E+6,
             CNT_WIDTH_G       => 29 )
      port map (
        freqOut     => monClkRate(i),
        freqUpdated => open,
        locked      => monClkLock  (i),
        tooFast     => monClkFast  (i),
        tooSlow     => monClkSlow  (i),
        clkIn       => monClk      (i),
        locClk      => axiClk,
        refClk      => axiClk );
  end generate;

  U_OFLOW : entity work.SynchronizerOneShotCntVector
    generic map ( COMMON_CLK_G => true,
                  CNT_WIDTH_G  => 8,
                  WIDTH_G      => 2 )
    port map ( dataIn(0)  => axisOflow,          -- ib fifo
               dataIn(1)  => axisCtrl.overflow,  -- dma
               rollOverEn => (others=>'0'),
               cntOut     => cntOflow,
               wrClk      => axiClk,
               rdClk      => axiClk );

  comb : process ( axiRst, r, sAxilReadMaster, sAxilWriteMaster,
                   migStatus, cntOflow,
                   monClkRate, monClkLock, monClkFast, monClkSlow ) is
    variable v       : RegType;
    variable regCon  : AxiLiteEndPointType;
    variable regAddr : slv(11 downto 0);
  begin

    v := r;
    
    -- Start transaction block
    axiSlaveWaitTxn(regCon, sAxilWriteMaster, sAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

    regAddr := toSlv(0,12);
    axiSlaveRegister(regCon, regAddr, 0, v.monEnable );

    regAddr := toSlv(128,12); 

    axiSlaveRegister(regCon, regAddr, 0, v.migConfig.blockSize);
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 8, v.migConfig.blocksPause);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, migStatus.blocksFree);
    axiSlaveRegisterR(regCon, regAddr,12, migStatus.blocksQueued);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, migStatus.writeQueCnt);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, migStatus.wrIndex);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, migStatus.wcIndex);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, migStatus.rdIndex);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, muxSlVectorArray(cntOflow,0));
    axiSlaveRegisterR(regCon, regAddr, 8, muxSlVectorArray(cntOflow,1));
    regAddr := regAddr + 4;

    regAddr := toSlv(256,12);
    for i in 0 to MONCLKS_G-1 loop
      axiSlaveRegisterR(regCon, regAddr,  0, monClkRate(i));
      axiSlaveRegisterR(regCon, regAddr, 29, monClkSlow(i));
      axiSlaveRegisterR(regCon, regAddr, 30, monClkFast(i));
      axiSlaveRegisterR(regCon, regAddr, 31, monClkLock(i));
      regAddr := regAddr + 4;
    end loop;
      
    -- End transaction block
    axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave);

    sAxilWriteSlave <= r.axilWriteSlave;
    sAxilReadSlave  <= r.axilReadSlave;
    
    v.monReadout := '0';

    if r.monEnable = '1' then
      if r.monSampleCnt = r.monSampleInt then
        v.monSample    := '1';
        v.monSampleCnt := (others=>'0');
      else
        v.monSampleCnt := r.monSampleCnt + 1;
      end if;
      if r.monSample = '1' then
        if r.monReadoutCnt = r.monReadoutInt then
          v.monReadout    := '1';
          v.monReadoutCnt := (others=>'0');
        else
          v.monReadoutCnt := r.monReadoutCnt + 1;
        end if;
      end if;
    else
      v.monSampleCnt  := (others=>'0');
      v.monReadoutCnt := (others=>'0');
    end if;

    if axiRst = '1' then
      v := REG_INIT_C;
    end if;

    rin <= v;

    migConfig <= r.migConfig;
    
  end process comb;

  seq: process(axiClk) is
  begin
    if rising_edge(axiClk) then
      r <= rin;
    end if;
  end process seq;
      
 end mapping;



