-------------------------------------------------------------------------------
-- File       : AxiStreamBytePackerTbTx.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-- AxiStream data packer tester, tx module
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC Firmware Standard Library', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;

use STD.textio.all;
use ieee.std_logic_textio.all;

entity FileToAxiStreamSim is
   generic (
      TPD_G           : time                := 1 ns;
      BYTE_SIZE_C     : positive            := 1;
      FRAMES_PER_BYTE : positive            := 6;
      AXIS_CONFIG_G   : AxiStreamConfigType := AXI_STREAM_CONFIG_INIT_C);
   port (
      -- System clock and reset
      axiClk       : in  sl;
      axiRst       : in  sl;
      -- Outbound frame
      mAxisMaster  : out AxiStreamMasterType);
end FileToAxiStreamSim;

architecture rtl of FileToAxiStreamSim is

   type RegType is record
      byteCount    : natural;
      frameCount   : natural;
      sleepCount : natural;
      master       : AxiStreamMasterType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      byteCount    => 0,
      frameCount   => 0,
      sleepCount   => 0,
      master       => AXI_STREAM_MASTER_INIT_C);

   file file_VECTORS : text;
   file file_RESULTS : text;
 
   constant c_WIDTH : natural := 4;

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
   signal r_ADD_TERM1 : std_logic_vector(c_WIDTH-1 downto 0) := (others => '0');
   signal r_ADD_TERM2 : std_logic_vector(c_WIDTH-1 downto 0) := (others => '0');
   signal w_SUM       : std_logic_vector(c_WIDTH downto 0);

begin

   process
      variable v : RegType;
      variable v_ILINE     : line;
      variable v_OLINE     : line;
      variable v_ADD_TERM1 : std_logic_vector(c_WIDTH-1 downto 0);
      variable v_ADD_TERM2 : std_logic_vector(c_WIDTH-1 downto 0);
      variable v_SPACE     : character;

   begin
      v := r;
      
      w_SUM <= (others=>'1');

      file_open(file_RESULTS, "output_results.txt", write_mode);
      file_open(file_VECTORS, "input_vectors.txt",  read_mode);
      

    while not endfile(file_VECTORS) loop
      readline(file_VECTORS, v_ILINE);
      read(v_ILINE, v_ADD_TERM1);
      read(v_ILINE, v_SPACE);           -- read in the space character
      read(v_ILINE, v_ADD_TERM2);
 
      -- Pass the variable to a signal to allow the ripple-carry to use it
      r_ADD_TERM1 <= v_ADD_TERM1;
      r_ADD_TERM2 <= v_ADD_TERM2;
 
      wait for 60 ns;
 
      write(v_OLINE, w_SUM, right, c_WIDTH);
      writeline(file_RESULTS, v_OLINE);
    end loop;
 
    file_close(file_VECTORS);
    file_close(file_RESULTS);
     
    wait;
  end process;

   seq : process (axiClk) is
   begin  
      if (rising_edge(axiClk)) then
         r <= rin;
      end if;
   end process;

end architecture rtl;
