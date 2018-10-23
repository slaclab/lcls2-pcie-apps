------------------------------------------------------------------------------
-- File       : MigToPcieDma.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-10-20
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
              DEBUG_G          : boolean          := true );
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
             -- (axiClk domain)
             migConfig        : out MigConfigArray(LANES_G-1 downto 0);
             migStatus        : in  MigStatusArray(LANES_G-1 downto 0) );
end MigToPcieDma;

architecture mapping of MigToPcieDma is

  signal sAxilReadMaster  : AxiLiteReadMasterType;
  signal sAxilReadSlave   : AxiLiteReadSlaveType;
  signal sAxilWriteMaster : AxiLiteWriteMasterType;
  signal sAxilWriteSlave  : AxiLiteWriteSlaveType;
  
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
    monReadoutCnt  => (others=>'0') );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal monRst     : sl;
  signal monMigStatusMaster : AxiStreamMasterArray(LANES_G-1 downto 0);
  signal monMigStatusSlave  : AxiStreamSlaveArray (LANES_G-1 downto 0);
  
  constant MON_MIG_STATUS_AWIDTH_C : integer := 8;
  constant MON_WRITE_DESC_AWIDTH_C : integer := 8;

  constant AXIS_CONFIG_C : AxiStreamConfigType := AXI_STREAM_CONFIG_INIT_C;
  constant AXI_CONFIG_C  : AxiConfigType := (
    ADDR_WIDTH_C => 40,
    DATA_BYTES_C => 16,
    ID_BITS_C    =>  2,
    LEN_BITS_C   =>  6 );
  
  constant DEBUG_C : boolean := DEBUG_G;

  component ila_0
    port ( clk : in sl;
           probe0 : in slv(255 downto 0) );
  end component;
  
begin

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
      generic map ( AXIS_CONFIG_G => AXIS_CONFIG_C,
                    AXI_CONFIG_G  => AXI_CONFIG_C )
      port map ( axiClk          => axiClk,
                 axiRst          => axiRst,
                 dmaRdDescReq    => rdDescReq(i),
                 dmaRdDescAck    => rdDescAck(i),
                 dmaRdDescRet    => rdDescRet(i),
                 dmaRdDescRetAck => rdDescRetAck(i),
                 dmaRdIdle       => open,
                 axiCache        => (others=>'0'),
                 axisMaster      => axisMasters(i),
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

  axisMasters      (LANES_G)   <= monMigStatusMaster(LANES_G-1);
  monMigStatusSlave(LANES_G-1) <= axisSlaves        (LANES_G);

  comb : process ( axiRst, r, sAxilReadMaster, sAxilWriteMaster, migStatus ) is
    variable v       : RegType;
    variable regCon  : AxiLiteEndPointType;
    variable regAddr : slv(11 downto 0);
  begin

    v := r;
    
    -- Start transaction block
    axiSlaveWaitTxn(regCon, sAxilWriteMaster, sAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

    regAddr := toSlv(0,12);
    axiSlaveRegister(regCon, regAddr, 0, v.monEnable );
    regAddr := regAddr + 16;

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



