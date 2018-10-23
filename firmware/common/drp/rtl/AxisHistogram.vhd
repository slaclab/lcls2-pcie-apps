-------------------------------------------------------------------------------
-- File       : AxisHistogram.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-02-23
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
use work.AxiStreamPkg.all;

entity AxisHistogram is
  generic ( ADDR_WIDTH_G : integer := 10;
            INLET_G      : boolean := false;
            ROLLOVER_EN_G : boolean := true );
  port    ( -- Clock and reset
    clk                 : in  sl;
    rst                 : in  sl;
    wen                 : in  sl;
    addr                : in  slv(ADDR_WIDTH_G-1 downto 0);
    --
    axisClk             : in  sl;
    axisRst             : in  sl;
    sPush               : in  sl := '0';
    sAxisMaster         : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
    sAxisSlave          : out AxiStreamSlaveType;
    mAxisMaster         : out AxiStreamMasterType;
    mAxisSlave          : in  AxiStreamSlaveType );
end AxisHistogram;

architecture mapping of AxisHistogram is

  type StreamState is ( IDLE_S, ADD_S, END_S );

  type RegType is record
    state          : StreamState;
    addrb          : slv(ADDR_WIDTH_G-1 downto 0);
    axisMaster     : AxiStreamMasterType;
    axisSlave      : AxiStreamSlaveType;
  end record;

  constant AXIS_MASTER_CONFIG_INIT_C : AxiStreamConfigType := (
    TSTRB_EN_C    => false,
    TDATA_BYTES_C => 4,
    TDEST_BITS_C  => 0,
    TID_BITS_C    => 0,
    TKEEP_MODE_C  => TKEEP_NORMAL_C,
    TUSER_BITS_C  => 0,
    TUSER_MODE_C  => TUSER_NORMAL_C);

  constant REG_INIT_C : RegType := (
    state          => IDLE_S,
    addrb          => (others=>'0'),
    axisMaster     => axiStreamMasterInit(AXIS_MASTER_CONFIG_INIT_C),
    axisSlave      => AXI_STREAM_SLAVE_INIT_C );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal dina  : slv(31 downto 0);
  signal douta : slv(31 downto 0);
  signal doutb : slv(31 downto 0);
  signal addrb : slv(ADDR_WIDTH_G-1 downto 0);

  constant END_ADDR : slv(ADDR_WIDTH_G-1 downto 0) := (others=>'1');
  
begin

  U_RAM : entity work.DualPortRam
    generic map ( DATA_WIDTH_G => 32,
                  ADDR_WIDTH_G => ADDR_WIDTH_G )
    port map ( -- Accumulation Interface
      clka   => clk,
      ena    => '1',
      wea    => wen,
      rsta   => rst,
      addra  => addr ,
      dina   => dina,
      douta  => douta,
      -- Readout Interface
      clkb   => axisClk,
      enb    => '1',
      rstb   => '0',
      addrb  => addrb,
      doutb  => doutb );

  pout : process ( clk ) is
    constant OFLOW : slv(31 downto 0) := (others=>'1');
  begin
    if rising_edge(clk) then
      if ROLLOVER_EN_G = false and douta = OFLOW then
        dina <= douta;
      else
        dina <= douta+1;
      end if;
    end if;
  end process;

  comb : process ( r, axisRst, sAxisMaster, mAxisSlave, sPush, doutb ) is
    variable v : RegType;
  begin
    v := r;

    v.axisSlave.tReady := '0';

    if mAxisSlave.tReady = '1' then
      v.axisMaster.tValid := '0';
    end if;

    if v.axisMaster.tValid = '0' then
      case r.state is
        when IDLE_S =>
          if INLET_G then
            if sPush = '1' then
              v.axisMaster.tValid := '1';
              v.axisMaster.tData(31 downto 0) := x"BDBDBD" & toSlv(ADDR_WIDTH_G,8);
              v.axisMaster.tLast  := '0';
              v.state             := ADD_S;
            end if;
          elsif sAxisMaster.tValid = '1' then
            v.axisSlave .tReady := '1';
            v.axisMaster.tValid := '1';
            v.axisMaster.tData  := sAxisMaster.tData;
            v.axisMaster.tLast  := '0';
            if sAxisMaster.tLast = '1' then
              v.axisMaster.tData(31 downto 0) := x"BDBDBD" & toSlv(ADDR_WIDTH_G,8);
              v.state         := ADD_S;
            end if;
          end if;
        when ADD_S =>
          v.addrb             := r.addrb + 1;
          v.axisMaster.tValid := '1';
          v.axisMaster.tData(doutb'range)  := doutb;
          v.axisMaster.tLast  := '0';
          if r.addrb = END_ADDR then
            v.addrb           := (others=>'0');
            v.state           := END_S;
          end if;
        when END_S =>
          v.axisMaster.tValid := '1';
          v.axisMaster.tData(31 downto 0) := x"BDBDBD00";
          v.axisMaster.tLast  := '1';
          v.state             := IDLE_S;
      end case;
    end if;

    addrb       <= v.addrb;
    sAxisSlave  <= v.axisSlave;
    mAxisMaster <= r.axisMaster;
  
    if axisRst = '1' then
      v := REG_INIT_C;
    end if;

    rin <= v;
  end process;

  seq : process ( axisClk ) is
  begin
    if rising_edge(axisClk) then
      r <= rin;
    end if;
  end process;

end mapping;
