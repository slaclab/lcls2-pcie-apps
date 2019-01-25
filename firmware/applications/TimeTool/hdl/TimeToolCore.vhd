-------------------------------------------------------------------------------
-- File       : TimeToolCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-04
-- Last update: 2018-11-08
-------------------------------------------------------------------------------
-- Description:
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
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPkg.all;
use work.SsiPkg.all;
use work.AxiPciePkg.all;
use work.TimingPkg.all;
use work.Pgp2bPkg.all;

library unisim;
use unisim.vcomponents.all;


entity TimeToolCore is
   generic (
      TPD_G             : time                := 1 ns;
      DEBUG_G           : boolean             := true;
      NUM_MASTERS_G     : positive            := 2;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);
      AXI_BASE_ADDR_G   : slv(31 downto 0)    := x"0000_0000");      
   port (
      -- System Interface
      sysClk          : in  sl;
      sysRst          : in  sl;
      -- DMA Interfaces (sysClk domain)
      dataInMaster    : in  AxiStreamMasterType;
      dataInSlave     : out AxiStreamSlaveType;
      dataOutMaster   : out AxiStreamMasterType;
      dataOutSlave    : in  AxiStreamSlaveType;
      -- AXI-Lite Interface (sysClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Timing information (sysClk domain)
      timingBus       : in  TimingBusType;
      -- PGP TX OP-codes (pgpTxClk domains)
      pgpTxClk        : in  sl;
      pgpTxIn         : out Pgp2bTxInType);
end TimeToolCore;

architecture mapping of TimeToolCore is

   constant NUM_AXI_MASTERS_C : natural := 2;

   constant DMA_SIZE_C : positive := 1;
   
   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 21, 20);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   --FEX stands for feature extracted
   signal masterRepeaterToFEXorPrescaler : AxiStreamMasterArray(NUM_MASTERS_G-1 downto 0);
   signal slaveRepeaterToFEXorPrescaler  : AxiStreamSlaveArray(NUM_MASTERS_G-1 downto 0);

   signal masterFEXorPrescalerToCombiner : AxiStreamMasterArray(NUM_MASTERS_G-1 downto 0);
   signal slaveFEXorPrescalerToCombiner  : AxiStreamSlaveArray(NUM_MASTERS_G-1 downto 0);

   signal masterCombinerToBatcher              : AxiStreamMasterType;
   signal slaveCombinerToBatcher               : AxiStreamSlaveType;


begin

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => sysClk,
         axiClkRst           => sysRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);


   --------------------------------------------
   --breaking out the data from detector
   --------------------------------------------

   --all modules that can't keep up with reater will need input fifo

   U_AxiStreamRepeater : entity work.AxiStreamRepeater
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => 2)
      port map (
         -- Clock and reset
         axisClk      => sysClk,
         axisRst      => sysRst,
         -- Slave
         sAxisMaster  => dataInMaster,
         sAxisSlave   => dataInSlave,
         -- Masters
         mAxisMasters => masterRepeaterToFEXorPrescaler,
         mAxisSlaves  => slaveRepeaterToFEXorPrescaler);



   --------------------------------------------
   --sending one of the repeated signals from module above to FEX or prescaling
   --------------------------------------------


   U_TimeToolFEX : entity work.TimeToolFEX_placeholder
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- System Clock and Reset
         sysClk          => sysClk,
         sysRst          => sysRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => masterRepeaterToFEXorPrescaler(0),
         dataInSlave     => slaveRepeaterToFEXorPrescaler(0),
         dataOutMaster   => masterFEXorPrescalerToCombiner(0),
         dataOutSlave    => slaveFEXorPrescalerToCombiner(0),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(0),
         axilReadSlave   => axilReadSlaves(0),
         axilWriteMaster => axilWriteMasters(0),
         axilWriteSlave  => axilWriteSlaves(0));

   --------------------------------------------
   --sending one of the repeated signals from module above to FEX or prescaling
   --------------------------------------------


   U_TimeToolPrescaler : entity work.TimeToolPrescaler
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- System Clock and Reset
         sysClk          => sysClk,
         sysRst          => sysRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => masterRepeaterToFEXorPrescaler(1),
         dataInSlave     => slaveRepeaterToFEXorPrescaler(1),
         dataOutMaster   => masterFEXorPrescalerToCombiner(1),
         dataOutSlave    => slaveFEXorPrescalerToCombiner(1),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(1),
         axilReadSlave   => axilReadSlaves(1),
         axilWriteMaster => axilWriteMasters(1),
         axilWriteSlave  => axilWriteSlaves(1));


   --------------------------------------------
   --AxiStreamBatcherEventBuilder Combines them back together
   --------------------------------------------

   U_AxiStreamBatcherEventBuilder : entity work.AxiStreamBatcherEventBuilder
      generic map (
         TPD_G         => TPD_G,
         NUM_SLAVES_G  => 2,
         AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- Clock and Reset
         axisClk      => sysClk,
         axisRst      => sysRst,
         -- AXIS Interfaces
         sAxisMasters => masterFEXorPrescalerToCombiner,
         sAxisSlaves  => slaveFEXorPrescalerToCombiner,
         mAxisMaster  => masterCombinerToBatcher,
         mAxisSlave   => slaveCombinerToBatcher);

   --------------------------------------------
   --AxiStreamBatcherEventBuilder Combines them back together
   --------------------------------------------

   U_AxiStreamBatcher : entity work.AxiStreamBatcher
      generic map (
         TPD_G         => TPD_G,
         AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- Clock and Reset
         axisClk      => sysClk,
         axisRst      => sysRst,
         -- AXIS Interfaces
         sAxisMaster  => masterCombinerToBatcher,
         sAxisSlave   => slaveCombinerToBatcher,
         mAxisMaster  => dataOutMaster,
         mAxisSlave   => dataOutSlave);

end mapping;
