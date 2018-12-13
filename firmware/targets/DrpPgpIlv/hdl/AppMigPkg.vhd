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
use work.AxiPkg.all;

package AppMigPkg is

   constant BLOCK_BASE_SIZE_C : integer := 21; -- 2**17 = 128kB
   constant BLOCK_INDEX_SIZE_C : integer := 32 - BLOCK_BASE_SIZE_C;
   
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
      wrIndex          : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
      wcIndex          : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
      rdIndex          : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
      blocksQueued     : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
      blocksFree       : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
      writeQueCnt      : slv(7 downto 0);
   end record;

   constant MIG_STATUS_INIT_C : MigStatusType := (
      memReady        => '0',
      wrIndex         => (others=>'0'),
      wcIndex         => (others=>'0'),
      rdIndex         => (others=>'0'),
      blocksQueued    => (others=>'0'),
      blocksFree      => (others=>'0'),
      writeQueCnt     => (others=>'0') );

   constant MIG_STATUS_BITS_C : integer := 9+5*BLOCK_INDEX_SIZE_C;
   -- Array
   type MigStatusArray is array (natural range<>) of MigStatusType;

   function toSlv      (status : MigStatusType) return slv;
   function toMigStatus(vector : slv) return MigStatusType;

   constant APP2MIG_AXI_CONFIG_C : AxiConfigType := (
     ADDR_WIDTH_C => 32,
     DATA_BYTES_C => 64,
     ID_BITS_C    => 2,
     LEN_BITS_C   => 6 );

end package AppMigPkg;

package body AppMigPkg is

  function toSlv   (status : MigStatusType) return slv is
    variable vector : slv(MIG_STATUS_BITS_C-1 downto 0);
    variable i      : integer;
  begin
    assignSlv(i, vector, status.memReady);
    assignSlv(i, vector, status.wrIndex);
    assignSlv(i, vector, status.wcIndex);
    assignSlv(i, vector, status.rdIndex);
    assignSlv(i, vector, status.blocksQueued);
    assignSlv(i, vector, status.blocksFree);
    assignSlv(i, vector, status.writeQueCnt);
    return vector;
  end function;

  function toMigStatus(vector : slv) return MigStatusType is
    variable status : MigStatusType;
    variable i      : integer := 0;
  begin
    assignRecord(i, vector, status.memReady);
    assignRecord(i, vector, status.wrIndex);
    assignRecord(i, vector, status.wcIndex);
    assignRecord(i, vector, status.rdIndex);
    assignRecord(i, vector, status.blocksQueued);
    assignRecord(i, vector, status.blocksFree);
    assignRecord(i, vector, status.writeQueCnt);
    return status;
  end function;

end package body;
