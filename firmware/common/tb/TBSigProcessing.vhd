-------------------------------------------------------------------------------
-- File       : TimeToolKcu1500.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-24
-- Last update: 2018-11-08
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-dev'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-dev', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;
use surf.Pgp2bPkg.all;
use surf.SsiPkg.all;

library timetool; 

entity TBSigProcessing is end TBSigProcessing;

architecture testbed of TBSigProcessing is

   constant TPD_G             : time := 1 ns;
   --constant BUILD_INFO_G      : BuildInfoType;

   constant DMA_SIZE_C        : positive := 1;

   constant NUM_AXI_MASTERS_C : positive := 2;

   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);  -- 16 byte (128-bit) AXIS interface

   constant CLK_PERIOD_G : time := 10 ns;

   constant SRC_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 16, -- 128 bits
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_FIRST_LAST_C);

   signal userClk156   : sl;
   signal dmaClk       : sl;
   signal dmaRst       : sl;

   signal masterRepeaterToFEXorPrescaler : AxiStreamMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal slaveRepeaterToFEXorPrescaler  : AxiStreamSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal appInMaster  : AxiStreamMasterType;
   signal appInSlave   : AxiStreamSlaveType;
   signal appOutMaster : AxiStreamMasterType;
   signal appOutSlave  : AxiStreamSlaveType;

   signal axiClk   : sl;
   signal axiRst   : sl;

begin

   

   FileToAxiStreamSim_0 : entity timetool.FileToAxiStreamSim
               generic map (
                  TPD_G         => TPD_G,
                  BYTE_SIZE_C   => 2+1,
                  AXIS_CONFIG_G => SRC_CONFIG_C)
               port map (
                  axiClk      => axiClk,
                  axiRst      => axiRst,
                  mAxisMaster => appInMaster);

end testbed;
