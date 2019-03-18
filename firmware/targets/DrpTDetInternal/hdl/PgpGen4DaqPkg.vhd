-------------------------------------------------------------------------------
-- File       : PgpGen4DaqPkg
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-04-24
-- Last update: 2018-01-24
-------------------------------------------------------------------------------
-- Description: AXI Stream Package File
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;

package HwDmaPkg is

   type HwDmaConfigType is record
      buffRst   : sl;
      buffOrder : slv(23 downto 0);
      appIndex  : slv( 2 downto 0);
   end record AxiStreamMasterType;

   constant HW_DMA_CONFIG_INIT_C : HwDmaConfigType := (
      buffRst   => '1',
      buffOrder => 21,
      appIndex  => "000" );

   type HwDmaConfigArray is array (natural range<>) of HwDmaConfigType;

   type HwDmaStatusType is record
      buffWriteIndex : slv(23 downto 0);
      buffReadIndex  : slv(23 downto 0);
   end record;

   constant HW_DMA_STATUS_INIT_C : HwDmaStatusType := (
      buffWriteIndex => (others=>'0'),
      buffReadIndex  => (others=>'0') );

   type HwDmaStatusArray is array (natural range<>) of HwDmaStatusType;

end package HwDmaPkg;

package body HwDmaPkg is
end package body;
