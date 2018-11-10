-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : AxiRecord.vhd
-- Author     : Matt Weaver <weaver@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-10
-- Last update: 2018-11-09
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
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;

use STD.textio.all;
use ieee.std_logic_textio.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;

entity AxiRecord is
  generic ( filename : string := "default.xtc" );
  port ( axiClk     : in  sl;
         axiMaster  : in  AxiWriteMasterType;
         axiSlave   : in  AxiWriteSlaveType );
end AxiRecord;

architecture behavior of AxiRecord is

begin

  process is
    function HexChar(v : in slv(3 downto 0)) return character is
      variable result : character := '0';
    begin
      case(v) is
        when x"0" => result := '0';
      when x"1" => result := '1';
      when x"2" => result := '2';
      when x"3" => result := '3';
      when x"4" => result := '4';
      when x"5" => result := '5';
      when x"6" => result := '6';
      when x"7" => result := '7';
      when x"8" => result := '8';
      when x"9" => result := '9';
      when x"A" => result := 'a';
      when x"B" => result := 'b';
      when x"C" => result := 'c';
      when x"D" => result := 'd';
      when x"E" => result := 'e';
      when x"F" => result := 'f';
      when others => null;
    end case;
    return result;
  end function;

  function HexString(v : in slv(31 downto 0)) return string is
    variable result : string(8 downto 1);
  begin
    for i in 0 to 7 loop
      result(i+1) := HexChar(v(4*i+3 downto 4*i));
    end loop;
    return result;
  end function;

  file results : text;
  variable oline : line;
  variable word  : slv(31 downto 0);
  variable ldone : sl;
  variable lvalid : sl;
  begin
    file_open(results, filename, write_mode);
    loop
      wait until rising_edge(axiClk);
      if axiMaster.awvalid='1' and axiSlave.awready='1' then
        write(oline, HexString(axiMaster.awaddr(63 downto 32)), right, 8);
        write(oline, HexString(axiMaster.awaddr(31 downto  0)), right, 8);
        write(oline, '.', right);
        word := x"00" & axiMaster.awid(7 downto 0) & axiMaster.awlen & resize(axiMaster.awsize,8);
        write(oline, HexString(word), right, 8);
        ldone := '0';
        while ldone='0' loop
          lvalid := '0';
          while lvalid='0' loop
            if axiMaster.wvalid='0' or axiSlave.wready='0' then
              wait until rising_edge(axiClk);
            else
              lvalid := '1';
            end if;
          end loop;
          for i in 0 to 15 loop
            if axiMaster.wstrb(8*i)='1' then
              write(oline, '.', right);
              write(oline, HexString(axiMaster.wdata( 64*i+63 downto 64*i+32)), right, 8);
              write(oline, HexString(axiMaster.wdata( 64*i+31 downto 64*i+ 0)), right, 8);
            end if;
          end loop;
          ldone := axiMaster.wlast;
          wait until rising_edge(axiClk);
        end loop;
        writeline(results, oline);
      end if;
    end loop;
    file_close(results);
  end process;

end behavior;
