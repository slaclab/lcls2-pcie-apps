----------------------------------------------------------------
-- File       : AppTxSim.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2018-11-11
-------------------------------------------------------------------------------
-- Description: Application File
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

entity AppTxSim is
   generic (
      DMA_AXIS_CONFIG_C : AxiStreamConfigType;
      NUM_LANES_G       : integer := 4 );
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      --
      clk             : in  slv                 (NUM_LANES_G-1 downto 0);
      rst             : in  slv                 (NUM_LANES_G-1 downto 0);
      saxisMasters    : in  AxiStreamMasterArray(NUM_LANES_G-1 downto 0);
      saxisSlaves     : out AxiStreamSlaveArray (NUM_LANES_G-1 downto 0);
      maxisMasters    : out AxiStreamMasterArray(NUM_LANES_G-1 downto 0);
      maxisSlaves     : in  AxiStreamSlaveArray (NUM_LANES_G-1 downto 0);
      rxOpCodeEn      : in  slv      (NUM_LANES_G-1 downto 0);
      rxOpCode        : in  Slv8Array(NUM_LANES_G-1 downto 0);
      txFull          : out slv      (NUM_LANES_G-1 downto 0)
      );
end AppTxSim;

architecture mapping of AppTxSim is

  signal rdReg : Slv32Array(0 downto 0);
  signal wrReg : Slv32Array(1 downto 0);
  
  signal txReqMax   : Slv4Array(NUM_LANES_G-1 downto 0);
  signal txReqDly   : Slv4Array(NUM_LANES_G-1 downto 0);
  signal txClear    : slv(NUM_LANES_G-1 downto 0);
  signal txEnable   : slv(NUM_LANES_G-1 downto 0);
  signal txFixed    : slv(NUM_LANES_G-1 downto 0);
  signal txIntBase  : Slv4Array(NUM_LANES_G-1 downto 0);
  signal txIntExp   : Slv4Array(NUM_LANES_G-1 downto 0);
  signal txLength   : Slv19Array(NUM_LANES_G-1 downto 0);
  signal txOverflow : Slv32Array(NUM_LANES_G-1 downto 0);

  type StateType is (IDLE_S,
                     WAIT_S,
                     SEND_S);
  type StateArray is array(natural range<>) of StateType;
  
  type RegType is record
    state    : StateType;
    reqCnt   : slv(3 downto 0);
    reqTime  : slv(14 downto 0);
    length   : slv(18 downto 0);
    count    : slv(31 downto 0);
    tcount   : slv(31 downto 0);
    sof      : sl;
    overflow : slv(3 downto 0);
    txMaster : AxiStreamMasterType;
  end record;

  constant REG_INIT_C : RegType := (
    state       => IDLE_S,
    reqCnt      => (others=>'0'),
    reqTime     => (others=>'0'),
    length      => (others=>'0'),
    count       => (others=>'0'),
    tcount      => (others=>'0'),
    sof         => '0',
    overflow    => (others=>'0'),
    txMaster    => AXI_STREAM_MASTER_INIT_C );

  type RegArray is array(natural range<>) of RegType;
  
  signal r   : RegArray(NUM_LANES_G-1 downto 0) := (others=>REG_INIT_C);
  signal rin : RegArray(NUM_LANES_G-1 downto 0);

  constant DEBUG_C : boolean := false;
  constant dp      : integer := 3;
  
  component ila_1
    port ( clk          : in  sl;
           trig_out     : out sl;
           trig_out_ack : in  sl;
           probe0       : in  slv(255 downto 0) );
  end component;

  signal trig_out  : sl;
  signal state_r   : slv(1 downto 0);

begin
  
  GEN_DEBUG : if DEBUG_C generate
    state_r <= "00" when (r(dp).state = IDLE_S) else
               "01" when (r(dp).state = WAIT_S) else
               "10";
    U_ILA : ila_1
      port map ( clk          => clk(dp),
                 trig_out     => trig_out,
                 trig_out_ack => trig_out,
                 probe0( 1 downto  0) => state_r,
                 probe0( 5 downto  2) => r(dp).reqCnt,
                 probe0(20 downto  6) => r(dp).reqTime,
                 probe0(39 downto 21) => r(dp).length,
                 probe0(71 downto 40) => r(dp).count,
                 probe0(72) => r(dp).sof,
                 probe0(76 downto 73) => r(dp).overflow,
                 probe0(77) => rxOpCodeEn(dp),
                 probe0(78) => r(dp).txMaster.tValid,
                 probe0(79) => r(dp).txMaster.tLast,
                 probe0(80) => txEnable(dp),
                 probe0(255 downto 81) => (others=>'0') );
  end generate;

  U_Axil : entity work.AxiLiteRegs
    generic map ( NUM_WRITE_REG_G => 2 )
    port map (
      axiClk         => axilClk,
      axiClkRst      => axilRst,
      axiReadMaster  => axilReadMaster,
      axiReadSlave   => axilReadSlave,
      axiWriteMaster => axilWriteMaster,
      axiWriteSlave  => axilWriteSlave,
      writeRegister  => wrReg,
      readRegister   => rdReg );

  GEN_SYNC : for i in 0 to NUM_LANES_G-1 generate
    U_SyncTxEn : entity work.Synchronizer
      port map ( clk     => clk(i),
                 dataIn  => wrReg(0)(i),
                 dataOut => txEnable(i) );

    U_SyncTxCl : entity work.Synchronizer
      port map ( clk     => clk(i),
                 dataIn  => wrReg(0)(16+i),
                 dataOut => txClear(i) );
    
    U_SyncWr : entity work.SynchronizerVector
      generic map ( WIDTH_G => 32 )
      port map ( clk    => clk(i),
                 dataIn => wrReg(0),
                 dataOut( 7 downto  0) => open,
                 dataOut( 8 )          => txFixed  (i),
                 dataOut(12 downto  9) => txIntBase(i),
                 dataOut(15 downto 13) => txIntExp (i),
                 dataOut(23 downto 16) => open,
                 dataOut(27 downto 24) => txReqDly (i),
                 dataOut(31 downto 28) => txReqMax (i) );

    U_SyncWr1 : entity work.SynchronizerVector
      generic map ( WIDTH_G => txLength(i)'length )
      port map ( clk     => clk(i),
                 dataIn  => wrReg(1)(txLength(i)'range),
                 dataOut => txLength(i) );

    U_SyncRd : entity work.SynchronizerVector
      generic map ( WIDTH_G => 4 )
      port map ( clk     => axilClk,
                 dataIn  => r(i).overflow,
                 dataOut => rdReg(0)(4*i+3 downto 4*i) );
    
    comb : process ( r, rst, txEnable, rxOpCodeEn, saxisMasters,
                     txFixed, txIntBase, txIntExp,
                     maxisSlaves, txReqMax, txReqDly, txLength ) is
      variable v : RegType;
      variable exp  : integer;
      variable trig : sl;
      variable j    : integer;
    begin
      v := r(i);
      
      --  Fixed period triggering
      trig        := '0';
      exp         := 2*conv_integer(txIntExp(i));
      v.tcount := r(i).tcount + 1;
      if txFixed(i) = '1' then
        if r(i).tcount(exp+3 downto exp) = txIntBase(i) then
          v.tcount := (others=>'0');
          trig := '1';
        end if;
      else
        v.tcount := (others=>'0');
      end if;
      
      if maxisSlaves(i).tReady = '1' then
        v.txMaster.tValid := '0';
      end if;

      saxisSlaves(i).tReady <= '0';

      if (r(i).reqCnt < txReqMax(i) or
          txEnable(i) = '0') then
        txFull(i) <= '0';
      else
        txFull(i) <= '1';
      end if;

      if txEnable(i) = '1' then
        if ((txFixed(i) = '0' and rxOpCodeEn(i) = '1') or
            (txFixed(i) = '1' and trig = '1')) then
          if r(i).reqCnt /= toSlv(15,4) then
            v.reqCnt := r(i).reqCnt + 1;
          else
            v.overflow := r(i).overflow + 1;
          end if;
        end if;
      end if;
      
      case r(i).state is
        when IDLE_S =>
          if txEnable(i) = '0' then
            if v.txMaster.tValid = '0' then
              v.txMaster := saxisMasters(i);
              saxisSlaves  (i).tReady <= '1';
            end if;
            v.reqCnt  := (others=>'0');
            v.reqTime := (others=>'0');
          elsif r(i).reqCnt /= 0 then
            v.reqCnt  := r(i).reqCnt - 1;
            v.reqTime := (others=>'0');
            v.state   := WAIT_S;
          end if;
        when WAIT_S =>
          if r(i).reqTime(conv_integer(txReqDly(i))) = '1' then
            v.sof    := '1';
            v.state  := SEND_S;
            v.length := txLength(i);
          end if;
          v.reqTime := r(i).reqTime + 1;
        when SEND_S =>
          if v.txMaster.tValid = '0' then
            saxisSlaves(i).tReady <= '1';
            ssiSetUserSof(DMA_AXIS_CONFIG_C, v.txMaster, r(i).sof);
            v.sof             := '0';
            v.txMaster.tValid := '1';
            for j in 0 to DMA_AXIS_CONFIG_C.TDATA_BYTES_C/4-1 loop
              v.txMaster.tData(32*j+31 downto 32*j)  :=  resize(r(i).length - j, 32);
            end loop;
            v.txMaster.tLast  := '1';
            v.length          := toSlv(0,txLength(i)'length);
            v.state           := IDLE_S;
            j := conv_integer(r(i).length);
            if j <= DMA_AXIS_CONFIG_C.TDATA_BYTES_C/4 then
              v.txMaster.tKeep := (others=>'0');
              v.txMaster.tKeep(4*j-1 downto 0) := (others=>'1');
            else
              v.txMaster.tKeep := (others=>'0');
              v.txMaster.tKeep(DMA_AXIS_CONFIG_C.TDATA_BYTES_C-1 downto 0) := (others=>'1');
              v.txMaster.tLast := '0';
              v.length         := r(i).length - DMA_AXIS_CONFIG_C.TDATA_BYTES_C/4;
              v.state          := SEND_S;
            end if;
            if r(i).sof = '1' then
              v.count    := r(i).count + 1;
              v.txMaster.tData(31 downto 0) := resize(r(i).count,32);
            end if;
          end if;
        when others => null;
      end case;

      if rst(i) = '1' then
        v := REG_INIT_C;
      end if;

      rin(i) <= v;

      maxisMasters(i) <= r(i).txMaster;
      
    end process;

    process (clk) is
    begin
      if rising_edge(clk(i)) then
        r(i) <= rin(i);
      end if;
    end process;

  end generate;
  
end mapping;
