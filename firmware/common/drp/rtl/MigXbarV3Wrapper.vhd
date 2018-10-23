-------------------------------------------------------------------------------
-- File       : MigXbar.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-08-02
-- Last update: 2018-02-26
-------------------------------------------------------------------------------
-- Description: V2Wrapper for the "store-and-forward" AXI FIFO
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

use work.StdRtlPkg.all;
use work.AxiPkg.all;

entity MigXbarV3Wrapper is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Slave Interfaces
      sAxiClk          : in  sl;
      sAxiRst          : in  sl;
      sAxiWriteMasters : in  AxiWriteMasterArray(3 downto 0);
      sAxiWriteSlaves  : out AxiWriteSlaveArray (3 downto 0);
      sAxiReadMasters  : in  AxiReadMasterArray (3 downto 0);
      sAxiReadSlaves   : out AxiReadSlaveArray  (3 downto 0);
      -- Master Interface
      mAxiClk          : in  sl;
      mAxiRst          : out sl;
      mAxiWriteMaster  : out AxiWriteMasterType;
      mAxiWriteSlave   : in  AxiWriteSlaveType;
      mAxiReadMaster   : out AxiReadMasterType;
      mAxiReadSlave    : in  AxiReadSlaveType);
end MigXbarV3Wrapper;

architecture mapping of MigXbarV3Wrapper is

   component MigXbarV3
      port (
         INTERCONNECT_ACLK    : in  std_logic;
         INTERCONNECT_ARESETN : in  std_logic;
         S00_AXI_ARESET_OUT_N : out std_logic;
         S00_AXI_ACLK         : in  std_logic;
         S00_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S00_AXI_AWADDR       : in  std_logic_vector(31 downto 0);
         S00_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S00_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S00_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S00_AXI_AWLOCK       : in  std_logic;
         S00_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S00_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S00_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S00_AXI_AWVALID      : in  std_logic;
         S00_AXI_AWREADY      : out std_logic;
         S00_AXI_WDATA        : in  std_logic_vector(127 downto 0);
         S00_AXI_WSTRB        : in  std_logic_vector( 15 downto 0);
         S00_AXI_WLAST        : in  std_logic;
         S00_AXI_WVALID       : in  std_logic;
         S00_AXI_WREADY       : out std_logic;
         S00_AXI_BID          : out std_logic_vector(0 downto 0);
         S00_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S00_AXI_BVALID       : out std_logic;
         S00_AXI_BREADY       : in  std_logic;
         S00_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S00_AXI_ARADDR       : in  std_logic_vector(31 downto 0);
         S00_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S00_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S00_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S00_AXI_ARLOCK       : in  std_logic;
         S00_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S00_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S00_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S00_AXI_ARVALID      : in  std_logic;
         S00_AXI_ARREADY      : out std_logic;
         S00_AXI_RID          : out std_logic_vector(0 downto 0);
         S00_AXI_RDATA        : out std_logic_vector(127 downto 0);
         S00_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S00_AXI_RLAST        : out std_logic;
         S00_AXI_RVALID       : out std_logic;
         S00_AXI_RREADY       : in  std_logic;
         S01_AXI_ARESET_OUT_N : out std_logic;
         S01_AXI_ACLK         : in  std_logic;
         S01_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S01_AXI_AWADDR       : in  std_logic_vector(31 downto 0);
         S01_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S01_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S01_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S01_AXI_AWLOCK       : in  std_logic;
         S01_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S01_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S01_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S01_AXI_AWVALID      : in  std_logic;
         S01_AXI_AWREADY      : out std_logic;
         S01_AXI_WDATA        : in  std_logic_vector(127 downto 0);
         S01_AXI_WSTRB        : in  std_logic_vector( 15 downto 0);
         S01_AXI_WLAST        : in  std_logic;
         S01_AXI_WVALID       : in  std_logic;
         S01_AXI_WREADY       : out std_logic;
         S01_AXI_BID          : out std_logic_vector(0 downto 0);
         S01_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S01_AXI_BVALID       : out std_logic;
         S01_AXI_BREADY       : in  std_logic;
         S01_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S01_AXI_ARADDR       : in  std_logic_vector(31 downto 0);
         S01_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S01_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S01_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S01_AXI_ARLOCK       : in  std_logic;
         S01_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S01_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S01_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S01_AXI_ARVALID      : in  std_logic;
         S01_AXI_ARREADY      : out std_logic;
         S01_AXI_RID          : out std_logic_vector(0 downto 0);
         S01_AXI_RDATA        : out std_logic_vector(127 downto 0);
         S01_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S01_AXI_RLAST        : out std_logic;
         S01_AXI_RVALID       : out std_logic;
         S01_AXI_RREADY       : in  std_logic;
         S02_AXI_ARESET_OUT_N : out std_logic;
         S02_AXI_ACLK         : in  std_logic;
         S02_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S02_AXI_AWADDR       : in  std_logic_vector(31 downto 0);
         S02_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S02_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S02_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S02_AXI_AWLOCK       : in  std_logic;
         S02_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S02_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S02_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S02_AXI_AWVALID      : in  std_logic;
         S02_AXI_AWREADY      : out std_logic;
         S02_AXI_WDATA        : in  std_logic_vector(127 downto 0);
         S02_AXI_WSTRB        : in  std_logic_vector( 15 downto 0);
         S02_AXI_WLAST        : in  std_logic;
         S02_AXI_WVALID       : in  std_logic;
         S02_AXI_WREADY       : out std_logic;
         S02_AXI_BID          : out std_logic_vector(0 downto 0);
         S02_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S02_AXI_BVALID       : out std_logic;
         S02_AXI_BREADY       : in  std_logic;
         S02_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S02_AXI_ARADDR       : in  std_logic_vector(31 downto 0);
         S02_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S02_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S02_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S02_AXI_ARLOCK       : in  std_logic;
         S02_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S02_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S02_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S02_AXI_ARVALID      : in  std_logic;
         S02_AXI_ARREADY      : out std_logic;
         S02_AXI_RID          : out std_logic_vector(0 downto 0);
         S02_AXI_RDATA        : out std_logic_vector(127 downto 0);
         S02_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S02_AXI_RLAST        : out std_logic;
         S02_AXI_RVALID       : out std_logic;
         S02_AXI_RREADY       : in  std_logic;
         S03_AXI_ARESET_OUT_N : out std_logic;
         S03_AXI_ACLK         : in  std_logic;
         S03_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S03_AXI_AWADDR       : in  std_logic_vector(31 downto 0);
         S03_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S03_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S03_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S03_AXI_AWLOCK       : in  std_logic;
         S03_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S03_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S03_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S03_AXI_AWVALID      : in  std_logic;
         S03_AXI_AWREADY      : out std_logic;
         S03_AXI_WDATA        : in  std_logic_vector(127 downto 0);
         S03_AXI_WSTRB        : in  std_logic_vector( 15 downto 0);
         S03_AXI_WLAST        : in  std_logic;
         S03_AXI_WVALID       : in  std_logic;
         S03_AXI_WREADY       : out std_logic;
         S03_AXI_BID          : out std_logic_vector(0 downto 0);
         S03_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S03_AXI_BVALID       : out std_logic;
         S03_AXI_BREADY       : in  std_logic;
         S03_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S03_AXI_ARADDR       : in  std_logic_vector(31 downto 0);
         S03_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S03_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S03_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S03_AXI_ARLOCK       : in  std_logic;
         S03_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S03_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S03_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S03_AXI_ARVALID      : in  std_logic;
         S03_AXI_ARREADY      : out std_logic;
         S03_AXI_RID          : out std_logic_vector(0 downto 0);
         S03_AXI_RDATA        : out std_logic_vector(127 downto 0);
         S03_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S03_AXI_RLAST        : out std_logic;
         S03_AXI_RVALID       : out std_logic;
         S03_AXI_RREADY       : in  std_logic;
         M00_AXI_ARESET_OUT_N : out std_logic;
         M00_AXI_ACLK         : in  std_logic;
         M00_AXI_AWID         : out std_logic_vector(3 downto 0);
         M00_AXI_AWADDR       : out std_logic_vector(31 downto 0);
         M00_AXI_AWLEN        : out std_logic_vector(7 downto 0);
         M00_AXI_AWSIZE       : out std_logic_vector(2 downto 0);
         M00_AXI_AWBURST      : out std_logic_vector(1 downto 0);
         M00_AXI_AWLOCK       : out std_logic;
         M00_AXI_AWCACHE      : out std_logic_vector(3 downto 0);
         M00_AXI_AWPROT       : out std_logic_vector(2 downto 0);
         M00_AXI_AWQOS        : out std_logic_vector(3 downto 0);
         M00_AXI_AWVALID      : out std_logic;
         M00_AXI_AWREADY      : in  std_logic;
         M00_AXI_WDATA        : out std_logic_vector(511 downto 0);
         M00_AXI_WSTRB        : out std_logic_vector(63 downto 0);
         M00_AXI_WLAST        : out std_logic;
         M00_AXI_WVALID       : out std_logic;
         M00_AXI_WREADY       : in  std_logic;
         M00_AXI_BID          : in  std_logic_vector(3 downto 0);
         M00_AXI_BRESP        : in  std_logic_vector(1 downto 0);
         M00_AXI_BVALID       : in  std_logic;
         M00_AXI_BREADY       : out std_logic;
         M00_AXI_ARID         : out std_logic_vector(3 downto 0);
         M00_AXI_ARADDR       : out std_logic_vector(31 downto 0);
         M00_AXI_ARLEN        : out std_logic_vector(7 downto 0);
         M00_AXI_ARSIZE       : out std_logic_vector(2 downto 0);
         M00_AXI_ARBURST      : out std_logic_vector(1 downto 0);
         M00_AXI_ARLOCK       : out std_logic;
         M00_AXI_ARCACHE      : out std_logic_vector(3 downto 0);
         M00_AXI_ARPROT       : out std_logic_vector(2 downto 0);
         M00_AXI_ARQOS        : out std_logic_vector(3 downto 0);
         M00_AXI_ARVALID      : out std_logic;
         M00_AXI_ARREADY      : in  std_logic;
         M00_AXI_RID          : in  std_logic_vector(3 downto 0);
         M00_AXI_RDATA        : in  std_logic_vector(511 downto 0);
         M00_AXI_RRESP        : in  std_logic_vector(1 downto 0);
         M00_AXI_RLAST        : in  std_logic;
         M00_AXI_RVALID       : in  std_logic;
         M00_AXI_RREADY       : out std_logic
         );
   end component;

   signal axiClk       : sl;
   signal axiRstL      : sl;
   signal imAxiRst     : sl;
   signal mAxiRstL     : sl;
   signal mAxiRstLSync : sl;
   signal imAxiWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal imAxiWriteSlave  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal imAxiReadMaster  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
   signal imAxiReadSlave   : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;
   signal isAxiWriteSlaves : AxiWriteSlaveArray(3 downto 0) := (others=>AXI_WRITE_SLAVE_INIT_C);
   signal isAxiReadSlaves  : AxiReadSlaveArray (3 downto 0) := (others=>AXI_READ_SLAVE_INIT_C);
   constant AXI_CONFIG_C : AxiConfigType := axiConfig(32,64,4,8);
begin

   axiClk          <= sAxiClk;
   axiRstL         <= not sAxiRst;
   mAxiRst         <= imAxiRst;
   imAxiRst        <= not mAxiRstL;
   sAxiWriteSlaves <= isAxiWriteSlaves;
   sAxiReadSlaves  <= isAxiReadSlaves;

   U_ReadFifo : entity work.AxiReadPathFifo
     generic map ( AXI_CONFIG_G => AXI_CONFIG_C )
     port map ( sAxiClk         => sAxiClk,
                sAxiRst         => sAxiRst,
                sAxiReadMaster  => imAxiReadMaster,
                sAxiReadSlave   => imAxiReadSlave,
                mAxiClk         => mAxiClk,
                mAxiRst         => imAxiRst,
                mAxiReadMaster  => mAxiReadMaster,
                mAxiReadSlave   => mAxiReadSlave );
   
   U_WriteFifo : entity work.AxiWritePathFifo
     generic map ( AXI_CONFIG_G => AXI_CONFIG_C )
     port map ( sAxiClk         => sAxiClk,
                sAxiRst         => sAxiRst,
                sAxiWriteMaster => imAxiWriteMaster,
                sAxiWriteSlave  => imAxiWriteSlave,
                mAxiClk         => mAxiClk,
                mAxiRst         => imAxiRst,
                mAxiWriteMaster => mAxiWriteMaster,
                mAxiWriteSlave  => mAxiWriteSlave );

   --GEN_WRITE : for i in 0 to 1 generate
   --  U_WriteFifo : entity work.AxiWritePathFifo
   --    generic map ( AXI_CONFIG_G => AXI_CONFIG_C )
   --    port map ( sAxiClk         => sAxiClk,
   --               sAxiRst         => sAxiRst,
   --               sAxiWriteMaster => imAxiWriteMaster,
   --               sAxiWriteSlave  => imAxiWriteSlave,
   --               mAxiClk         => sAxiClk,
   --               mAxiRst         => sAxiRst,
   --               mAxiWriteMaster => mAxiWriteMaster,
   --               mAxiWriteSlave  => mAxiWriteSlave );
   --end generate;
   
   U_Sync : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axiClk,
         dataIn  => mAxiRstL,
         dataOut => mAxiRstLSync);

   U_XBAR : MigXbarV3
      port map (
         INTERCONNECT_ACLK    => axiClk,
         INTERCONNECT_ARESETN => axiRstL,
         -- SLAVE[0]
         S00_AXI_ARESET_OUT_N => open,
         S00_AXI_ACLK         => axiClk,
         S00_AXI_AWID(0)      => '0',
         S00_AXI_AWADDR       => sAxiWriteMasters(0).awaddr(31 downto 0),
         S00_AXI_AWLEN        => sAxiWriteMasters(0).awlen,
         S00_AXI_AWSIZE       => sAxiWriteMasters(0).awsize,
         S00_AXI_AWBURST      => sAxiWriteMasters(0).awburst,
         S00_AXI_AWLOCK       => sAxiWriteMasters(0).awlock(0),
         S00_AXI_AWCACHE      => sAxiWriteMasters(0).awcache,
         S00_AXI_AWPROT       => sAxiWriteMasters(0).awprot,
         S00_AXI_AWQOS        => sAxiWriteMasters(0).awqos,
         S00_AXI_AWVALID      => sAxiWriteMasters(0).awvalid,
         S00_AXI_AWREADY      => isAxiWriteSlaves(0).awready,
         S00_AXI_WDATA        => sAxiWriteMasters(0).wdata(127 downto 0),
         S00_AXI_WSTRB        => sAxiWriteMasters(0).wstrb( 15 downto 0),
         S00_AXI_WLAST        => sAxiWriteMasters(0).wlast,
         S00_AXI_WVALID       => sAxiWriteMasters(0).wvalid,
         S00_AXI_WREADY       => isAxiWriteSlaves(0).wready,
         S00_AXI_BID          => isAxiWriteSlaves(0).bid(0 downto 0),
         S00_AXI_BRESP        => isAxiWriteSlaves(0).bresp,
         S00_AXI_BVALID       => isAxiWriteSlaves(0).bvalid,
         S00_AXI_BREADY       => sAxiWriteMasters(0).bready,
         S00_AXI_ARID(0)      => '0',
         S00_AXI_ARADDR       => sAxiReadMasters(0).araddr(31 downto 0),
         S00_AXI_ARLEN        => sAxiReadMasters(0).arlen,
         S00_AXI_ARSIZE       => sAxiReadMasters(0).arsize,
         S00_AXI_ARBURST      => sAxiReadMasters(0).arburst,
         S00_AXI_ARLOCK       => sAxiReadMasters(0).arlock(0),
         S00_AXI_ARCACHE      => sAxiReadMasters(0).arcache,
         S00_AXI_ARPROT       => sAxiReadMasters(0).arprot,
         S00_AXI_ARQOS        => sAxiReadMasters(0).arqos,
         S00_AXI_ARVALID      => sAxiReadMasters(0).arvalid,
         S00_AXI_ARREADY      => isAxiReadSlaves(0).arready,
         S00_AXI_RID          => isAxiReadSlaves(0).rid(0 downto 0),
         S00_AXI_RDATA        => isAxiReadSlaves(0).rdata(127 downto 0),
         S00_AXI_RRESP        => isAxiReadSlaves(0).rresp,
         S00_AXI_RLAST        => isAxiReadSlaves(0).rlast,
         S00_AXI_RVALID       => isAxiReadSlaves(0).rvalid,
         S00_AXI_RREADY       => sAxiReadMasters(0).rready,
         -- SLAVE[1]
         S01_AXI_ARESET_OUT_N => open,
         S01_AXI_ACLK         => axiClk,
         S01_AXI_AWID(0)      => '0',
         S01_AXI_AWADDR       => sAxiWriteMasters(1).awaddr(31 downto 0),
         S01_AXI_AWLEN        => sAxiWriteMasters(1).awlen,
         S01_AXI_AWSIZE       => sAxiWriteMasters(1).awsize,
         S01_AXI_AWBURST      => sAxiWriteMasters(1).awburst,
         S01_AXI_AWLOCK       => sAxiWriteMasters(1).awlock(0),
         S01_AXI_AWCACHE      => sAxiWriteMasters(1).awcache,
         S01_AXI_AWPROT       => sAxiWriteMasters(1).awprot,
         S01_AXI_AWQOS        => sAxiWriteMasters(1).awqos,
         S01_AXI_AWVALID      => sAxiWriteMasters(1).awvalid,
         S01_AXI_AWREADY      => isAxiWriteSlaves(1).awready,
         S01_AXI_WDATA        => sAxiWriteMasters(1).wdata(127 downto 0),
         S01_AXI_WSTRB        => sAxiWriteMasters(1).wstrb( 15 downto 0),
         S01_AXI_WLAST        => sAxiWriteMasters(1).wlast,
         S01_AXI_WVALID       => sAxiWriteMasters(1).wvalid,
         S01_AXI_WREADY       => isAxiWriteSlaves(1).wready,
         S01_AXI_BID          => isAxiWriteSlaves(1).bid(0 downto 0),
         S01_AXI_BRESP        => isAxiWriteSlaves(1).bresp,
         S01_AXI_BVALID       => isAxiWriteSlaves(1).bvalid,
         S01_AXI_BREADY       => sAxiWriteMasters(1).bready,
         S01_AXI_ARID(0)      => '0',
         S01_AXI_ARADDR       => sAxiReadMasters(1).araddr(31 downto 0),
         S01_AXI_ARLEN        => sAxiReadMasters(1).arlen,
         S01_AXI_ARSIZE       => sAxiReadMasters(1).arsize,
         S01_AXI_ARBURST      => sAxiReadMasters(1).arburst,
         S01_AXI_ARLOCK       => sAxiReadMasters(1).arlock(0),
         S01_AXI_ARCACHE      => sAxiReadMasters(1).arcache,
         S01_AXI_ARPROT       => sAxiReadMasters(1).arprot,
         S01_AXI_ARQOS        => sAxiReadMasters(1).arqos,
         S01_AXI_ARVALID      => sAxiReadMasters(1).arvalid,
         S01_AXI_ARREADY      => isAxiReadSlaves(1).arready,
         S01_AXI_RID          => isAxiReadSlaves(1).rid(0 downto 0),
         S01_AXI_RDATA        => isAxiReadSlaves(1).rdata(127 downto 0),
         S01_AXI_RRESP        => isAxiReadSlaves(1).rresp,
         S01_AXI_RLAST        => isAxiReadSlaves(1).rlast,
         S01_AXI_RVALID       => isAxiReadSlaves(1).rvalid,
         S01_AXI_RREADY       => sAxiReadMasters(1).rready,
         -- SLAVE[2]
         S02_AXI_ARESET_OUT_N => open,
         S02_AXI_ACLK         => axiClk,
         S02_AXI_AWID(0)      => '0',
         S02_AXI_AWADDR       => sAxiWriteMasters(2).awaddr(31 downto 0),
         S02_AXI_AWLEN        => sAxiWriteMasters(2).awlen,
         S02_AXI_AWSIZE       => sAxiWriteMasters(2).awsize,
         S02_AXI_AWBURST      => sAxiWriteMasters(2).awburst,
         S02_AXI_AWLOCK       => sAxiWriteMasters(2).awlock(0),
         S02_AXI_AWCACHE      => sAxiWriteMasters(2).awcache,
         S02_AXI_AWPROT       => sAxiWriteMasters(2).awprot,
         S02_AXI_AWQOS        => sAxiWriteMasters(2).awqos,
         S02_AXI_AWVALID      => sAxiWriteMasters(2).awvalid,
         S02_AXI_AWREADY      => isAxiWriteSlaves(2).awready,
         S02_AXI_WDATA        => sAxiWriteMasters(2).wdata(127 downto 0),
         S02_AXI_WSTRB        => sAxiWriteMasters(2).wstrb( 15 downto 0),
         S02_AXI_WLAST        => sAxiWriteMasters(2).wlast,
         S02_AXI_WVALID       => sAxiWriteMasters(2).wvalid,
         S02_AXI_WREADY       => isAxiWriteSlaves(2).wready,
         S02_AXI_BID          => isAxiWriteSlaves(2).bid(0 downto 0),
         S02_AXI_BRESP        => isAxiWriteSlaves(2).bresp,
         S02_AXI_BVALID       => isAxiWriteSlaves(2).bvalid,
         S02_AXI_BREADY       => sAxiWriteMasters(2).bready,
         S02_AXI_ARID(0)      => '0',
         S02_AXI_ARADDR       => sAxiReadMasters(2).araddr(31 downto 0),
         S02_AXI_ARLEN        => sAxiReadMasters(2).arlen,
         S02_AXI_ARSIZE       => sAxiReadMasters(2).arsize,
         S02_AXI_ARBURST      => sAxiReadMasters(2).arburst,
         S02_AXI_ARLOCK       => sAxiReadMasters(2).arlock(0),
         S02_AXI_ARCACHE      => sAxiReadMasters(2).arcache,
         S02_AXI_ARPROT       => sAxiReadMasters(2).arprot,
         S02_AXI_ARQOS        => sAxiReadMasters(2).arqos,
         S02_AXI_ARVALID      => sAxiReadMasters(2).arvalid,
         S02_AXI_ARREADY      => isAxiReadSlaves(2).arready,
         S02_AXI_RID          => isAxiReadSlaves(2).rid(0 downto 0),
         S02_AXI_RDATA        => isAxiReadSlaves(2).rdata(127 downto 0),
         S02_AXI_RRESP        => isAxiReadSlaves(2).rresp,
         S02_AXI_RLAST        => isAxiReadSlaves(2).rlast,
         S02_AXI_RVALID       => isAxiReadSlaves(2).rvalid,
         S02_AXI_RREADY       => sAxiReadMasters(2).rready,
         -- SLAVE[3]
         S03_AXI_ARESET_OUT_N => open,
         S03_AXI_ACLK         => axiClk,
         S03_AXI_AWID(0)      => '0',
         S03_AXI_AWADDR       => sAxiWriteMasters(3).awaddr(31 downto 0),
         S03_AXI_AWLEN        => sAxiWriteMasters(3).awlen,
         S03_AXI_AWSIZE       => sAxiWriteMasters(3).awsize,
         S03_AXI_AWBURST      => sAxiWriteMasters(3).awburst,
         S03_AXI_AWLOCK       => sAxiWriteMasters(3).awlock(0),
         S03_AXI_AWCACHE      => sAxiWriteMasters(3).awcache,
         S03_AXI_AWPROT       => sAxiWriteMasters(3).awprot,
         S03_AXI_AWQOS        => sAxiWriteMasters(3).awqos,
         S03_AXI_AWVALID      => sAxiWriteMasters(3).awvalid,
         S03_AXI_AWREADY      => isAxiWriteSlaves(3).awready,
         S03_AXI_WDATA        => sAxiWriteMasters(3).wdata(127 downto 0),
         S03_AXI_WSTRB        => sAxiWriteMasters(3).wstrb( 15 downto 0),
         S03_AXI_WLAST        => sAxiWriteMasters(3).wlast,
         S03_AXI_WVALID       => sAxiWriteMasters(3).wvalid,
         S03_AXI_WREADY       => isAxiWriteSlaves(3).wready,
         S03_AXI_BID          => isAxiWriteSlaves(3).bid(0 downto 0),
         S03_AXI_BRESP        => isAxiWriteSlaves(3).bresp,
         S03_AXI_BVALID       => isAxiWriteSlaves(3).bvalid,
         S03_AXI_BREADY       => sAxiWriteMasters(3).bready,
         S03_AXI_ARID(0)      => '0',
         S03_AXI_ARADDR       => sAxiReadMasters(3).araddr(31 downto 0),
         S03_AXI_ARLEN        => sAxiReadMasters(3).arlen,
         S03_AXI_ARSIZE       => sAxiReadMasters(3).arsize,
         S03_AXI_ARBURST      => sAxiReadMasters(3).arburst,
         S03_AXI_ARLOCK       => sAxiReadMasters(3).arlock(0),
         S03_AXI_ARCACHE      => sAxiReadMasters(3).arcache,
         S03_AXI_ARPROT       => sAxiReadMasters(3).arprot,
         S03_AXI_ARQOS        => sAxiReadMasters(3).arqos,
         S03_AXI_ARVALID      => sAxiReadMasters(3).arvalid,
         S03_AXI_ARREADY      => isAxiReadSlaves(3).arready,
         S03_AXI_RID          => isAxiReadSlaves(3).rid(0 downto 0),
         S03_AXI_RDATA        => isAxiReadSlaves(3).rdata(127 downto 0),
         S03_AXI_RRESP        => isAxiReadSlaves(3).rresp,
         S03_AXI_RLAST        => isAxiReadSlaves(3).rlast,
         S03_AXI_RVALID       => isAxiReadSlaves(3).rvalid,
         S03_AXI_RREADY       => sAxiReadMasters(3).rready,
         -- MASTER         
         M00_AXI_ARESET_OUT_N => mAxiRstL,
         M00_AXI_ACLK         => axiClk,
         M00_AXI_AWID         => imAxiWriteMaster.awid(3 downto 0),
         M00_AXI_AWADDR       => imAxiWriteMaster.awaddr(31 downto 0),
         M00_AXI_AWLEN        => imAxiWriteMaster.awlen,
         M00_AXI_AWSIZE       => imAxiWriteMaster.awsize,
         M00_AXI_AWBURST      => imAxiWriteMaster.awburst,
         M00_AXI_AWLOCK       => imAxiWriteMaster.awlock(0),
         M00_AXI_AWCACHE      => imAxiWriteMaster.awcache,
         M00_AXI_AWPROT       => imAxiWriteMaster.awprot,
         M00_AXI_AWQOS        => imAxiWriteMaster.awqos,
         M00_AXI_AWVALID      => imAxiWriteMaster.awvalid,
         M00_AXI_AWREADY      => imAxiWriteSlave.awready,
         M00_AXI_WDATA        => imAxiWriteMaster.wdata(511 downto 0),
         M00_AXI_WSTRB        => imAxiWriteMaster.wstrb(63 downto 0),
         M00_AXI_WLAST        => imAxiWriteMaster.wlast,
         M00_AXI_WVALID       => imAxiWriteMaster.wvalid,
         M00_AXI_WREADY       => imAxiWriteSlave.wready,
         M00_AXI_BID          => imAxiWriteSlave.bid(3 downto 0),
         M00_AXI_BRESP        => imAxiWriteSlave.bresp,
         M00_AXI_BVALID       => imAxiWriteSlave.bvalid,
         M00_AXI_BREADY       => imAxiWriteMaster.bready,
         M00_AXI_ARID         => imAxiReadMaster.arid(3 downto 0),
         M00_AXI_ARADDR       => imAxiReadMaster.araddr(31 downto 0),
         M00_AXI_ARLEN        => imAxiReadMaster.arlen,
         M00_AXI_ARSIZE       => imAxiReadMaster.arsize,
         M00_AXI_ARBURST      => imAxiReadMaster.arburst,
         M00_AXI_ARLOCK       => imAxiReadMaster.arlock(0),
         M00_AXI_ARCACHE      => imAxiReadMaster.arcache,
         M00_AXI_ARPROT       => imAxiReadMaster.arprot,
         M00_AXI_ARQOS        => imAxiReadMaster.arqos,
         M00_AXI_ARVALID      => imAxiReadMaster.arvalid,
         M00_AXI_ARREADY      => imAxiReadSlave.arready,
         M00_AXI_RID          => imAxiReadSlave.rid(3 downto 0),
         M00_AXI_RDATA        => imAxiReadSlave.rdata(511 downto 0),
         M00_AXI_RRESP        => imAxiReadSlave.rresp,
         M00_AXI_RLAST        => imAxiReadSlave.rlast,
         M00_AXI_RVALID       => imAxiReadSlave.rvalid,
         M00_AXI_RREADY       => imAxiReadMaster.rready);

end mapping;
