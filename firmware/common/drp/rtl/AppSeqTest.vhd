------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AppSeqTest.vhd
-- Author     : Matt Weaver <weaver@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-10
-- Last update: 2019-02-07
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

entity AppSeqTest is
   port ( axisClk         : in  sl;
          axisRst         : in  sl;
          axisMaster      : in  AxiStreamMasterType;
          axisSlave       : in  AxiStreamSlaveType;
          seqError        : out sl );
end AppSeqTest;

architecture top_level_app of AppSeqTest is

  type RegType is record
    sofd    : slv(3 downto 0);
    seqTest : sl;
    seqErr  : sl;
    seqData : slv(15 downto 0);
  end record;

  constant REG_INIT_C : RegType := (
    sofd    => (others=>'0'),
    seqTest => '0',
    seqErr  => '0',
    seqData => (others=>'0') );
  
  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  component ila_0
    port ( clk    : in sl;
           probe0 : in slv(255 downto 0) );
  end component;
  
begin

  U_ILA : ila_0
    port map ( clk                    => axisClk,
               probe0( 15 downto   0) => r.seqData(15 downto 0),
               probe0( 19 downto  16) => r.sofd,
               probe0(            20) => r.seqTest,
               probe0(            21) => r.seqErr,
               probe0(            22) => axisMaster.tValid,
               probe0(            23) => axisMaster.tLast,
               probe0(            24) => axisSlave.tReady,
               probe0(255 downto  25) => (others=>'0') );
  
  comb : process ( r, axisRst, axisMaster, axisSlave ) is
    variable v : RegType;
  begin
    v := r;

    v.seqErr := '0';
    
    -- Test sequence of data to isolate source of 32B drop/add error
    if axisMaster.tValid = '1' and axisSlave.tReady = '1' then
      v.sofd := r.sofd(2 downto 0) & axisMaster.tLast;

      if r.sofd = "1000" then
        v.seqTest := '1';
      end if;
      if axisMaster.tLast = '1' then
        v.seqTest := '0';
      end if;

      if r.seqTest = '1' then
        if axisMaster.tData(10 downto 0) /= (r.seqData(10 downto 0)+4) then
          v.seqErr := '1';
        end if;
      end if;

      v.seqData := axisMaster.tData(15 downto 0);
      
    end if;
    
    if axisRst = '1' then
      v := REG_INIT_C;
    end if;

    rin <= v;
    seqError <= r.seqErr;
    
  end process comb;

  seq : process ( axisClk ) is
  begin
    if rising_edge(axisClk) then
      r <= rin;
    end if;
  end process seq;
  
end top_level_app;
