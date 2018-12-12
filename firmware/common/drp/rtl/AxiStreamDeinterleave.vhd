------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AxiStreamDeinterleave.vhd
-- Author     : Matt Weaver <weaver@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-10
-- Last update: 2018-11-11
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 DAQ Software'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'LCLS2 DAQ Software', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

entity AxiStreamDeinterleave is
   generic ( LANES_G        : integer := 4;
             AXIS_CONFIG_G  : AxiStreamConfigType := AXI_STREAM_CONFIG_INIT_C );
   port ( axisClk         : in  sl;
          axisRst         : in  sl;
          sAxisMaster     : in  AxiStreamMasterArray( LANES_G-1 downto 0 );
          sAxisSlave      : out AxiStreamSlaveArray ( LANES_G-1 downto 0 );
          mAxisMaster     : out AxiStreamMasterType;
          mAxisSlave      : in  AxiStreamSlaveType );
end AxiStreamDeinterleave;

architecture top_level_app of AxiStreamDeinterleave is

  constant MAXIS_CONFIG_C : AxiStreamConfigType := (
    TSTRB_EN_C    => false,
    TDATA_BYTES_C => LANES_G*AXIS_CONFIG_G.TDATA_BYTES_C,
    TDEST_BITS_C  => AXIS_CONFIG_G.TDEST_BITS_C,
    TID_BITS_C    => AXIS_CONFIG_G.TID_BITS_C,
    TKEEP_MODE_C  => AXIS_CONFIG_G.TKEEP_MODE_C,
    TUSER_BITS_C  => AXIS_CONFIG_G.TUSER_BITS_C,
    TUSER_MODE_C  => AXIS_CONFIG_G.TUSER_MODE_C );
    
  type RegType is record
    master  : AxiStreamMasterType;
    tDest   : slv                 (LANES_G*AXIS_CONFIG_G.TDEST_BITS_C-1 downto 0);
    discard : slv                 (LANES_G-1 downto 0);
    slaves  : AxiStreamSlaveArray (LANES_G-1 downto 0);
  end record;

  constant REG_INIT_C : RegType := (
    master  => axiStreamMasterInit(MAXIS_CONFIG_C),
    tDest   => (others=>'0'),
    discard => (others=>'0'),
    slaves  => (others=>AXI_STREAM_SLAVE_INIT_C));
  
  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

begin

  comb : process ( r, axisRst, sAxisMaster, mAxisSlave ) is
    variable v : RegType;
    variable tdb, ready : sl;
    variable m,n : integer;
    variable sof, tDestv : slv(LANES_G-1 downto 0);
  begin
    v := r;

    for i in 0 to LANES_G-1 loop
      -- clear strobe signals
      v.slaves(i).tReady := '0';
      -- collect lane signals
      sof     (i) := axiStreamGetUserBit(AXIS_CONFIG_G, sAxisMaster(i), SSI_SOF_C, 0);
      tDestv  (i) := sAxisMaster(i).tDest(0);
    end loop;

    -- process acknowledge
    if mAxisSlave.tReady = '1' then
      v.master.tValid := '0';
    end if;

    --  sink any streams that have excess data
    if r.discard /= 0 then
      for i in 0 to LANES_G-1 loop
        if sAxisMaster(i).tValid = '1' and r.discard(i)='1' then
          v.slaves(i).tReady := '1';
          if sAxisMaster(i).tLast = '1' then
            v.discard(i) := '0';
          end if;
        end if;
      end loop;
    --  handle aligned streams
    else
      -- wait for all streams to contribute
      ready := '1';
      for i in 0 to LANES_G-1 loop
        if sAxisMaster(i).tValid='0' then
          ready := '0';
        end if;
      end loop;

      if ready = '1' and v.master.tValid = '0' then
        v.master := sAxisMaster(0);

        for i in 0 to LANES_G-1 loop
          for j in 0 to AXIS_CONFIG_G.TDATA_BYTES_C-1 loop
            m := 8*j;
            n := 8*(LANES_G*j+i);
            v.master.tData(n+7 downto n) := sAxisMaster(i).tData(m+7 downto m);
            v.master.tKeep(LANES_G*j+i)  := sAxisMaster(i).tKeep(j);
          end loop;
        end loop;

        -- Verify all streams are closing or not
        v.master.tLast := sAxisMaster(0).tLast;
        for i in 0 to LANES_G-1 loop
          v.discard(i) := not sAxisMaster(i).tLast;
        end loop;

        axiStreamSetUserBit(AXIS_CONFIG_G, v.master, SSI_EOFE_C, '0');
        if allBits(v.discard,'0') then
          v.master.tLast := '1';
        elsif allBits(v.discard,'1') then
          v.master.tLast := '0';
          v.discard      := (others=>'0');
        else
          v.master.tLast := '1';
          axiStreamSetUserBit(AXIS_CONFIG_G, v.master, SSI_EOFE_C, '1');
        end if;

        -- get SOF from all lanes -- validate tDest
        -- if mismatch, sink data until they match
        axiStreamSetUserBit(AXIS_CONFIG_G, v.master, SSI_SOF_C, sof(0), 0);
        -- if only one lane wrong, assume it dropped and sink all others to
        -- line up; let higher level logic resync when too many eofes.
        if sof(0)='1' then
          for i in 0 to LANES_G-1 loop
            v.tDest((i+1)*AXIS_CONFIG_G.TDEST_BITS_C-1 downto i*AXIS_CONFIG_G.TDEST_BITS_C) :=
              sAxisMaster(i).tDest(AXIS_CONFIG_G.TDEST_BITS_C-1 downto 0);
          end loop;
        else
          v.tDest := r.tDest(r.tDest'left-1 downto 0) & r.tDest(r.tDest'left);
          tdb := r.tDest(0);
          for i in 1 to LANES_G-1 loop
            if r.tDest(i*AXIS_CONFIG_G.TDEST_BITS_C)/=tdb then
              v.master.tLast := '1';
              v.discard      := (others=>'1');
              axiStreamSetUserBit(AXIS_CONFIG_G, v.master, SSI_EOFE_C, '1');
            end if;
          end loop;
        end if;
        
        if (sof(0)='1' and not (allBits(tDestV,'0') or allBits(tDestV,'1'))) then
          v.master.tLast  := '1';
          v.discard       := (others=>'1');
          axiStreamSetUserBit(AXIS_CONFIG_G, v.master, SSI_EOFE_C, '1');
          for i in 0 to LANES_G-1 loop
            if ((    tDestv = toSlv(2**i,LANES_G)) or
                (not tDestV = toSlv(2**i,LANES_G))) then
              v.discard(i) := '0';
            end if;
          end loop;
        else
          for i in 0 to LANES_G-1 loop
            v.slaves(i).tReady := '1';
          end loop;
        end if;
      end if;
    end if;

    sAxisSlave  <= v.slaves;
    mAxisMaster <= r.master;
    
    --for i in 0 to LANES_G-1 loop
    --  mAxisMaster(i)       <= r.master;
      --mAxisMaster(i).tData(AXIS_CONFIG_G.TDATA_BYTES_C*8-1 downto 0) <=
      --  r.tData((i+1)*AXIS_CONFIG_G.TDATA_BYTES_C*8-1 downto
      --          (i+0)*AXIS_CONFIG_G.TDATA_BYTES_C*8);
      --mAxisMaster(i).tKeep(AXIS_CONFIG_G.TDATA_BYTES_C-1 downto 0) <=
      --  r.tKeep((i+1)*AXIS_CONFIG_G.TDATA_BYTES_C-1 downto
      --          (i+0)*AXIS_CONFIG_G.TDATA_BYTES_C);
    --end loop;
    
    if axisRst = '1' then
      v := REG_INIT_C;
    end if;

    rin <= v;
    
  end process comb;

  seq : process ( axisClk ) is
  begin
    if rising_edge(axisClk) then
      r <= rin;
    end if;
  end process seq;
  
end top_level_app;
