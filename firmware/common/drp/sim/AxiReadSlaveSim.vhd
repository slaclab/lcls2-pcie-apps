-------------------------------------------------------------------------------
-- File       : AxiReadSlaveSim.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-03-11
-------------------------------------------------------------------------------
-- Description: Wrapper for Xilinx Axi Data Mover
-- Axi stream input (dscReadMasters.command) launches an AxiReadMaster to
-- read from a memory mapped device and write to another memory mapped device
-- with an AxiWriteMaster to a start address given by the AxiLite bus register
-- writes.  Completion of the transfer results in another axi write.
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

entity AxiReadSlaveSim is
   port    ( -- Clock and reset
             axiClk           : in  sl; -- 200MHz
             axiRst           : in  sl; -- need a user reset to clear the pipeline
             -- AXI4 Interface
             axiReadMaster    : in  AxiReadMasterType;
             axiReadSlave     : out AxiReadSlaveType );
end AxiReadSlaveSim;

architecture mapping of AxiReadSlaveSim is

  type RegType is record
    slave : AxiReadSlaveType;
    busy  : sl;
    rlen  : integer;
    rword : integer;
    addr  : slv(63 downto 0);
    rsize : slv(7 downto 0);
  end record;

  constant REG_INIT_C : RegType := (
    slave => AXI_READ_SLAVE_INIT_C,
    busy  => '0',
    rlen  => 0,
    rword => 0,
    addr  => (others=>'0'),
    rsize => (others=>'0') );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;
  
begin

  axiReadSlave <= r.slave;
  
  comb : process ( axiRst, r, axiReadMaster ) is
    variable v : RegType;
    variable q : integer;
  begin
    v := r;

    v.slave.arready := '0';

    if axiReadMaster.rready = '1' then
      v.slave.rvalid := '0';
    end if;
    
    if r.busy = '0' then
      if axiReadMaster.arvalid = '1' then
        v.busy  := '1';
        v.slave.arready := '1';
        v.slave.rid     := axiReadMaster.arid;
        v.rlen  := conv_integer(axiReadMaster.arlen)+1;
        v.addr  := axiReadMaster.araddr;
        v.rword := 0;
        q := conv_integer(axiReadMaster.arsize);
        v.rsize    := (others=>'0');
        v.rsize(q) := '1';
        v.slave.rvalid := '0';
        v.slave.rlast  := '0';
      end if;
    elsif v.slave.rvalid = '0' then
      v.slave.rvalid := '1';
      v.slave.rlast  := '0';
      v.rlen         := r.rlen;
      v.rword        := r.rword + 1;
      if r.rword = 0 then
        v.slave.rdata := (others=>'1');
        v.slave.rdata(63 downto 0) := r.addr;
        for i in 8 to conv_integer(r.rsize)-1 loop
          v.slave.rdata(i*8+7 downto i*8) := toSlv(r.rword*conv_integer(r.rsize) + i,8);
        end loop;
      else
        v.slave.rdata := (others=>'0');
        for i in 0 to conv_integer(r.rsize)-1 loop
          v.slave.rdata(i*8+7 downto i*8) := toSlv(r.rword*conv_integer(r.rsize) + i,8);
        end loop;
      end if;
      if v.rword = r.rlen then
        v.slave.rlast := '1';
        v.busy := '0';
      end if;
    end if;
    
    if axiRst = '1' then
      v := REG_INIT_C;
    end if;

    rin <= v;
  end process comb;

  seq : process (axiClk) is
  begin
    if rising_edge(axiClk) then
      r <= rin;
    end if;
  end process seq;
  
end mapping;
