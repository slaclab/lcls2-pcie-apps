----------------------------------------------------------------
-- File       : AppTxOpCode.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2018-03-07
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

entity AppTxOpCode is
   port (
      -- AXI-Lite Interface (axilClk domain)
      clk         : in  sl;
      rst         : in  sl;
      rxFull      : in  sl;
      txFull      : in  sl;
      txOpCodeEn  : out sl;
      txOpCode    : out slv(7 downto 0)
      );
end AppTxOpCode;

architecture mapping of AppTxOpCode is
  
   constant NONE_AF_OPCODE : slv(7 downto 0) := x"00";
   constant RX_AF_OPCODE   : slv(7 downto 0) := x"01";   -- receive queue almost full
   constant TX_AF_OPCODE   : slv(7 downto 0) := x"02";   -- receive queue almost full
   constant BOTH_AF_OPCODE : slv(7 downto 0) := x"03";   -- both queues almost full

   type RegType is record
     upCnt   : slv(9 downto 0);
     irxFull : sl;
     itxFull : sl;
     opCodeEn: sl;
     opCode  : slv(7 downto 0);
   end record;

   constant REG_INIT_C : RegType := (
     upCnt   => (others=>'0'),
     irxFull => '0',
     itxFull => '0',
     opCodeEn=> '0',
     opCode  => (others=>'0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
begin

  txOpCodeEn <= r.opCodeEn;
  txOpCode   <= r.opCode;
  
  comb : process ( r, rst, rxFull, txFull ) is
     variable v : RegType;
  begin
     v := r;

     v.upCnt    := v.upCnt + 1;
     v.opCodeEn := '0';
     if ((r.upCnt = toSlv(511,10)) or  -- timeout
         (r.upCnt(8 downto 6) /= 0 and
          (rxFull /= r.irxFull or
           txFull /= r.itxFull))) then
       v.upCnt    := (others=>'0');
       v.opCodeEn := '1';
       v.irxFull  := rxFull;
       v.itxFull  := txFull;
       if rxFull = '0' and txFull = '0' then
         v.opCode   := NONE_AF_OPCODE;
       elsif rxFull = '1' and txFull = '0' then
         v.opCode   := RX_AF_OPCODE;
       elsif rxFull = '0' and txFull = '1' then
         v.opCode   := TX_AF_OPCODE;
       else
         v.opCode   := BOTH_AF_OPCODE;
       end if;
     end if;

     rin <= v;
  end process comb;
  
  process (clk) is
  begin
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process;
end mapping;
