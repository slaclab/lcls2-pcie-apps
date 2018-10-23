-------------------------------------------------------------------------------
-- File       : AppMigPkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-05-06
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-- Package file for AXI DMA Controller
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

use work.StdRtlPkg.all;

package AppMigPkg is

   constant BLOCK_BASE_SIZE_C : integer := 21; -- 2**17 = 128kB
   constant BLOCK_INDEX_SIZE_C : integer := 30 - BLOCK_BASE_SIZE_C;
   
   type MigConfigType is record
     blockSize   : slv(3 downto 0);
     blocksPause : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
     inhibit     : sl;
   end record;

   -- Initialization constants
   constant MIG_CONFIG_INIT_C : MigConfigType := ( 
     blockSize   => toSlv(4,4),  -- 2MB
     blocksPause => toSlv(32,BLOCK_INDEX_SIZE_C),
     inhibit     => '1' );

   -- Array
   type MigConfigArray is array (natural range<>) of MigConfigType;


   type MigStatusType is record
      memReady   : sl;
      writeSlaveBusy   : sl;
      readMasterBusy   : sl;
      blocksQueued     : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
      blocksFree       : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
      writeQueCnt      : slv(7 downto 0);
   end record;

   constant MIG_STATUS_INIT_C : MigStatusType := (
      memReady   => '0',
      writeSlaveBusy  => '0',
      readMasterBusy  => '0',
      blocksQueued    => (others=>'0'),
      blocksFree => (others=>'0'),
      writeQueCnt     => (others=>'0') );

   -- Array
   type MigStatusArray is array (natural range<>) of MigStatusType;
   
end package AppMigPkg;

package body AppMigPkg is
end package body;
