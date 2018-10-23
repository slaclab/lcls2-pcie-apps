-------------------------------------------------------------------------------
-- File       : PgpLaneRx.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2018-06-27
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.Pgp3Pkg.all;
use work.AxiPciePkg.all;

entity PgpLaneRx is
   generic (
      TPD_G    : time     := 1 ns;
      LANE_G   : natural  := 0;
      NUM_VC_G : positive := 16);
   port (
      -- DMA Interface (dmaClk domain)
      dmaClk       : in  sl;
      dmaRst       : in  sl;
      dmaIbMaster  : out AxiStreamMasterType;
      dmaIbSlave   : in  AxiStreamSlaveType;
      dmaIbFull    : in  sl;
      frameDrop    : out sl;
      frameTrunc   : out sl;
      sAxisCtrl    : out AxiStreamCtrlType;
      -- PGP Interface (pgpClk domain)
      pgpClk       : in  sl;
      pgpRst       : in  sl;
      pgpRxMasters : in  AxiStreamMasterArray(NUM_VC_G-1 downto 0);
      pgpRxCtrl    : out AxiStreamCtrlArray(NUM_VC_G-1 downto 0));
end PgpLaneRx;

architecture mapping of PgpLaneRx is

   function TdestRoutes return Slv8Array is
      variable retConf : Slv8Array(NUM_VC_G-1 downto 0);
   begin
      for i in NUM_VC_G-1 downto 0 loop
         retConf(i) := toSlv((32*LANE_G)+i, 8);
      end loop;
      return retConf;
   end function;

   signal intPgpRxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal intPgpRxCtrl    : AxiStreamCtrlArray  (NUM_VC_G-1 downto 0);

   signal rxMasters : AxiStreamMasterArray(NUM_VC_G-1 downto 0);
   signal rxSlaves  : AxiStreamSlaveArray(NUM_VC_G-1 downto 0);

   signal rxMaster : AxiStreamMasterType;
   signal rxSlave  : AxiStreamSlaveType;

   signal drop     : slv(NUM_VC_G-1 downto 0);
   signal trunc    : slv(NUM_VC_G-1 downto 0);

begin

   frameDrop  <= uOr(drop);
   frameTrunc <= uOr(trunc);
   sAxisCtrl  <= intPgpRxCtrl(0);
   
   GEN_MUX : if NUM_VC_G > 1 generate

     GEN_VEC :
     for i in NUM_VC_G-1 downto 0 generate

       --
       --  Should never need to assert RxCtrl
       --    If we do, dump packet and assert eofe
       --
       PGP_FLOW : entity work.AxiStreamFlow
         generic map ( DEBUG_G => ite(LANE_G<1, i<1, false) )
         port map (
           clk         => pgpClk,
           rst         => pgpRst,
           sAxisMaster => pgpRxMasters   (i),
           sAxisCtrl   => pgpRxCtrl      (i),
           mAxisMaster => intPgpRxMasters(i),
           mAxisCtrl   => intPgpRxCtrl   (i),
           ibFull      => dmaIbFull,
           drop        => drop           (i),
           trunc       => trunc          (i) );
       

       PGP_FIFO : entity work.AxiStreamFifoV2
         generic map (
           -- General Configurations
           TPD_G               => TPD_G,
           INT_PIPE_STAGES_G   => 1,
           PIPE_STAGES_G       => 1,
           SLAVE_READY_EN_G    => false,
--           VALID_THOLD_G       => 128,  -- Hold until enough to burst into the interleaving MUX
--           VALID_BURST_MODE_G  => true,
           -- FIFO configurations
           BRAM_EN_G           => true,
           GEN_SYNC_FIFO_G     => true,
           FIFO_ADDR_WIDTH_G   => 10,
           FIFO_FIXED_THRESH_G => true,
           FIFO_PAUSE_THRESH_G => 1020,
           -- AXI Stream Port Configurations
           SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
           MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C)
         port map (
           -- Slave Port
           sAxisClk    => pgpClk,
           sAxisRst    => pgpRst,
           sAxisMaster => intPgpRxMasters(i),
           sAxisCtrl   => intPgpRxCtrl   (i),
           -- Master Port
           mAxisClk    => pgpClk,
           mAxisRst    => pgpRst,
           mAxisMaster => rxMasters(i),
           mAxisSlave  => rxSlaves(i));

     end generate GEN_VEC;

     U_Mux : entity work.AxiStreamMux
       generic map (
         TPD_G                => TPD_G,
         NUM_SLAVES_G         => NUM_VC_G,
         MODE_G               => "ROUTED",
         TDEST_ROUTES_G       => TdestRoutes,
         ILEAVE_EN_G          => true,
         ILEAVE_ON_NOTVALID_G => false,
         ILEAVE_REARB_G       => 128,
         PIPE_STAGES_G        => 1)
       port map (
         -- Clock and reset
         axisClk      => pgpClk,
         axisRst      => pgpRst,
         -- Slaves
         sAxisMasters => rxMasters,
         sAxisSlaves  => rxSlaves,
         -- Master
         mAxisMaster  => rxMaster,
         mAxisSlave   => rxSlave);
     
     ASYNC_FIFO : entity work.AxiStreamFifoV2
       generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C)
       port map (
         -- Slave Port
         sAxisClk    => pgpClk,
         sAxisRst    => pgpRst,
         sAxisMaster => rxMaster,
         sAxisSlave  => rxSlave,
         -- Master Port
         mAxisClk    => dmaClk,
         mAxisRst    => dmaRst,
         mAxisMaster => dmaIbMaster,
         mAxisSlave  => dmaIbSlave);

   end generate;

   GEN_NOMUX : if NUM_VC_G < 2 generate

     PGP_FLOW : entity work.AxiStreamFlow
--       generic map ( DEBUG_G => LANE_G=0 )
       generic map ( DEBUG_G => false )
       port map (
         clk         => pgpClk,
         rst         => pgpRst,
         sAxisMaster => pgpRxMasters   (0),
         sAxisCtrl   => pgpRxCtrl      (0),
         mAxisMaster => intPgpRxMasters(0),
         mAxisCtrl   => intPgpRxCtrl   (0),
         ibFull      => dmaIbFull,
         drop        => drop           (0),
         trunc       => trunc          (0) );

     ASYNC_FIFO : entity work.AxiStreamFifoV2
       generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => false,
--         VALID_THOLD_G       => 128,  -- Hold until enough to burst into the interleaving MUX
--         VALID_BURST_MODE_G  => true,
         -- FIFO configurations
         BRAM_EN_G           => true,
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 10,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 1020,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C)
       port map (
         -- Slave Port
         sAxisClk    => pgpClk,
         sAxisRst    => pgpRst,
         sAxisMaster => intPgpRxMasters(0),
         sAxisCtrl   => intPgpRxCtrl   (0),
         -- Master Port
         mAxisClk    => dmaClk,
         mAxisRst    => dmaRst,
         mAxisMaster => dmaIbMaster,
         mAxisSlave  => dmaIbSlave);
   end generate;
   
end mapping;
