------------------------------------------------------------------------------
-- File       : MigToPcieDma.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2019-03-28
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

entity MigToPcieDma is
   generic (  LANES_G          : integer          := 4;
              MONCLKS_G        : integer          := 4;
              AXIS_CONFIG_G    : AxiStreamConfigType;
              DEBUG_G          : boolean          := false );
   port    ( -- Clock and reset
             axiClk           : in  sl; -- 200MHz
             axiRst           : in  sl; -- need a user reset to clear the pipeline
             usrRst           : out sl;
             -- AXI4 Interfaces to MIG
             axiReadMasters   : out AxiReadMasterArray  (LANES_G-1 downto 0);
             axiReadSlaves    : in  AxiReadSlaveArray   (LANES_G-1 downto 0);
             -- DMA Desc Interfaces from MIG
             rdDescReq        : in  AxiReadDmaDescReqArray (LANES_G-1 downto 0);
             rdDescAck        : out slv                    (LANES_G-1 downto 0);
             rdDescRet        : out AxiReadDmaDescRetArray (LANES_G-1 downto 0);
             rdDescRetAck     : in  slv                    (LANES_G-1 downto 0);
             -- AXIStream Interface to PCIe
             axisMasters      : out AxiStreamMasterArray(LANES_G downto 0);
             axisSlaves       : in  AxiStreamSlaveArray (LANES_G downto 0);
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
             migConfig        : out MigConfigArray(LANES_G-1 downto 0);
             migStatus        : in  MigStatusArray(LANES_G-1 downto 0) );
end MigToPcieDma;

architecture mapping of MigToPcieDma is

  signal sAxilReadMaster  : AxiLiteReadMasterType;
  signal sAxilReadSlave   : AxiLiteReadSlaveType;
  signal sAxilWriteMaster : AxiLiteWriteMasterType;
  signal sAxilWriteSlave  : AxiLiteWriteSlaveType;
  signal taxisMasters     : AxiStreamMasterArray(LANES_G downto 0);
  
  type RegType is record
    axilWriteSlave : AxiLiteWriteSlaveType;
    axilReadSlave  : AxiLiteReadSlaveType;
    migConfig      : MigConfigArray      (LANES_G-1 downto 0);
    readQueCnt     : Slv8Array           (LANES_G-1 downto 0);
    writeQueCnt    : Slv8Array           (LANES_G-1 downto 0);
    -- Diagnostics control
    monEnable      : sl;
    monSampleInt   : slv                 (15 downto 0);
    monReadoutInt  : slv                 (19 downto 0);
    monSample      : sl;
    monSampleCnt   : slv                 (15 downto 0);
    monReadout     : sl;
    monReadoutCnt  : slv                 (19 downto 0);
    -- Debug
    taxisFirst     : Slv2Array           (LANES_G-1 downto 0);
    evCount        : Slv8Array           (LANES_G-1 downto 0);
    evCountDiff    : slv                 (8*LANES_G-1 downto 0);
  end record;

  constant REG_INIT_C : RegType := (
    axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
    axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
    migConfig      => (others=>MIG_CONFIG_INIT_C),
    readQueCnt     => (others=>(others=>'0')),
    writeQueCnt    => (others=>(others=>'0')),
    monEnable      => '0',
    monSampleInt   => toSlv(200,16),     -- 1MHz
    monReadoutInt  => toSlv(1000000,20), -- 1MHz -> 1Hz
    monSample      => '0',
    monSampleCnt   => (others=>'0'),
    monReadout     => '0',
    monReadoutCnt  => (others=>'0'),
    taxisFirst     => (others=>"01"),
    evCount        => (others=>(others=>'0')),
    evCountDiff    => (others=>'0') );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal monRst     : sl;
  signal monMigStatusMaster : AxiStreamMasterArray(LANES_G-1 downto 0);
  signal monMigStatusSlave  : AxiStreamSlaveArray (LANES_G-1 downto 0);
  
  constant MON_MIG_STATUS_AWIDTH_C : integer := 8;
  constant MON_WRITE_DESC_AWIDTH_C : integer := 8;

  signal monClkRate : Slv29Array(MONCLKS_G-1 downto 0);
  signal monClkSlow : slv       (MONCLKS_G-1 downto 0);
  signal monClkFast : slv       (MONCLKS_G-1 downto 0);
  signal monClkLock : slv       (MONCLKS_G-1 downto 0);

  constant MON_AXIS_CONFIG_C : AxiStreamConfigType := (
    TSTRB_EN_C    => false,
    TDATA_BYTES_C => 4,
    TDEST_BITS_C  => 0,
    TID_BITS_C    => 0,
    TKEEP_MODE_C  => TKEEP_NORMAL_C,
    TUSER_BITS_C  => 0,
    TUSER_MODE_C  => TUSER_NONE_C );
    
  constant DEBUG_C : boolean := DEBUG_G;

  component ila_0
    port ( clk : in sl;
           probe0 : in slv(255 downto 0) );
  end component;
  
begin

  axisMasters <= taxisMasters;
  
  GEN_DEBUG : if DEBUG_C generate
    U_ILAA : ila_0
      port map ( clk                  => axiClk,
                 probe0(           0) => axiRst,
                 probe0(           1) => rdDescReq(0).valid,
                 probe0(33 downto  2) => rdDescReq(0).address(31 downto 0),
                 probe0(65 downto 34) => rdDescReq(0).size   (31 downto 0),
                 probe0(          66) => rdDescRetAck(0),
                 probe0(          67) => taxisMasters(0).tValid,
                 probe0(99 downto 68) => taxisMasters(0).tData(31 downto 0),
                 probe0(         100) => taxisMasters(0).tLast,
                 probe0(         101) => axisSlaves  (0).tReady,
                 probe0(133 downto 102) => r.evCountDiff,
                 probe0(141 downto 134) => r.evCount(0),
                 probe0(149 downto 142) => r.evCount(1),
                 probe0(157 downto 150) => r.evCount(2),
                 probe0(165 downto 158) => r.evCount(3),
                 probe0(255 downto 166) => (others=>'0') );
  end generate;

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

  GEN_CHAN : for i in 0 to LANES_G-1 generate

    U_DmaRead : entity work.AxiStreamDmaV2Read
      generic map ( AXIS_READY_EN_G => true,
                    AXIS_CONFIG_G   => AXIS_CONFIG_G,
                    AXI_CONFIG_G    => APP2MIG_AXI_CONFIG_C )
      port map ( axiClk          => axiClk,
                 axiRst          => axiRst,
                 dmaRdDescReq    => rdDescReq(i),
                 dmaRdDescAck    => rdDescAck(i),
                 dmaRdDescRet    => rdDescRet(i),
                 dmaRdDescRetAck => rdDescRetAck(i),
                 dmaRdIdle       => open,
                 axiCache        => x"3",
                 axisMaster      => taxisMasters(i),
                 axisSlave       => axisSlaves (i),
                 axisCtrl        => AXI_STREAM_CTRL_UNUSED_C,
                 axiReadMaster   => axiReadMasters(i),
                 axiReadSlave    => axiReadSlaves (i) );

    GEN_MON_INLET : if i=0 generate
      monRst <= not r.monEnable or axiRst;
      U_MonMigStatus : entity work.AxisHistogram
        generic map ( ADDR_WIDTH_G => MON_MIG_STATUS_AWIDTH_C,
                      INLET_G      => true )
        port map ( clk  => axiClk,
                   rst  => monRst,
                   wen  => r.monSample,
                   addr => migStatus(i).blocksFree(BLOCK_INDEX_SIZE_C-1 downto BLOCK_INDEX_SIZE_C-8),
                   axisClk => axiClk,
                   axisRst => axiRst,
                   sPush   => r.monReadout,
                   mAxisMaster => monMigStatusMaster(i),
                   mAxisSlave  => monMigStatusSlave (i) );
    end generate;
    GEN_MON_SOCKET : if i>0 generate
      U_MonMigStatus : entity work.AxisHistogram
        generic map ( ADDR_WIDTH_G => MON_MIG_STATUS_AWIDTH_C )
        port map ( clk  => axiClk,
                   rst  => monRst,
                   wen  => r.monSample,
                   addr => migStatus(i).blocksFree(BLOCK_INDEX_SIZE_C-1 downto BLOCK_INDEX_SIZE_C-8),
                   axisClk => axiClk,
                   axisRst => axiRst,
                   sAxisMaster => monMigStatusMaster(i-1),
                   sAxisSlave  => monMigStatusSlave (i-1),
                   mAxisMaster => monMigStatusMaster(i),
                   mAxisSlave  => monMigStatusSlave (i) );
    end generate;
  end generate;

  U_MON_OUTLET : entity work.AxiStreamResize
    generic map ( SLAVE_AXI_CONFIG_G  => MON_AXIS_CONFIG_C,
                  MASTER_AXI_CONFIG_G => AXIS_CONFIG_G )
    port map ( axisClk  => axiClk,
               axisRst  => axiRst,
               sAxisMaster => monMigStatusMaster(LANES_G-1),
               sAxisSlave  => monMigStatusSlave (LANES_G-1),
               mAxisMaster => taxisMasters      (LANES_G),
               mAxisSlave  => axisSlaves        (LANES_G) );

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
     
  comb : process ( axiRst, r, sAxilReadMaster, sAxilWriteMaster, migStatus,
                   monClkRate, monClkLock, monClkFast, monClkSlow,
                   taxisMasters, axisSlaves) is
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
    for i in 0 to LANES_G-1 loop
      axiSlaveRegister(regCon, regAddr, 0, v.migConfig(i).blockSize);
      regAddr := regAddr + 4;
      axiSlaveRegister(regCon, regAddr, 8, v.migConfig(i).blocksPause);
      regAddr := regAddr + 4;
      axiSlaveRegisterR(regCon, regAddr, 0, migStatus(i).blocksFree);
      axiSlaveRegisterR(regCon, regAddr,12, migStatus(i).blocksQueued);
      regAddr := regAddr + 4;
      axiSlaveRegisterR(regCon, regAddr, 0, migStatus(i).writeQueCnt);
      regAddr := regAddr + 4;
      axiSlaveRegisterR(regCon, regAddr, 0, migStatus(i).wrIndex);
      regAddr := regAddr + 4;
      axiSlaveRegisterR(regCon, regAddr, 0, migStatus(i).wcIndex);
      regAddr := regAddr + 4;
      axiSlaveRegisterR(regCon, regAddr, 0, migStatus(i).rdIndex);
      regAddr := regAddr + 4;
      regAddr := regAddr + 4;
    end loop;

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
    v.monSample  := '0';
    
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

    for i in 0 to LANES_G-1 loop
      if (taxisMasters(i).tValid = '1' and axisSlaves(i).tReady = '1') then
        v.taxisFirst(i) := r.taxisFirst(i)(0) & taxisMasters(i).tLast;
        if r.taxisFirst(i)(1) = '1' then
          v.evCount(i)  := taxisMasters(i).tData(39 downto 32);
          v.evCountDiff(8*i+7 downto 8*i) := v.evCount(i) - r.evCount(i);
        end if;
      end if;
    end loop;
    
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



