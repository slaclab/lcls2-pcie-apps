-------------------------------------------------------------------------------
-- File       : TimeToolCoreDebugTest.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: TimeTool Core Module
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AppPkg.all;

entity TimeToolCoreDebugTest is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_BASE_ADDR_G : slv(31 downto 0) := x"00C0_0000");
   port (
      -- Clock and Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      -- Trigger Event streams (axilClk domain)
      --trigMaster      : in  AxiStreamMasterType;
      --trigSlave       : out AxiStreamSlaveType;
      -- DMA Interfaces (axilClk domain)
      dataInMaster    : in  AxiStreamMasterType;
      dataInSlave     : out AxiStreamSlaveType;
      eventMaster     : out AxiStreamMasterType;
      eventSlave      : in  AxiStreamSlaveType;
      -- AXI-Lite Interface (axilClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);

end TimeToolCoreDebugTest;

architecture mapping of TimeToolCoreDebugTest is

   constant NUM_MASTERS_G : positive := 2;

   constant NUM_AXIL_MASTERS_C : natural := NUM_MASTERS_G+1;

   constant EVENT_INDEX_C    : natural := 0;
   constant FEX_INDEX_C      : natural := 1;
   constant PRESCALE_INDEX_C : natural := 2;

   subtype AXIL_INDEX_RANGE_C is integer range NUM_AXIL_MASTERS_C-1 downto 0;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_INDEX_RANGE_C) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(AXIL_INDEX_RANGE_C);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_INDEX_RANGE_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(AXIL_INDEX_RANGE_C);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(AXIL_INDEX_RANGE_C);

   subtype DSP_INDEX_RANGE_C is integer range NUM_AXIL_MASTERS_C-1 downto 1;

   signal dataInMasters : AxiStreamMasterArray(DSP_INDEX_RANGE_C);
   signal dataInSlaves  : AxiStreamSlaveArray(DSP_INDEX_RANGE_C);

   signal dataIbMasters : AxiStreamMasterArray(DSP_INDEX_RANGE_C);
   signal dataIbSlaves  : AxiStreamSlaveArray(DSP_INDEX_RANGE_C);

   signal dspObMasters : AxiStreamMasterArray(DSP_INDEX_RANGE_C);
   signal dspObSlaves  : AxiStreamSlaveArray(DSP_INDEX_RANGE_C);

   signal dspMasters : AxiStreamMasterArray(DSP_INDEX_RANGE_C);
   signal dspSlaves  : AxiStreamSlaveArray(DSP_INDEX_RANGE_C);


   signal dummyMaster  :  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal dummySlave   :  AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

begin

      eventMaster     <= dummyMaster;
      dummyMaster     <= dataInMaster;
      dataInSlave     <= dummySlave;
      dummySlave      <= eventSlave;

end mapping;
