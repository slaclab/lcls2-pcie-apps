-------------------------------------------------------------------------------
-- File       : TimeToolFEX.vhd
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
--
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

entity TimeToolFEX is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_BASE_ADDR_G : slv(31 downto 0) := x"00C0_0000");
   port (
      -- Clock and Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      -- Trigger Event streams (axilClk domain)
      trigMaster      : in  AxiStreamMasterType;
      trigSlave       : out AxiStreamSlaveType;
      -- DMA Interfaces (axilClk domain). One for data into server, two for reloadable coefficients and config from server, one for prescaled data?
      dataInMaster    : in  AxiStreamMasterArray(3 downto 0);  
      dataInSlave     : out AxiStreamSlaveArray(3 downto 0);
      eventMaster     : out AxiStreamMasterArray(3 downto 0);
      eventSlave      : in  AxiStreamSlaveArray(3 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end TimeToolFEX;

architecture mapping of TimeToolFEX is

   constant NUM_AXIS_MASTERS_G : positive := 12;
   constant NUM_AXIL_MASTERS_C : natural  := NUM_AXIS_MASTERS_G;
   

   subtype  AXIL_INDEX_RANGE_C is integer range NUM_AXIL_MASTERS_C-1 downto 0;
   subtype  AXIS_INDEX_RANGE_C is integer range NUM_AXIS_MASTERS_G-1 downto 0;


   constant REPEATER1_2_EVCFILTER           : natural  := 0;
   constant REPEATER1_2_SUBTRACTOR          : natural  := 1;
   constant EVCFILTER_2_REPEATER2           : natural  := 2;
   constant REPEATER2_2_NULLFILTER          : natural  := 3;
   constant REPEATER2_2_PRESCALER           : natural  := 4;
   constant PRESCALER_2_EVENTBUILDER        : natural  := 5;
   constant REPEATER2_2_NULLFILTER          : natural  := 6;
   constant NULLFILTER_2_FRAMEIIR           : natural  := 7;
   constant FRAMEIIR_2_SUBTRACTOR           : natural  := 8;
   constant SUBTRACTOR_2_FIR                : natural  := 9;
   constant FIR_2_PEAKFINDER                : natural  := 10;
   constant PEAKFINDER_2_EVENTBUILDER       : natural  := 11;
   

   

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_INDEX_RANGE_C) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 18, 14);

   signal axilWriteMasters            : AxiLiteWriteMasterArray(AXIL_INDEX_RANGE_C);
   signal axilWriteSlaves             : AxiLiteWriteSlaveArray(AXIL_INDEX_RANGE_C);
   signal axilReadMasters             : AxiLiteReadMasterArray(AXIL_INDEX_RANGE_C);
   signal axilReadSlaves              : AxiLiteReadSlaveArray(AXIL_INDEX_RANGE_C);

   signal axisMasters                 : AxiStreamMasterArray(AXIS_INDEX_RANGE_C);
   signal axisSlaves                  : AxiStreamSlaveArray(AXIS_INDEX_RANGE_C);





begin

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);


   ----------------------
   -- AXI Stream Repeater
   ----------------------
   U_AxiStreamRepeater : entity work.AxiStreamRepeater
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => 2)
      port map (
         -- Clock and reset
         axisClk      => axilClk,
         axisRst      => axilRst,
         -- Slave
         sAxisMaster  => dataInMaster(0),
         sAxisSlave   => dataInSlave(0),
         -- Masters
         mAxisMasters(0)   => axisMasters(REPEATER1_2_EVCFILTER),
         mAxisSlaves(0)    => axisSlaves(REPEATER1_2_EVCFILTER),
         mAxisMasters(1)   => axisMasters(REPEATER1_2_SUBTRACTOR),
         mAxisSlaves(1)    => axisSlaves(REPEATER1_2_SUBTRACTOR));


   -------------------
   -- Prescaler Module. Place holder for event code based filter.
   -------------------
   U_TimeToolPrescaler : entity work.TimeToolPrescaler
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C)
      port map (
         -- System Clock and Reset
         sysClk          => axilClk,
         sysRst          => axilRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => axisMasters(REPEATER1_2_EVCFILTER),
         dataInSlave     => axisSlaves(REPEATER1_2_EVCFILTER),
         dataOutMaster   => axisMasters(EVCFILTER_2_REPEATER2),
         dataOutSlave    => axisSlaves(EVCFILTER_2_REPEATER2),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(PRESCALE_INDEX_C),
         axilReadSlave   => axilReadSlaves(PRESCALE_INDEX_C),
         axilWriteMaster => axilWriteMasters(PRESCALE_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PRESCALE_INDEX_C));

   ----------------------
   -- AXI Stream Repeater
   ----------------------
   U_AxiStreamRepeater : entity work.AxiStreamRepeater
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => 2)
      port map (
         -- Clock and reset
         axisClk      => axilClk,
         axisRst      => axilRst,
         -- Slave
         sAxisMaster  => axisMasters(EVCFILTER_2_REPEATER2),
         sAxisSlave   => axisSlaves(EVCFILTER_2_REPEATER2),
         -- Masters
         mAxisMasters(0) => axisMasters(REPEATER2_2_PRESCALER),
         mAxisSlaves(0)  => axisSlaves(REPEATER2_2_PRESCALER),
         mAxisMasters(1) => axisMasters(REPEATER2_2_NULLFILTER),
         mAxisSlaves(1)  => axisSlaves(REPEATER2_2_NULLFILTER));


   -------------------
   -- Prescaler Module
   -------------------
   U_TimeToolPrescaler : entity work.TimeToolPrescaler
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C)
      port map (
         -- System Clock and Reset
         sysClk          => axilClk,
         sysRst          => axilRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => axisMasters(REPEATER2_2_PRESCALER),
         dataInSlave     => axisSlaves(REPEATER2_2_PRESCALER),
         dataOutMaster   => axisMasters(PRESCALER_2_EVENTBUILDER),
         dataOutSlave    => axisSlaves(PRESCALER_2_EVENTBUILDER),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(PRESCALE_INDEX_C),
         axilReadSlave   => axilReadSlaves(PRESCALE_INDEX_C),
         axilWriteMaster => axilWriteMasters(PRESCALE_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PRESCALE_INDEX_C));

   -------------------
   -- background subtraction
   -------------------

   U_NullPacketFilter : entity work.NullPacketFilter
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- System Clock and Reset
         sysClk          => dmaClk,
         sysRst          => dmaRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => axisMasters(REPEATER2_2_NULLFILTER),
         dataInSlave     => axisSlaves(REPEATER2_2_NULLFILTER),
         dataOutMaster   => axisMasters(NULLFILTER_2_FRAMEIIR),
         dataOutSlave    => axisSlaves(NULLFILTER_2_FRAMEIIR),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(NULL_FILTER_INDEX_C),
         axilReadSlave   => axilReadSlaves(NULL_FILTER_INDEX_C),
         axilWriteMaster => axilWriteMasters(NULL_FILTER_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(NULL_FILTER_INDEX_C));


   U_FrameIIR : entity work.FrameIIR
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- System Clock and Reset
         sysClk          => dmaClk,
         sysRst          => dmaRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => axisMasters(NULLFILTER_2_FRAMEIIR),
         dataInSlave     => axisSlaves(NULLFILTER_2_FRAMEIIR),
         dataOutMaster   => axisMasters(FRAMEIIR_2_SUBTRACTOR),
         dataOutSlave    => axisSlaves(FRAMEIIR_2_SUBTRACTOR),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(FRAME_IIR_INDEX_C),
         axilReadSlave   => axilReadSlaves(FRAME_IIR_INDEX_C),
         axilWriteMaster => axilWriteMasters(FRAME_IIR_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(FRAME_IIR_INDEX_C));

   U_FrameSubtractor : entity work.FrameSubtractor
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- System Clock and Reset
         sysClk           => dmaClk,
         sysRst           => dmaRst,
         -- DMA Interface (sysClk domain)
         dataInMaster     => axisMasters(REPEATER1_2_SUBTRACTOR),
         dataInSlave      => axisSlaves(REPEATER1_2_SUBTRACTOR),
         dataOutMaster    => axisMasters(SUBTRACTOR_2_FIR),
         dataOutSlave     => axisSlaves(SUBTRACTOR_2_FIR),
         -- Pedestal DMA Interfaces  (sysClk domain)
         pedestalInMaster =>  axisMasters(FRAMEIIR_2_SUBTRACTOR),
         pedestalInSlave  =>  axisSlaves(FRAMEIIR_2_SUBTRACTOR),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(FRAME_SUBTRACTOR_INDEX_C),
         axilReadSlave   => axilReadSlaves(FRAME_SUBTRACTOR_INDEX_C),
         axilWriteMaster => axilWriteMasters(FRAME_SUBTRACTOR_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(FRAME_SUBTRACTOR_INDEX_C));

   --------------------
   -- Surf wrapped FIR filter
   -------------------- 


   edge_to_peak: entity work.FrameFIR
   generic map(
      TPD_G             => TPD_G,
      DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
      DEBUG_G           => true )
   port map(
      -- System Interface
      sysClk          => axiClk,
      sysRst          => axiRst,
      -- DMA Interfaces  (sysClk domain)
      dataInMaster    => axisMasters(SUBTRACTOR_2_FIR),
      dataInSlave     => axisSlaves(SUBTRACTOR_2_FIR),
      dataOutMaster   => axisMasters(FIR_2_PEAKFINDER),
      dataOutSlave    => axisSlaves(FIR_2_PEAKFINDER),
      -- coefficient reload  (sysClk domain)
      reloadInMaster  => dataInMaster(1),
      reloadInSlave   => dataInSlaves(1),
      configInMaster  => dataInMaster(2),
      configInSlave   => dataInSlaves(2));


  --------------------
   -- Peak finder
   -------------------- 

     U_FramePeakFinder : entity work.FramePeakFinder
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- System Clock and Reset
         sysClk          => axiClk,
         sysRst          => axiRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => axisMasters(FIR_2_PEAKFINDER),
         dataInSlave     => axisSlaves(FIR_2_PEAKFINDER),
         dataOutMaster   => axisMasters(PEAKFINDER_2_EVENTBUILDER),
         dataOutSlave    => axisSlaves(PEAKFINDER_2_EVENTBUILDER),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0)
         );



   ----------------------
   -- EventBuilder Module
   ----------------------
   U_EventBuilder : entity work.AxiStreamBatcherEventBuilder
      generic map (
         TPD_G         => TPD_G,
         NUM_SLAVES_G  => 2,
         AXIS_CONFIG_G => DMA_AXIS_CONFIG_C)
      port map (
         -- Clock and Reset
         axisClk             => axilClk,
         axisRst             => axilRst,
         -- AXI-Lite Interface (axisClk domain)
         axilReadMaster      => axilReadMasters(EVENT_INDEX_C),
         axilReadSlave       => axilReadSlaves(EVENT_INDEX_C),
         axilWriteMaster     => axilWriteMasters(EVENT_INDEX_C),
         axilWriteSlave      => axilWriteSlaves(EVENT_INDEX_C),
         -- Inbound Master AXIS Interfaces
         sAxisMasters(0)     => axisMasters(PEAKFINDER_2_EVENTBUILDER),
         sAxisMasters(1)     => axisMasters(PRESCALER_2_EVENTBUILDER),
         -- Inbound Slave AXIS Interfaces
         sAxisSlaves(0)      => axisSlaves(PEAKFINDER_2_EVENTBUILDER),
         sAxisSlaves(1)      => axisSlaves(PRESCALER_2_EVENTBUILDER),
         -- Outbound AXIS
         mAxisMaster         => eventMaster,
         mAxisSlave          => eventSlave);

end mapping;
