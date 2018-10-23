-------------------------------------------------------------------------------
-- File       : AxiStreamFlow.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2018-06-24
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'SLAC PGP Gen3 Card'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC PGP Gen3 Card', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

entity AxiStreamFlow is
   generic ( DEBUG_G : boolean := false);
   port (
      clk             : in  sl;
      rst             : in  sl;
      sAxisMaster     : in  AxiStreamMasterType;
      sAxisCtrl       : out AxiStreamCtrlType;
      mAxisMaster     : out AxiStreamMasterType;
      mAxisCtrl       : in  AxiStreamCtrlType;
      ibFull          : in  sl;
      drop            : out sl;
      trunc           : out sl );
end AxiStreamFlow;

architecture mapping of AxiStreamFlow is

   type StateType is (IDLE_S, RECV_S, DUMP_S);
   
   type RegType is record
     state      : StateType;
     axisMaster : AxiStreamMasterType;
     drop       : sl;
     trunc      : sl;
     ibFull     : sl;
   end record;

   constant REG_INIT_C : RegType := (
     state      => IDLE_S,
     axisMaster => AXI_STREAM_MASTER_INIT_C,
     drop       => '0',
     trunc      => '0',
     ibFull     => '0');

   signal r    : RegType := REG_INIT_C;
   signal r_in : RegType;

   component ila_0
     port ( clk : in sl;
            probe0 : in slv(255 downto 0) );
   end component;

   signal r_state : slv(1 downto 0);

   signal ibFullS : sl;
   signal isFull : sl;
begin

  isFull <= mAxisCtrl.pause;
--  isFull <= mAxisCtrl.pause or r.ibFull;

  --U_FullS : entity work.Synchronizer
  --  port map ( clk     => clk,
  --             dataIn  => ibFull,
  --             dataOut => ibFullS );

  ibFullS <= '0';
  
  GEN_DEBUG : if DEBUG_G generate
    r_state <= "00" when r.state = IDLE_S else
               "01" when r.state = RECV_S else
               "10";
    U_ILA : ila_0
      port map ( clk      => clk,
                 probe0(0) => sAxisMaster.tValid,
                 probe0(1) => sAxisMaster.tLast,
                 probe0(9 downto 2) => sAxisMaster.tData(7 downto 0),
                 probe0(10) => r.axisMaster.tValid,
                 probe0(11) => r.axisMaster.tLast,
                 probe0(19 downto 12) => r.axisMaster.tData(7 downto 0),
                 probe0(20) => mAxisCtrl.pause,
                 probe0(21) => r.ibFull,
                 probe0(23 downto 22)  => r_state,
                 probe0(24)            => r.drop,
                 probe0(25)            => r.trunc,
                 probe0(26)            => isFull,
                 probe0(255 downto 27) => (others=>'0') );
  end generate;
  
  comb : process ( r, rst, sAxisMaster, mAxisCtrl, isFull, ibFullS ) is
    variable v : RegType;
  begin
    v := r;

    v.drop       := '0';
    v.trunc      := '0';
    v.axisMaster := sAxisMaster;
    v.ibFull     := ibFullS;
    
    case r.state is
      when IDLE_S =>
        if sAxisMaster.tValid = '1' then
          if isFull = '1' then
            v.axisMaster.tValid := '0';
            v.drop              := '1';
            if sAxisMaster.tLast = '0' then
              v.state := DUMP_S;
            end if;
          elsif sAxisMaster.tLast = '0' then
            v.state := RECV_S;
          end if;
        end if;
      when RECV_S =>
        if sAxisMaster.tValid = '1' then
          if sAxisMaster.tLast = '1' then
            v.state := IDLE_S;
          elsif isFull = '1' then
            v.trunc      := '1';
            v.axisMaster := SSI_MASTER_FORCE_EOFE_C;
            if sAxisMaster.tLast = '0' then
              v.state := DUMP_S;
            end if;
          end if;
        end if;
      when DUMP_S =>
        v.axisMaster.tValid := '0';
        if sAxisMaster.tValid = '1' and sAxisMaster.tLast = '1' then
          v.state := IDLE_S;
        end if;
    end case;

    drop            <= r.drop;
    trunc           <= r.trunc;
    sAxisCtrl       <= mAxisCtrl;
    sAxisCtrl.pause <= '0';
    mAxisMaster     <= r.axisMaster;
    
    if rst = '1' then
      v := REG_INIT_C;
    end if;

    r_in <= v;

  end process comb;

  seq : process ( clk ) is
  begin
    if rising_edge(clk) then
      r <= r_in;
    end if;
  end process seq;
  
end architecture mapping;
