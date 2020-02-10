------------------------------------------------------------------------------
-- File       : FrameFIR.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-04
-- Last update: 2019-11-18
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library timetool;
use timetool.AppPkg.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- This file wraps the xilinx FIR IP core.
-------------------------------------------------------------------------------

entity FrameFIR is
   generic (
      TPD_G   : time    := 1 ns;
      DEBUG_G : boolean := true);
   port (
      -- System Interface
      sysClk         : in  sl;
      sysRst         : in  sl;
      -- DMA Interfaces  (sysClk domain)
      dataInMaster   : in  AxiStreamMasterType;
      dataInSlave    : out AxiStreamSlaveType;
      dataOutMaster  : out AxiStreamMasterType;
      dataOutSlave   : in  AxiStreamSlaveType;
      -- coefficient reload  (sysClk domain)
      reloadInMaster : in  AxiStreamMasterType;
      reloadInSlave  : out AxiStreamSlaveType;
      configInMaster : in  AxiStreamMasterType;
      configInSlave  : out AxiStreamSlaveType);
end FrameFIR;

architecture mapping of FrameFIR is

---------------------------------------
-------record intitial value-----------
---------------------------------------

   signal appInMaster         : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal appInMaster_pix_rev : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal appInSlave          : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal appOutMaster         : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal appOutMaster_pix_rev : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal appOutSlave          : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal resizeFIFOToFIRMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal resizeFIFOToFIRSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal FIRToResizeFIFOMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal FIRToResizeFIFOSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;


   signal event_s_reload_tlast_missing    : sl := '0';
   signal event_s_reload_tlast_unexpected : sl := '0';

   signal not_sysRst : sl := '1';

   component fir_compiler_1
      port (
         aclk                            : in  sl;
         aresetn                         : in  sl;
         s_axis_data_tvalid              : in  sl;
         s_axis_data_tready              : out sl;
         s_axis_data_tdata               : in  slv(7 downto 0);
         s_axis_data_tlast               : in  sl;
         s_axis_config_tvalid            : in  sl;
         s_axis_config_tready            : out sl;
         s_axis_config_tdata             : in  slv(7 downto 0);
         s_axis_reload_tvalid            : in  sl;
         s_axis_reload_tready            : out sl;
         s_axis_reload_tdata             : in  slv(7 downto 0);
         s_axis_reload_tlast             : in  sl;
         m_axis_data_tvalid              : out sl;
         m_axis_data_tready              : in  sl;
         m_axis_data_tdata               : out slv(7 downto 0);
         m_axis_data_tlast               : out sl;
         event_s_reload_tlast_missing    : out sl;
         event_s_reload_tlast_unexpected : out sl);
   end component;


begin

   not_sysRst <= not sysRst;

   appInMaster <= dataInMaster;
   dataInSlave <= appInSlave;

   dataOutMaster <= appOutMaster_pix_rev;
   appOutSlave   <= dataOutSlave;

   --------------------------------
   --byte order change for input---
   --------------------------------

   appInMaster_pix_rev.tValid <= appInMaster.tValid;
   appInMaster_pix_rev.tLast  <= appInMaster.tLast;

   APP_IN_PIXEL_SWAP : for i in 0 to DSP_AXIS_CONFIG_C.TDATA_BYTES_C-1 generate

      appInMaster_pix_rev.tData(i*8+7 downto i*8) <= appInMaster.tData(((DSP_AXIS_CONFIG_C.TDATA_BYTES_C-1-i)*8+7) downto ((DSP_AXIS_CONFIG_C.TDATA_BYTES_C-1-i)*8));

   end generate APP_IN_PIXEL_SWAP;


   --------------------------------
   --byte order change for output--
   --------------------------------

   appOutMaster_pix_rev.tValid <= appOutMaster.tValid;
   appOutMaster_pix_rev.tLast  <= appOutMaster.tLast;

   APP_OUT_PIXEL_SWAP : for i in 0 to DSP_AXIS_CONFIG_C.TDATA_BYTES_C-1 generate

      appOutMaster_pix_rev.tData(i*8+7 downto i*8) <= appOutMaster.tData(((DSP_AXIS_CONFIG_C.TDATA_BYTES_C-1-i)*8+7) downto ((DSP_AXIS_CONFIG_C.TDATA_BYTES_C-1-i)*8));

   end generate APP_OUT_PIXEL_SWAP;

   --------------------------------
   --------------------------------
   --------------------------------


   U_down_size_test : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 500,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => DSP_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => DSP_AXIS_DOWNSIZED_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => sysClk,
         sAxisRst    => sysRst,
         sAxisMaster => appInMaster_pix_rev,  --appInMaster,
         sAxisSlave  => appInSlave,
         -- Master Port
         mAxisClk    => sysClk,
         mAxisRst    => sysRst,
         mAxisMaster => resizeFIFOToFIRMaster,
         mAxisSlave  => resizeFIFOToFIRSlave
         );


   dut : fir_compiler_1
      port map (
         aclk                            => sysClk,
         aresetn                         => not_sysRst,
         s_axis_data_tvalid              => resizeFIFOToFIRMaster.tValid,
         s_axis_data_tready              => resizeFIFOToFIRSlave.tReady,
         s_axis_data_tdata               => resizeFIFOToFIRMaster.tData(7 downto 0),
         s_axis_data_tlast               => resizeFIFOToFIRMaster.tLast,
         s_axis_config_tvalid            => configInMaster.tValid,
         s_axis_config_tready            => configInSlave.tReady,
         s_axis_config_tdata             => configInMaster.tData(7 downto 0),
         s_axis_reload_tvalid            => reloadInMaster.tValid,
         s_axis_reload_tready            => reloadInSlave.tReady,
         s_axis_reload_tdata             => reloadInMaster.tData(7 downto 0),
         s_axis_reload_tlast             => reloadInMaster.tLast,
         m_axis_data_tvalid              => FIRToResizeFIFOMaster.tValid,
         m_axis_data_tready              => FIRToResizeFIFOSlave.tReady,
         m_axis_data_tdata               => FIRToResizeFIFOMaster.tData(7 downto 0),
         m_axis_data_tlast               => FIRToResizeFIFOMaster.tLast,
         event_s_reload_tlast_missing    => event_s_reload_tlast_missing,
         event_s_reload_tlast_unexpected => event_s_reload_tlast_unexpected
         );

   U_up_size_test : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 500,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => DSP_AXIS_DOWNSIZED_CONFIG_C,
         MASTER_AXI_CONFIG_G => DSP_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => sysClk,
         sAxisRst    => sysRst,
         sAxisMaster => FIRToResizeFIFOMaster,
         sAxisSlave  => FIRToResizeFIFOSlave,
         -- Master Port
         mAxisClk    => sysClk,
         mAxisRst    => sysRst,
         mAxisMaster => appOutMaster,
         mAxisSlave  => appOutSlave);


end mapping;
