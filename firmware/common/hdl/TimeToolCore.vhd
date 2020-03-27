-------------------------------------------------------------------------------
-- File       : TimeToolCore.vhd
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library timetool;
use timetool.AppPkg.all;

library timetool;

entity TimeToolCore is
   generic (
      TPD_G           : time             := 1 ns;
      SIMULATION_G    : boolean          := false;
      AXI_BASE_ADDR_G : slv(31 downto 0) := x"00C0_0000");
   port (
      -- Clock and Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      -- Trigger Event streams (axilClk domain)
      eventAxisMaster : in  AxiStreamMasterType;
      eventAxisSlave  : out AxiStreamSlaveType;
      clearReadout    : in  sl;
      -- PGP data from camera
      dataInMaster    : in  AxiStreamMasterType;
      dataInSlave     : out AxiStreamSlaveType;
      -- DMA Interfaces (axilClk domain)      
      eventMaster     : out AxiStreamMasterType;
      eventSlave      : in  AxiStreamSlaveType;
      -- AXI-Lite Interface (axilClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end TimeToolCore;

architecture mapping of TimeToolCore is

   constant NUM_AXIS_MASTERS_C : positive := 2;

   constant NUM_AXIL_MASTERS_C : natural := NUM_AXIS_MASTERS_C+2;

   constant EVENT_INDEX_C : natural := 0;
   constant PGP_INDEX_C   : natural := 1;

   -- These need updating
   constant FEX_INDEX_C      : natural := 1;
   constant PRESCALE_INDEX_C : natural := 2;
   constant BYPASS_INDEX_C   : natural := 3;  --this has been removed.  was causing first pixel in camera to get duplicated

   subtype AXIL_INDEX_RANGE_C is integer range NUM_AXIL_MASTERS_C-1 downto 0;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_INDEX_RANGE_C) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(AXIL_INDEX_RANGE_C);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_INDEX_RANGE_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(AXIL_INDEX_RANGE_C);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(AXIL_INDEX_RANGE_C);

   subtype DSP_INDEX_RANGE_C is integer range NUM_AXIL_MASTERS_C-2 downto 1;

   signal dataInMasters : AxiStreamMasterArray(DSP_INDEX_RANGE_C);
   signal dataInSlaves  : AxiStreamSlaveArray(DSP_INDEX_RANGE_C);

   signal dataIbMasters : AxiStreamMasterArray(DSP_INDEX_RANGE_C);
   signal dataIbSlaves  : AxiStreamSlaveArray(DSP_INDEX_RANGE_C);

   signal dspObMasters : AxiStreamMasterArray(DSP_INDEX_RANGE_C);
   signal dspObSlaves  : AxiStreamSlaveArray(DSP_INDEX_RANGE_C);

   signal dspMasters : AxiStreamMasterArray(DSP_INDEX_RANGE_C);
   signal dspSlaves  : AxiStreamSlaveArray(DSP_INDEX_RANGE_C);

   signal byPassToTimeToolMaster : AxiStreamMasterType;  --this has been removed.  was causing first pixel in camera to get duplicated
   signal byPassToTimeToolSlave  : AxiStreamSlaveType;  --this has been removed.  was causing first pixel in camera to get duplicated

   signal timeToolToByPassMaster : AxiStreamMasterType;  --this has been removed.  was causing first pixel in camera to get duplicated
   signal timeToolToByPassSlave  : AxiStreamSlaveType;  --this has been removed.  was causing first pixel in camera to get duplicated

   signal bufDataInMaster : AxiStreamMasterType;
   signal bufDataInSlave  : AxiStreamSlaveType;

   signal blowoff : sl;


begin

   ----------------------
   -- AXI Stream Repeater
   ----------------------
--    U_AxiStreamRepeater : entity surf.AxiStreamRepeater
--       generic map (
--          TPD_G         => TPD_G,
--          NUM_MASTERS_G => NUM_AXIS_MASTERS_C)
--       port map (
--          -- Clock and reset
--          axisClk      => axilClk,
--          axisRst      => axilRst,
--          -- Slave
--          sAxisMaster  => dataInMaster,
--          sAxisSlave   => dataInSlave,
--          -- Masters
--          mAxisMasters => dataInMasters,
--          mAxisSlaves  => dataInSlaves);

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity surf.AxiLiteCrossbar
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


   ----------------------------------------         
   -- FIFO between Repeater and DSP Modules
   ----------------------------------------    
   GEN_IB :
   for i in DSP_INDEX_RANGE_C generate
      U_FIFO : entity surf.AxiStreamFifoV2
         generic map (
            -- General Configurations
            TPD_G               => TPD_G,
            SLAVE_READY_EN_G    => true,
            VALID_THOLD_G       => 1,
            -- FIFO configurations
            MEMORY_TYPE_G       => "block",
            GEN_SYNC_FIFO_G     => true,
            FIFO_ADDR_WIDTH_G   => 9,
            -- AXI Stream Port Configurations
            SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_C,
            MASTER_AXI_CONFIG_G => DSP_AXIS_CONFIG_C)
         port map (
            -- Slave Port
            sAxisClk    => axilClk,
            sAxisRst    => axilRst,
            sAxisMaster => dataInMasters(i),
            sAxisSlave  => dataInSlaves(i),
            -- Master Port
            mAxisClk    => axilClk,
            mAxisRst    => axilRst,
            mAxisMaster => dataIbMasters(i),
            mAxisSlave  => dataIbSlaves(i));
   end generate GEN_IB;

   -------------
   -- FEX Module
   -------------
   U_TimeToolFEX : entity timetool.TimeToolFEX
      generic map (
         TPD_G           => TPD_G,
         AXI_BASE_ADDR_G => AXIL_CONFIG_C(FEX_INDEX_C).baseAddr)
      port map (
         -- System Clock and Reset
         axilClk         => axilClk,
         axilRst         => axilRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => dataIbMasters(FEX_INDEX_C),
         dataInSlave     => dataIbSlaves(FEX_INDEX_C),
         eventMaster     => dspObMasters(FEX_INDEX_C),
         eventSlave      => dspObSlaves(FEX_INDEX_C),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(FEX_INDEX_C),
         axilReadSlave   => axilReadSlaves(FEX_INDEX_C),
         axilWriteMaster => axilWriteMasters(FEX_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(FEX_INDEX_C));

   -------------------
   -- Prescaler Module
   -------------------
   U_TimeToolPrescaler : entity timetool.TimeToolPrescaler
      generic map (
         TPD_G => TPD_G)
      port map (
         -- System Clock and Reset
         sysClk          => axilClk,
         sysRst          => axilRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => dataIbMasters(PRESCALE_INDEX_C),
         dataInSlave     => dataIbSlaves(PRESCALE_INDEX_C),
         dataOutMaster   => dspObMasters(PRESCALE_INDEX_C),
         dataOutSlave    => dspObSlaves(PRESCALE_INDEX_C),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(PRESCALE_INDEX_C),
         axilReadSlave   => axilReadSlaves(PRESCALE_INDEX_C),
         axilWriteMaster => axilWriteMasters(PRESCALE_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PRESCALE_INDEX_C));

   ---------------------------------------------    
   -- FIFO between DSP Modules and Event Builder
   ---------------------------------------------    
   GEN_OB :
   for i in DSP_INDEX_RANGE_C generate
      U_FIFO : entity surf.AxiStreamFifoV2
         generic map (
            -- General Configurations
            TPD_G               => TPD_G,
            SLAVE_READY_EN_G    => true,
            VALID_THOLD_G       => 1,
            -- FIFO configurations
            MEMORY_TYPE_G       => "block",
            GEN_SYNC_FIFO_G     => true,
            FIFO_ADDR_WIDTH_G   => 9,
            -- AXI Stream Port Configurations
            SLAVE_AXI_CONFIG_G  => DSP_AXIS_CONFIG_C,
            MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_C)
         port map (
            -- Slave Port
            sAxisClk    => axilClk,
            sAxisRst    => axilRst,
            sAxisMaster => dspObMasters(i),
            sAxisSlave  => dspObSlaves(i),
            -- Master Port
            mAxisClk    => axilClk,
            mAxisRst    => axilRst,
            mAxisMaster => dspMasters(i),
            mAxisSlave  => dspSlaves(i));
   end generate GEN_OB;


   U_BUFFER_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => axilClk,
         sAxisRst    => axilRst,
         sAxisMaster => dataInMaster,
         sAxisSlave  => dataInSlave,
         -- Master Port
         mAxisClk    => axilClk,
         mAxisRst    => axilRst,
         mAxisMaster => bufDataInMaster,
         mAxisSlave  => bufDataInSlave);

   ------------------
   -- Create blowoff from clearReadout signal
   ------------------
   U_SynchronizerOneShot_1 : entity surf.SynchronizerOneShot
      generic map (
         TPD_G         => TPD_G,
         BYPASS_SYNC_G => true,         -- Already on the right domain
         PULSE_WIDTH_G => ite(SIMULATION_G, 10000, 10000000))
      port map (
         clk     => axilClk,            -- [in]
         rst     => axilRst,            -- [in]
         dataIn  => clearReadout,       -- [in]
         dataOut => blowoff);           -- [out]

   ----------------------
   -- EventBuilder Module
   ----------------------
   U_EventBuilder : entity surf.AxiStreamBatcherEventBuilder
      generic map (
         TPD_G          => TPD_G,
         NUM_SLAVES_G   => 2,           --NUM_AXIS_MASTERS_C+1,
         MODE_G         => "ROUTED",
         TDEST_ROUTES_G => (
            0           => "0000000-",  --,
            1           => "00000010"),
--             2           => "--------"),
         TRANS_TDEST_G  => X"01",
         AXIS_CONFIG_G  => DMA_AXIS_CONFIG_C)
      port map (
         -- Clock and Reset
         axisClk                     => axilClk,
         axisRst                     => axilRst,
         -- Misc
         blowoffExt                  => blowoff,
         -- AXI-Lite Interface (axisClk domain)
         axilReadMaster              => axilReadMasters(EVENT_INDEX_C),
         axilReadSlave               => axilReadSlaves(EVENT_INDEX_C),
         axilWriteMaster             => axilWriteMasters(EVENT_INDEX_C),
         axilWriteSlave              => axilWriteSlaves(EVENT_INDEX_C),
         -- Inbound Master AXIS Interfaces
         sAxisMasters(EVENT_INDEX_C) => eventAxisMaster,
         sAxisMasters(PGP_INDEX_C)   => bufDataInMaster,
--         sAxisMasters(DSP_INDEX_RANGE_C) => dspMasters,
         -- Inbound Slave AXIS Interfaces
         sAxisSlaves(EVENT_INDEX_C)  => eventAxisSlave,
         sAxisSlaves(PGP_INDEX_C)    => bufDataInSlave,
--         sAxisSlaves(DSP_INDEX_RANGE_C)  => dspSlaves,
         -- Outbound AXIS
         mAxisMaster                 => eventMaster,
         mAxisSlave                  => eventSlave);

end mapping;
