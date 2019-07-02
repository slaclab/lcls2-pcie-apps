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
      TPD_G             : time                := 1 ns;
      AXI_BASE_ADDR_G   : slv(31 downto 0)    := x"00C1_0000";
      DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2));
   port (
      -- Clock and Reset
      axilClk         : in  sl;
      axilRst         : in  sl;
      -- DMA Interfaces (axilClk domain). One for data into server, two for reloadable coefficients and config from server, one trig master?
      dataInMaster    : in  AxiStreamMasterType ;
      dataInSlave     : out AxiStreamSlaveType;
      eventMaster     : out AxiStreamMasterType;
      eventSlave      : in  AxiStreamSlaveType;
      -- AXI-Lite Interface (axilClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end TimeToolFEX;

architecture mapping of TimeToolFEX is

   constant NUM_AXIS_MASTERS_G : positive := 13;
   constant NUM_AXIL_MASTERS_C : natural  := 8;
   

   subtype  AXIL_INDEX_RANGE_C is integer range NUM_AXIL_MASTERS_C-1 downto 0;
   subtype  AXIS_INDEX_RANGE_C is integer range NUM_AXIS_MASTERS_G-1 downto 0;


   constant EVENTBUILDER_L                  : natural  := 0;
   constant EVCFILTER_L                     : natural  := 1;
   constant FIR_COEF_L                      : natural  := 2;
   constant FRAMEIIR_L                      : natural  := 3;
   constant NULLFILTER_L                    : natural  := 4;
   constant PEAKFINDER_L                    : natural  := 5;
   constant PRESCALER_L                     : natural  := 6;
   constant SUBTRACTOR_L                    : natural  := 7;


   constant REPEATER1_2_EVCFILTER           : natural  := 0;
   constant REPEATER1_2_SUBTRACTOR          : natural  := 1;
   constant EVCFILTER_2_REPEATER2           : natural  := 2;
   constant REPEATER2_2_NULLFILTER          : natural  := 3;
   constant REPEATER2_2_PRESCALER           : natural  := 4;
   constant PRESCALER_2_EVENTBUILDER        : natural  := 5;
   constant NULLFILTER_2_FRAMEIIR           : natural  := 6;
   constant FRAMEIIR_2_SUBTRACTOR           : natural  := 7;
   constant SUBTRACTOR_2_FIR                : natural  := 8;
   constant FIR_2_PEAKFINDER                : natural  := 9;
   constant PEAKFINDER_2_EVENTBUILDER       : natural  := 10;

   constant AXIL_TO_FIR_COEF                : natural  := 11;
   constant AXIL_TO_FIR_CONFIG              : natural  := 12;

   

   

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_INDEX_RANGE_C) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_G, 16, 12);

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



   U_FrameIIR : entity work.FrameIIR
      generic map (
         TPD_G             => TPD_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- System Clock and Reset
         sysClk          => axilClk,
         sysRst          => axilRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => dataInMaster,
         dataInSlave     => dataInSlave,
         dataOutMaster   => eventMaster,
         dataOutSlave    => eventSlave,
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(FRAMEIIR_L),
         axilReadSlave   => axilReadSlaves(FRAMEIIR_L),
         axilWriteMaster => axilWriteMasters(FRAMEIIR_L),
         axilWriteSlave  => axilWriteSlaves(FRAMEIIR_L));

end mapping;
