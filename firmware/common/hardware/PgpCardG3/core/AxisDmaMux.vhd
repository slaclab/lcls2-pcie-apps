-------------------------------------------------------------------------------
-- File       : AxisDmaMux.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-04
-- Last update: 2017-10-04
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'SLAC PGP Gen3 Card'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC PGP Gen3 Card', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiPciePkg.all;
use work.AppPkg.all;

entity AxisDmaMux is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Clock and Reset
      sysClk       : in  sl;
      sysRst       : in  sl;
      -- Single DMA Interface
      dmaObMaster  : in  AxiStreamMasterType;
      dmaObSlave   : out AxiStreamSlaveType;
      dmaIbMaster  : out AxiStreamMasterType;
      dmaIbSlave   : in  AxiStreamSlaveType;
      -- Multiple DMA Interfaces
      dmaObMasters : out AxiStreamMasterArray(7 downto 0);
      dmaObSlaves  : in  AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters : in  AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves  : out AxiStreamSlaveArray(7 downto 0));
end AxisDmaMux;

architecture mapping of AxisDmaMux is

   constant TDEST_ROUTES_C : Slv8Array := (
      0 => "0000----",  -- TDEST 0x00-0x0F = DMA[0]
      1 => "0001----",  -- TDEST 0x10-0x1F = DMA[1]
      2 => "0010----",  -- TDEST 0x20-0x2F = DMA[2]
      3 => "0011----",  -- TDEST 0x30-0x3F = DMA[3]
      4 => "0100----",  -- TDEST 0x40-0x4F = DMA[4]
      5 => "0101----",  -- TDEST 0x50-0x5F = DMA[5]
      6 => "0110----",  -- TDEST 0x60-0x6F = DMA[6]
      7 => "0111----");  -- TDEST 0x70-0x7F = DMA[7]

   signal ibMasters : AxiStreamMasterArray(7 downto 0);
   signal ibSlaves  : AxiStreamSlaveArray(7 downto 0);

begin

   -- GEN_VEC :
   -- for i in 7 downto 0 generate

      -- U_IbFifo : entity work.AxiStreamFifoV2
         -- generic map (
            -- -- General Configurations
            -- TPD_G               => TPD_G,
            -- INT_PIPE_STAGES_G   => 1,
            -- PIPE_STAGES_G       => 1,
            -- VALID_THOLD_G       => 128,  -- Hold until enough to burst into the interleaving MUX
            -- VALID_BURST_MODE_G  => true,
            -- -- FIFO configurations
            -- BRAM_EN_G           => true,
            -- XIL_DEVICE_G        => "7SERIES",
            -- USE_BUILT_IN_G      => false,
            -- GEN_SYNC_FIFO_G     => true,
            -- CASCADE_SIZE_G      => 1,
            -- FIFO_ADDR_WIDTH_G   => 9,
            -- -- AXI Stream Port Configurations
            -- SLAVE_AXI_CONFIG_G  => APP_AXIS_CONFIG_C,
            -- MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_C)
         -- port map (
            -- -- Slave Port
            -- sAxisClk    => sysClk,
            -- sAxisRst    => sysRst,
            -- sAxisMaster => dmaIbMasters(i),
            -- sAxisSlave  => dmaIbSlaves(i),
            -- -- Master Port
            -- mAxisClk    => sysClk,
            -- mAxisRst    => sysRst,
            -- mAxisMaster => ibMasters(i),
            -- mAxisSlave  => ibSlaves(i));

   -- end generate GEN_VEC;

   -- PgpLaneRx.vhd's U_RxBuffer is the store and forward FIFOs
   ibMasters <= dmaIbMasters;
   dmaIbSlaves <= ibSlaves;
   
   --------------
   -- MUX Module
   --------------               
   U_Mux : entity work.AxiStreamMux
      generic map (
         TPD_G          => TPD_G,
         NUM_SLAVES_G   => 8,
         MODE_G         => "ROUTED",
         TDEST_ROUTES_G => TDEST_ROUTES_C,
         ILEAVE_EN_G    => true,        -- Using interleaving MUX
         ILEAVE_REARB_G => 128,
         PIPE_STAGES_G  => 1)
      port map (
         -- Clock and reset
         axisClk      => sysClk,
         axisRst      => sysRst,
         -- Slaves
         sAxisMasters => ibMasters,
         sAxisSlaves  => ibSlaves,
         -- Master
         mAxisMaster  => dmaIbMaster,
         mAxisSlave   => dmaIbSlave);

   ---------------       
   -- DEMUX Module
   ---------------       
   U_AxiStreamDeMux : entity work.AxiStreamDeMux
      generic map (
         TPD_G          => TPD_G,
         NUM_MASTERS_G  => 8,
         MODE_G         => "ROUTED",
         TDEST_ROUTES_G => TDEST_ROUTES_C,
         PIPE_STAGES_G  => 1)
      port map (
         -- Clock and reset
         axisClk      => sysClk,
         axisRst      => sysRst,
         -- Slaves
         sAxisMaster  => dmaObMaster,
         sAxisSlave   => dmaObSlave,
         -- Master
         mAxisMasters => dmaObMasters,
         mAxisSlaves  => dmaObSlaves);

end mapping;
