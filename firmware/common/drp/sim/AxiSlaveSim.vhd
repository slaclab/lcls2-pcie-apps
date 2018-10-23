-------------------------------------------------------------------------------
-- File       : AxiSlaveSim.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-02-18
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

entity AxiSlaveSim is
   port    ( -- Clock and reset
             axiClk           : in  sl; -- 200MHz
             axiRst           : in  sl; -- need a user reset to clear the pipeline
             -- AXI4 Interface
             axiReadMaster    : in  AxiReadMasterType;
             axiReadSlave     : out AxiReadSlaveType;
             axiWriteMaster   : in  AxiWriteMasterType;
             axiWriteSlave    : out AxiWriteSlaveType );
end AxiSlaveSim;

architecture mapping of AxiSlaveSim is

  type RegType is record
    wslave : AxiWriteSlaveType;
    waddr  : integer;
    wsize  : slv(7 downto 0);
    rslave : AxiReadSlaveType;
    raddr  : integer;
    rlen   : integer;
    rsize  : slv(7 downto 0);
    bvalid : sl;
  end record;

  constant REG_INIT_C : RegType := (
    wslave => AXI_WRITE_SLAVE_INIT_C,
    waddr  => 0,
    wsize  => (others=>'0'),
    rslave => AXI_READ_SLAVE_INIT_C,
    raddr  => 0,
    rlen   => 0,
    rsize  => (others=>'0'),
    bvalid => '0');

  signal r   : RegType;
  signal rin : RegType := REG_INIT_C;

  constant ADDR_WIDTH_G      : integer := 28;
  
  type mem_type is array ((2**ADDR_WIDTH_G)-1 downto 0) of slv(7 downto 0);
  shared variable mem : mem_type := (others => x"00");

begin

  axiReadSlave  <= r.rslave;
  axiWriteSlave <= r.wslave;
  
  comb : process ( axiRst, r, axiReadMaster, axiWriteMaster ) is
    variable v : RegType;
    variable q : integer;
  begin
    v := r;

    --
    --  Read Slave
    --
    v.rslave.arready := '0';

    if axiReadMaster.rready = '1' then
      v.rslave.rvalid := '0';
    end if;
    
    if r.rlen = 0 then
      if axiReadMaster.arvalid = '1' then
        v.rslave.arready := '1';
        v.raddr := conv_integer(axiReadMaster.araddr);
        v.rlen := conv_integer(axiReadMaster.arlen)+1;
        q := conv_integer(axiReadMaster.arsize);
        v.rsize    := (others=>'0');
        v.rsize(q) := '1';
        v.rslave.rvalid := '0';
      end if;
    elsif v.rslave.rvalid = '0' then
      v.rslave.rvalid := '1';
      v.rslave.rlast  := '0';
      v.rlen         := r.rlen - 1;
      v.raddr := r.raddr + conv_integer(r.rsize);
      if v.rlen = 0 then
        v.rslave.rlast := '1';
      end if;
    end if;

    --
    -- Write Slave
    --
    v.wslave.awready := '0';
    v.wslave.wready  := '0';

    if axiWriteMaster.awvalid = '1' then
      v.wslave.awready := '1';
      v.waddr := conv_integer(axiWriteMaster.awaddr);
      q := conv_integer(axiWriteMaster.awsize);
      v.wsize    := (others=>'0');
      v.wsize(q) := '1';
    elsif axiWriteMaster.wvalid = '1' then
      v.wslave.wready := '1';
      v.waddr := r.waddr + conv_integer(v.wsize);
      if axiWriteMaster.wlast = '1' then
        v.bvalid := '1';
      end if;
    end if;

    v.wslave.bvalid := r.bvalid;
    
    if r.wslave.bvalid = '1' and axiWriteMaster.bready = '1' then
      v.wslave.bvalid := '0';
      v.bvalid       := '0';
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
      if axiWriteMaster.wvalid = '1' then
        for i in 0 to conv_integer(r.wsize)-1 loop
          mem(r.waddr+i) := axiWriteMaster.wdata(i*8+7 downto i*8);
        end loop;
      else
        for i in 0 to conv_integer(r.rsize)-1 loop
          r.rslave.rdata(i*8+7 downto i*8) <= mem(r.raddr+i);
        end loop;
      end if;
    end if;
  end process seq;
  
end mapping;
