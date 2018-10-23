-------------------------------------------------------------------------------
-- File       : AxiDescPkg.vhd
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
use work.AxiStreamPkg.all;

package AxiDescPkg is

  constant DESC_STREAM_CONFIG_INIT_C : AxiStreamConfigType := (
    TSTRB_EN_C    => true,
    TDATA_BYTES_C => 10,
    TDEST_BITS_C  => 0,
    TID_BITS_C    => 0,
    TKEEP_MODE_C  => TKEEP_NORMAL_C,
    TUSER_BITS_C  => 0,
    TUSER_MODE_C  => TUSER_NONE_C );
    
   type AxiDescMasterType is record
      command : AxiStreamMasterType;
      status  : AxiStreamSlaveType;
   end record;

   -- Initialization constants
   constant AXI_DESC_MASTER_INIT_C : AxiDescMasterType := ( 
      command => axiStreamMasterInit(DESC_STREAM_CONFIG_INIT_C),
      status  => AXI_STREAM_SLAVE_INIT_C );

   -- Array
   type AxiDescMasterArray is array (natural range<>) of AxiDescMasterType;


   type AxiDescSlaveType is record
      command : AxiStreamSlaveType;
      status  : AxiStreamMasterType;
   end record;

   constant AXI_DESC_SLAVE_INIT_C : AxiDescSlaveType := (
      command => AXI_STREAM_SLAVE_INIT_C,
      status  => AXI_STREAM_MASTER_INIT_C );

   -- Array
   type AxiDescSlaveArray is array (natural range<>) of AxiDescSlaveType;
   
end package AxiDescPkg;

package body AxiDescPkg is
end package body;
