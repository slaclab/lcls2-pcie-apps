-------------------------------------------------------------------------------
-- File       : PcieXbarWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-14
-- Last update: 2018-02-20
-------------------------------------------------------------------------------
-- Description: AXI DMA Crossbar
-------------------------------------------------------------------------------
-- This file is part of 'AxiPcieCore'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'AxiPcieCore', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;

entity PcieXbarWrapper is
   port (
      -- Slaves
      sAxiClk          : in  sl; -- 200MHz
      sAxiRst          : in  sl;
      sAxiWriteMasters : in  AxiWriteMasterArray(5 downto 0);
      sAxiWriteSlaves  : out AxiWriteSlaveArray (5 downto 0);
--      sAxiReadMasters  : in  AxiReadMasterArray (4 downto 0); -- Write Only
--      sAxiReadSlaves   : out AxiReadSlaveArray  (4 downto 0);
      -- Master
      mAxiClk          : in  sl; -- 250MHz
      mAxiRst          : in  sl;
      mAxiWriteMaster  : out AxiWriteMasterType;
      mAxiWriteSlave   : in  AxiWriteSlaveType;
      mAxiReadMaster   : out AxiReadMasterType;
      mAxiReadSlave    : in  AxiReadSlaveType );
end PcieXbarWrapper;

architecture mapping of PcieXbarWrapper is

  component PcieXbar
    PORT (
      INTERCONNECT_ACLK : IN STD_LOGIC;
      INTERCONNECT_ARESETN : IN STD_LOGIC;
      S00_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S00_AXI_ACLK : IN STD_LOGIC;
      S00_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S00_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S00_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S00_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S00_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S00_AXI_AWLOCK : IN STD_LOGIC;
      S00_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S00_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S00_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S00_AXI_AWVALID : IN STD_LOGIC;
      S00_AXI_AWREADY : OUT STD_LOGIC;
      S00_AXI_WDATA : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      S00_AXI_WSTRB : IN STD_LOGIC_VECTOR( 7 DOWNTO 0);
      S00_AXI_WLAST : IN STD_LOGIC;
      S00_AXI_WVALID : IN STD_LOGIC;
      S00_AXI_WREADY : OUT STD_LOGIC;
      S00_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S00_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S00_AXI_BVALID : OUT STD_LOGIC;
      S00_AXI_BREADY : IN STD_LOGIC;
      S00_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S00_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S00_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S00_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S00_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S00_AXI_ARLOCK : IN STD_LOGIC;
      S00_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S00_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S00_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S00_AXI_ARVALID : IN STD_LOGIC;
      S00_AXI_ARREADY : OUT STD_LOGIC;
      S00_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S00_AXI_RDATA : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      S00_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S00_AXI_RLAST : OUT STD_LOGIC;
      S00_AXI_RVALID : OUT STD_LOGIC;
      S00_AXI_RREADY : IN STD_LOGIC;
      S01_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S01_AXI_ACLK : IN STD_LOGIC;
      S01_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S01_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S01_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S01_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S01_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S01_AXI_AWLOCK : IN STD_LOGIC;
      S01_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S01_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S01_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S01_AXI_AWVALID : IN STD_LOGIC;
      S01_AXI_AWREADY : OUT STD_LOGIC;
      S01_AXI_WDATA : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      S01_AXI_WSTRB : IN STD_LOGIC_VECTOR( 7 DOWNTO 0);
      S01_AXI_WLAST : IN STD_LOGIC;
      S01_AXI_WVALID : IN STD_LOGIC;
      S01_AXI_WREADY : OUT STD_LOGIC;
      S01_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S01_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S01_AXI_BVALID : OUT STD_LOGIC;
      S01_AXI_BREADY : IN STD_LOGIC;
      S01_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S01_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S01_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S01_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S01_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S01_AXI_ARLOCK : IN STD_LOGIC;
      S01_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S01_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S01_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S01_AXI_ARVALID : IN STD_LOGIC;
      S01_AXI_ARREADY : OUT STD_LOGIC;
      S01_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S01_AXI_RDATA : OUT STD_LOGIC_VECTOR( 63 DOWNTO 0);
      S01_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S01_AXI_RLAST : OUT STD_LOGIC;
      S01_AXI_RVALID : OUT STD_LOGIC;
      S01_AXI_RREADY : IN STD_LOGIC;
      S02_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S02_AXI_ACLK : IN STD_LOGIC;
      S02_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S02_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S02_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S02_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S02_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S02_AXI_AWLOCK : IN STD_LOGIC;
      S02_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S02_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S02_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S02_AXI_AWVALID : IN STD_LOGIC;
      S02_AXI_AWREADY : OUT STD_LOGIC;
      S02_AXI_WDATA : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      S02_AXI_WSTRB : IN STD_LOGIC_VECTOR( 7 DOWNTO 0);
      S02_AXI_WLAST : IN STD_LOGIC;
      S02_AXI_WVALID : IN STD_LOGIC;
      S02_AXI_WREADY : OUT STD_LOGIC;
      S02_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S02_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S02_AXI_BVALID : OUT STD_LOGIC;
      S02_AXI_BREADY : IN STD_LOGIC;
      S02_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S02_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S02_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S02_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S02_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S02_AXI_ARLOCK : IN STD_LOGIC;
      S02_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S02_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S02_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S02_AXI_ARVALID : IN STD_LOGIC;
      S02_AXI_ARREADY : OUT STD_LOGIC;
      S02_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S02_AXI_RDATA : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      S02_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S02_AXI_RLAST : OUT STD_LOGIC;
      S02_AXI_RVALID : OUT STD_LOGIC;
      S02_AXI_RREADY : IN STD_LOGIC;
      S03_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S03_AXI_ACLK : IN STD_LOGIC;
      S03_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S03_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S03_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S03_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S03_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S03_AXI_AWLOCK : IN STD_LOGIC;
      S03_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S03_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S03_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S03_AXI_AWVALID : IN STD_LOGIC;
      S03_AXI_AWREADY : OUT STD_LOGIC;
      S03_AXI_WDATA : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      S03_AXI_WSTRB : IN STD_LOGIC_VECTOR( 7 DOWNTO 0);
      S03_AXI_WLAST : IN STD_LOGIC;
      S03_AXI_WVALID : IN STD_LOGIC;
      S03_AXI_WREADY : OUT STD_LOGIC;
      S03_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S03_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S03_AXI_BVALID : OUT STD_LOGIC;
      S03_AXI_BREADY : IN STD_LOGIC;
      S03_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S03_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S03_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S03_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S03_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S03_AXI_ARLOCK : IN STD_LOGIC;
      S03_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S03_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S03_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S03_AXI_ARVALID : IN STD_LOGIC;
      S03_AXI_ARREADY : OUT STD_LOGIC;
      S03_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S03_AXI_RDATA : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      S03_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S03_AXI_RLAST : OUT STD_LOGIC;
      S03_AXI_RVALID : OUT STD_LOGIC;
      S03_AXI_RREADY : IN STD_LOGIC;
      S04_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S04_AXI_ACLK : IN STD_LOGIC;
      S04_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S04_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S04_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S04_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S04_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S04_AXI_AWLOCK : IN STD_LOGIC;
      S04_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S04_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S04_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S04_AXI_AWVALID : IN STD_LOGIC;
      S04_AXI_AWREADY : OUT STD_LOGIC;
      S04_AXI_WDATA : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      S04_AXI_WSTRB : IN STD_LOGIC_VECTOR( 7 DOWNTO 0);
      S04_AXI_WLAST : IN STD_LOGIC;
      S04_AXI_WVALID : IN STD_LOGIC;
      S04_AXI_WREADY : OUT STD_LOGIC;
      S04_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S04_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S04_AXI_BVALID : OUT STD_LOGIC;
      S04_AXI_BREADY : IN STD_LOGIC;
      S04_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S04_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S04_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S04_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S04_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S04_AXI_ARLOCK : IN STD_LOGIC;
      S04_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S04_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S04_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S04_AXI_ARVALID : IN STD_LOGIC;
      S04_AXI_ARREADY : OUT STD_LOGIC;
      S04_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S04_AXI_RDATA : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      S04_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S04_AXI_RLAST : OUT STD_LOGIC;
      S04_AXI_RVALID : OUT STD_LOGIC;
      S04_AXI_RREADY : IN STD_LOGIC;
      S05_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S05_AXI_ACLK : IN STD_LOGIC;
      S05_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S05_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S05_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S05_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S05_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S05_AXI_AWLOCK : IN STD_LOGIC;
      S05_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S05_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S05_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S05_AXI_AWVALID : IN STD_LOGIC;
      S05_AXI_AWREADY : OUT STD_LOGIC;
      S05_AXI_WDATA : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      S05_AXI_WSTRB : IN STD_LOGIC_VECTOR( 7 DOWNTO 0);
      S05_AXI_WLAST : IN STD_LOGIC;
      S05_AXI_WVALID : IN STD_LOGIC;
      S05_AXI_WREADY : OUT STD_LOGIC;
      S05_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S05_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S05_AXI_BVALID : OUT STD_LOGIC;
      S05_AXI_BREADY : IN STD_LOGIC;
      S05_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S05_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S05_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S05_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S05_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S05_AXI_ARLOCK : IN STD_LOGIC;
      S05_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S05_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S05_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S05_AXI_ARVALID : IN STD_LOGIC;
      S05_AXI_ARREADY : OUT STD_LOGIC;
      S05_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S05_AXI_RDATA : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      S05_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S05_AXI_RLAST : OUT STD_LOGIC;
      S05_AXI_RVALID : OUT STD_LOGIC;
      S05_AXI_RREADY : IN STD_LOGIC;
      M00_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      M00_AXI_ACLK : IN STD_LOGIC;
      M00_AXI_AWID : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_AWADDR : OUT STD_LOGIC_VECTOR(37 DOWNTO 0);
      M00_AXI_AWLEN : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      M00_AXI_AWSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M00_AXI_AWBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      M00_AXI_AWLOCK : OUT STD_LOGIC;
      M00_AXI_AWCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M00_AXI_AWQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_AWVALID : OUT STD_LOGIC;
      M00_AXI_AWREADY : IN STD_LOGIC;
      M00_AXI_WDATA : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
      M00_AXI_WSTRB : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      M00_AXI_WLAST : OUT STD_LOGIC;
      M00_AXI_WVALID : OUT STD_LOGIC;
      M00_AXI_WREADY : IN STD_LOGIC;
      M00_AXI_BID : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      M00_AXI_BVALID : IN STD_LOGIC;
      M00_AXI_BREADY : OUT STD_LOGIC;
      M00_AXI_ARID : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_ARADDR : OUT STD_LOGIC_VECTOR(37 DOWNTO 0);
      M00_AXI_ARLEN : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      M00_AXI_ARSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M00_AXI_ARBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      M00_AXI_ARLOCK : OUT STD_LOGIC;
      M00_AXI_ARCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M00_AXI_ARQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_ARVALID : OUT STD_LOGIC;
      M00_AXI_ARREADY : IN STD_LOGIC;
      M00_AXI_RID : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_RDATA : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
      M00_AXI_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      M00_AXI_RLAST : IN STD_LOGIC;
      M00_AXI_RVALID : IN STD_LOGIC;
      M00_AXI_RREADY : OUT STD_LOGIC
      );
  END COMPONENT;

  signal mAxiRstL : sl;

  signal sAxiReadMasters  : AxiReadMasterArray (5 downto 0) := (others=>AXI_READ_MASTER_INIT_C);
  signal sAxiReadSlaves   : AxiReadSlaveArray  (5 downto 0) := (others=>AXI_READ_SLAVE_INIT_C);
  signal isAxiWriteSlaves : AxiWriteSlaveArray  (5 downto 0) := (others=>AXI_WRITE_SLAVE_INIT_C);
  signal imAxiWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
  signal imAxiReadMaster  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;

  component ila_0
    port ( clk     : in sl;
           probe0  : in slv(255 downto 0) );
  end component;
  
begin

  mAxiRstL        <= not(mAxiRst);
  mAxiWriteMaster <= imAxiWriteMaster;
  mAxiReadMaster  <= imAxiReadMaster;
  sAxiWriteSlaves <= isAxiWriteSlaves;
  
   U_ILA_MAXI : ila_0
     port map ( clk         => mAxiClk,
                probe0             (0) => mAxiRst,
                probe0             (1) => imAxiWriteMaster.awvalid,
                probe0( 39 downto   2) => imAxiWriteMaster.awaddr(37 downto 0),
                probe0( 47 downto  40) => imAxiWriteMaster.awlen,
                probe0( 50 downto  48) => imAxiWriteMaster.awsize,
                probe0            (51) => imAxiWriteMaster.wvalid,
                probe0            (52) => imAxiWriteMaster.wlast,
                probe0            (53) => imAxiWriteMaster.wvalid,
                probe0            (54) => mAxiWriteSlave.awready,
                probe0            (55) => mAxiWriteSlave.wready,
                probe0            (56) => mAxiWriteSlave.bvalid,
                probe0( 58 downto  57) => mAxiWriteSlave.bresp,
                probe0            (59) => imAxiWriteMaster.bready,
                probe0( 91 downto  60) => imAxiWriteMaster.wstrb(31 downto 0),
                probe0(255 downto  92) => (others=>'0') );

   U_ILA_SAXI : ila_0
     port map ( clk         => sAxiClk,
                probe0             (0) => sAxiRst,
                probe0             (1) => sAxiWriteMasters(0).awvalid,
                probe0             (2) => sAxiWriteMasters(1).awvalid,
                probe0             (3) => sAxiWriteMasters(2).awvalid,
                probe0             (4) => sAxiWriteMasters(3).awvalid,
                probe0             (5) => sAxiWriteMasters(4).awvalid,
                probe0             (6) => sAxiWriteMasters(5).awvalid,
                probe0             (7) => sAxiWriteMasters(0).wvalid,
                probe0             (8) => sAxiWriteMasters(1).wvalid,
                probe0             (9) => sAxiWriteMasters(2).wvalid,
                probe0            (10) => sAxiWriteMasters(3).wvalid,
                probe0            (11) => sAxiWriteMasters(4).wvalid,
                probe0            (12) => sAxiWriteMasters(5).wvalid,
                probe0            (13) => isAxiWriteSlaves(0).awready,
                probe0            (14) => isAxiWriteSlaves(1).awready,
                probe0            (15) => isAxiWriteSlaves(2).awready,
                probe0            (16) => isAxiWriteSlaves(3).awready,
                probe0            (17) => isAxiWriteSlaves(4).awready,
                probe0            (18) => isAxiWriteSlaves(5).awready,
                probe0            (19) => isAxiWriteSlaves(0).wready,
                probe0            (20) => isAxiWriteSlaves(1).wready,
                probe0            (21) => isAxiWriteSlaves(2).wready,
                probe0            (22) => isAxiWriteSlaves(3).wready,
                probe0            (23) => isAxiWriteSlaves(4).wready,
                probe0            (24) => isAxiWriteSlaves(5).wready,
                probe0            (25) => isAxiWriteSlaves(0).bvalid,
                probe0            (26) => isAxiWriteSlaves(1).bvalid,
                probe0            (27) => isAxiWriteSlaves(2).bvalid,
                probe0            (28) => isAxiWriteSlaves(3).bvalid,
                probe0            (29) => isAxiWriteSlaves(4).bvalid,
                probe0            (30) => isAxiWriteSlaves(5).bvalid,
                probe0            (31) => sAxiWriteMasters(0).bready,
                probe0            (32) => sAxiWriteMasters(1).bready,
                probe0            (33) => sAxiWriteMasters(2).bready,
                probe0            (34) => sAxiWriteMasters(3).bready,
                probe0            (35) => sAxiWriteMasters(4).bready,
                probe0            (36) => sAxiWriteMasters(5).bready,
                probe0(255 downto  37) => (others=>'0') );

   -------------------
   -- AXI PCIe IP Core
   -------------------
   U_AxiCrossbar : PcieXbar
      port map (
         INTERCONNECT_ACLK    => mAxiClk,
         INTERCONNECT_ARESETN => mAxiRstL,
         -- SLAVE[0] 
         S00_AXI_ARESET_OUT_N => open,
         S00_AXI_ACLK         => sAxiClk,
         S00_AXI_AWID(0)      => '0',
         S00_AXI_AWADDR       => sAxiWriteMasters(0).awaddr(37 downto 0),
         S00_AXI_AWLEN        => sAxiWriteMasters(0).awlen,
         S00_AXI_AWSIZE       => sAxiWriteMasters(0).awsize,
         S00_AXI_AWBURST      => sAxiWriteMasters(0).awburst,
         S00_AXI_AWLOCK       => sAxiWriteMasters(0).awlock(0),
         S00_AXI_AWCACHE      => sAxiWriteMasters(0).awcache,
         S00_AXI_AWPROT       => sAxiWriteMasters(0).awprot,
         S00_AXI_AWQOS        => sAxiWriteMasters(0).awqos,
         S00_AXI_AWVALID      => sAxiWriteMasters(0).awvalid,
         S00_AXI_AWREADY      => isAxiWriteSlaves(0).awready,
         S00_AXI_WDATA        => sAxiWriteMasters(0).wdata(63 downto 0),
         S00_AXI_WSTRB        => sAxiWriteMasters(0).wstrb( 7 downto 0),
         S00_AXI_WLAST        => sAxiWriteMasters(0).wlast,
         S00_AXI_WVALID       => sAxiWriteMasters(0).wvalid,
         S00_AXI_WREADY       => isAxiWriteSlaves(0).wready,
         S00_AXI_BID          => isAxiWriteSlaves(0).bid(0 downto 0),
         S00_AXI_BRESP        => isAxiWriteSlaves(0).bresp,
         S00_AXI_BVALID       => isAxiWriteSlaves(0).bvalid,
         S00_AXI_BREADY       => sAxiWriteMasters(0).bready,
         S00_AXI_ARID(0)      => '0',
         S00_AXI_ARADDR       => sAxiReadMasters(0).araddr(37 downto 0),
         S00_AXI_ARLEN        => sAxiReadMasters(0).arlen,
         S00_AXI_ARSIZE       => sAxiReadMasters(0).arsize,
         S00_AXI_ARBURST      => sAxiReadMasters(0).arburst,
         S00_AXI_ARLOCK       => sAxiReadMasters(0).arlock(0),
         S00_AXI_ARCACHE      => sAxiReadMasters(0).arcache,
         S00_AXI_ARPROT       => sAxiReadMasters(0).arprot,
         S00_AXI_ARQOS        => sAxiReadMasters(0).arqos,
         S00_AXI_ARVALID      => sAxiReadMasters(0).arvalid,
         S00_AXI_ARREADY      => sAxiReadSlaves(0).arready,
         S00_AXI_RID          => sAxiReadSlaves(0).rid(0 downto 0),
         S00_AXI_RDATA        => sAxiReadSlaves(0).rdata(63 downto 0),
         S00_AXI_RRESP        => sAxiReadSlaves(0).rresp,
         S00_AXI_RLAST        => sAxiReadSlaves(0).rlast,
         S00_AXI_RVALID       => sAxiReadSlaves(0).rvalid,
         S00_AXI_RREADY       => sAxiReadMasters(0).rready,
         -- SLAVE[1]
         S01_AXI_ARESET_OUT_N => open,
         S01_AXI_ACLK         => sAxiClk,
         S01_AXI_AWID(0)      => '0',
         S01_AXI_AWADDR       => sAxiWriteMasters(1).awaddr(37 downto 0),
         S01_AXI_AWLEN        => sAxiWriteMasters(1).awlen,
         S01_AXI_AWSIZE       => sAxiWriteMasters(1).awsize,
         S01_AXI_AWBURST      => sAxiWriteMasters(1).awburst,
         S01_AXI_AWLOCK       => sAxiWriteMasters(1).awlock(0),
         S01_AXI_AWCACHE      => "0000",  -- revert back the cache
         S01_AXI_AWPROT       => sAxiWriteMasters(1).awprot,
         S01_AXI_AWQOS        => sAxiWriteMasters(1).awqos,
         S01_AXI_AWVALID      => sAxiWriteMasters(1).awvalid,
         S01_AXI_AWREADY      => isAxiWriteSlaves(1).awready,
         S01_AXI_WDATA        => sAxiWriteMasters(1).wdata(63 downto 0),
         S01_AXI_WSTRB        => sAxiWriteMasters(1).wstrb( 7 downto 0),
         S01_AXI_WLAST        => sAxiWriteMasters(1).wlast,
         S01_AXI_WVALID       => sAxiWriteMasters(1).wvalid,
         S01_AXI_WREADY       => isAxiWriteSlaves(1).wready,
         S01_AXI_BID          => isAxiWriteSlaves(1).bid(0 downto 0),
         S01_AXI_BRESP        => isAxiWriteSlaves(1).bresp,
         S01_AXI_BVALID       => isAxiWriteSlaves(1).bvalid,
         S01_AXI_BREADY       => sAxiWriteMasters(1).bready,
         S01_AXI_ARID(0)      => '0',
         S01_AXI_ARADDR       => sAxiReadMasters(1).araddr(37 downto 0),
         S01_AXI_ARLEN        => sAxiReadMasters(1).arlen,
         S01_AXI_ARSIZE       => sAxiReadMasters(1).arsize,
         S01_AXI_ARBURST      => sAxiReadMasters(1).arburst,
         S01_AXI_ARLOCK       => sAxiReadMasters(1).arlock(0),
         S01_AXI_ARCACHE      => sAxiReadMasters(1).arcache,
         S01_AXI_ARPROT       => sAxiReadMasters(1).arprot,
         S01_AXI_ARQOS        => sAxiReadMasters(1).arqos,
         S01_AXI_ARVALID      => sAxiReadMasters(1).arvalid,
         S01_AXI_ARREADY      => sAxiReadSlaves(1).arready,
         S01_AXI_RID          => sAxiReadSlaves(1).rid(0 downto 0),
         S01_AXI_RDATA        => sAxiReadSlaves(1).rdata(63 downto 0),
         S01_AXI_RRESP        => sAxiReadSlaves(1).rresp,
         S01_AXI_RLAST        => sAxiReadSlaves(1).rlast,
         S01_AXI_RVALID       => sAxiReadSlaves(1).rvalid,
         S01_AXI_RREADY       => sAxiReadMasters(1).rready,
         -- SLAVE[2]
         S02_AXI_ARESET_OUT_N => open,
         S02_AXI_ACLK         => sAxiClk,
         S02_AXI_AWID(0)      => '0',
         S02_AXI_AWADDR       => sAxiWriteMasters(2).awaddr(37 downto 0),
         S02_AXI_AWLEN        => sAxiWriteMasters(2).awlen,
         S02_AXI_AWSIZE       => sAxiWriteMasters(2).awsize,
         S02_AXI_AWBURST      => sAxiWriteMasters(2).awburst,
         S02_AXI_AWLOCK       => sAxiWriteMasters(2).awlock(0),
         S02_AXI_AWCACHE      => "0000",  -- revert back the cache
         S02_AXI_AWPROT       => sAxiWriteMasters(2).awprot,
         S02_AXI_AWQOS        => sAxiWriteMasters(2).awqos,
         S02_AXI_AWVALID      => sAxiWriteMasters(2).awvalid,
         S02_AXI_AWREADY      => isAxiWriteSlaves(2).awready,
         S02_AXI_WDATA        => sAxiWriteMasters(2).wdata(63 downto 0),
         S02_AXI_WSTRB        => sAxiWriteMasters(2).wstrb( 7 downto 0),
         S02_AXI_WLAST        => sAxiWriteMasters(2).wlast,
         S02_AXI_WVALID       => sAxiWriteMasters(2).wvalid,
         S02_AXI_WREADY       => isAxiWriteSlaves(2).wready,
         S02_AXI_BID          => isAxiWriteSlaves(2).bid(0 downto 0),
         S02_AXI_BRESP        => isAxiWriteSlaves(2).bresp,
         S02_AXI_BVALID       => isAxiWriteSlaves(2).bvalid,
         S02_AXI_BREADY       => sAxiWriteMasters(2).bready,
         S02_AXI_ARID(0)      => '0',
         S02_AXI_ARADDR       => sAxiReadMasters(2).araddr(37 downto 0),
         S02_AXI_ARLEN        => sAxiReadMasters(2).arlen,
         S02_AXI_ARSIZE       => sAxiReadMasters(2).arsize,
         S02_AXI_ARBURST      => sAxiReadMasters(2).arburst,
         S02_AXI_ARLOCK       => sAxiReadMasters(2).arlock(0),
         S02_AXI_ARCACHE      => sAxiReadMasters(2).arcache,
         S02_AXI_ARPROT       => sAxiReadMasters(2).arprot,
         S02_AXI_ARQOS        => sAxiReadMasters(2).arqos,
         S02_AXI_ARVALID      => sAxiReadMasters(2).arvalid,
         S02_AXI_ARREADY      => sAxiReadSlaves(2).arready,
         S02_AXI_RID          => sAxiReadSlaves(2).rid(0 downto 0),
         S02_AXI_RDATA        => sAxiReadSlaves(2).rdata(63 downto 0),
         S02_AXI_RRESP        => sAxiReadSlaves(2).rresp,
         S02_AXI_RLAST        => sAxiReadSlaves(2).rlast,
         S02_AXI_RVALID       => sAxiReadSlaves(2).rvalid,
         S02_AXI_RREADY       => sAxiReadMasters(2).rready,
         -- SLAVE[3]
         S03_AXI_ARESET_OUT_N => open,
         S03_AXI_ACLK         => sAxiClk,
         S03_AXI_AWID(0)      => '0',
         S03_AXI_AWADDR       => sAxiWriteMasters(3).awaddr(37 downto 0),
         S03_AXI_AWLEN        => sAxiWriteMasters(3).awlen,
         S03_AXI_AWSIZE       => sAxiWriteMasters(3).awsize,
         S03_AXI_AWBURST      => sAxiWriteMasters(3).awburst,
         S03_AXI_AWLOCK       => sAxiWriteMasters(3).awlock(0),
         S03_AXI_AWCACHE      => "0000",  -- revert back the cache
         S03_AXI_AWPROT       => sAxiWriteMasters(3).awprot,
         S03_AXI_AWQOS        => sAxiWriteMasters(3).awqos,
         S03_AXI_AWVALID      => sAxiWriteMasters(3).awvalid,
         S03_AXI_AWREADY      => isAxiWriteSlaves(3).awready,
         S03_AXI_WDATA        => sAxiWriteMasters(3).wdata(63 downto 0),
         S03_AXI_WSTRB        => sAxiWriteMasters(3).wstrb( 7 downto 0),
         S03_AXI_WLAST        => sAxiWriteMasters(3).wlast,
         S03_AXI_WVALID       => sAxiWriteMasters(3).wvalid,
         S03_AXI_WREADY       => isAxiWriteSlaves(3).wready,
         S03_AXI_BID          => isAxiWriteSlaves(3).bid(0 downto 0),
         S03_AXI_BRESP        => isAxiWriteSlaves(3).bresp,
         S03_AXI_BVALID       => isAxiWriteSlaves(3).bvalid,
         S03_AXI_BREADY       => sAxiWriteMasters(3).bready,
         S03_AXI_ARID(0)      => '0',
         S03_AXI_ARADDR       => sAxiReadMasters(3).araddr(37 downto 0),
         S03_AXI_ARLEN        => sAxiReadMasters(3).arlen,
         S03_AXI_ARSIZE       => sAxiReadMasters(3).arsize,
         S03_AXI_ARBURST      => sAxiReadMasters(3).arburst,
         S03_AXI_ARLOCK       => sAxiReadMasters(3).arlock(0),
         S03_AXI_ARCACHE      => sAxiReadMasters(3).arcache,
         S03_AXI_ARPROT       => sAxiReadMasters(3).arprot,
         S03_AXI_ARQOS        => sAxiReadMasters(3).arqos,
         S03_AXI_ARVALID      => sAxiReadMasters(3).arvalid,
         S03_AXI_ARREADY      => sAxiReadSlaves(3).arready,
         S03_AXI_RID          => sAxiReadSlaves(3).rid(0 downto 0),
         S03_AXI_RDATA        => sAxiReadSlaves(3).rdata(63 downto 0),
         S03_AXI_RRESP        => sAxiReadSlaves(3).rresp,
         S03_AXI_RLAST        => sAxiReadSlaves(3).rlast,
         S03_AXI_RVALID       => sAxiReadSlaves(3).rvalid,
         S03_AXI_RREADY       => sAxiReadMasters(3).rready,
         -- SLAVE[4]
         S04_AXI_ARESET_OUT_N => open,
         S04_AXI_ACLK         => sAxiClk,
         S04_AXI_AWID(0)      => '0',
         S04_AXI_AWADDR       => sAxiWriteMasters(4).awaddr(37 downto 0),
         S04_AXI_AWLEN        => sAxiWriteMasters(4).awlen,
         S04_AXI_AWSIZE       => sAxiWriteMasters(4).awsize,
         S04_AXI_AWBURST      => sAxiWriteMasters(4).awburst,
         S04_AXI_AWLOCK       => sAxiWriteMasters(4).awlock(0),
         S04_AXI_AWCACHE      => "0000",  -- revert back the cache
         S04_AXI_AWPROT       => sAxiWriteMasters(4).awprot,
         S04_AXI_AWQOS        => sAxiWriteMasters(4).awqos,
         S04_AXI_AWVALID      => sAxiWriteMasters(4).awvalid,
         S04_AXI_AWREADY      => isAxiWriteSlaves(4).awready,
         S04_AXI_WDATA        => sAxiWriteMasters(4).wdata(63 downto 0),
         S04_AXI_WSTRB        => sAxiWriteMasters(4).wstrb( 7 downto 0),
         S04_AXI_WLAST        => sAxiWriteMasters(4).wlast,
         S04_AXI_WVALID       => sAxiWriteMasters(4).wvalid,
         S04_AXI_WREADY       => isAxiWriteSlaves(4).wready,
         S04_AXI_BID          => isAxiWriteSlaves(4).bid(0 downto 0),
         S04_AXI_BRESP        => isAxiWriteSlaves(4).bresp,
         S04_AXI_BVALID       => isAxiWriteSlaves(4).bvalid,
         S04_AXI_BREADY       => sAxiWriteMasters(4).bready,
         S04_AXI_ARID(0)      => '0',
         S04_AXI_ARADDR       => sAxiReadMasters(4).araddr(37 downto 0),
         S04_AXI_ARLEN        => sAxiReadMasters(4).arlen,
         S04_AXI_ARSIZE       => sAxiReadMasters(4).arsize,
         S04_AXI_ARBURST      => sAxiReadMasters(4).arburst,
         S04_AXI_ARLOCK       => sAxiReadMasters(4).arlock(0),
         S04_AXI_ARCACHE      => sAxiReadMasters(4).arcache,
         S04_AXI_ARPROT       => sAxiReadMasters(4).arprot,
         S04_AXI_ARQOS        => sAxiReadMasters(4).arqos,
         S04_AXI_ARVALID      => sAxiReadMasters(4).arvalid,
         S04_AXI_ARREADY      => sAxiReadSlaves(4).arready,
         S04_AXI_RID          => sAxiReadSlaves(4).rid(0 downto 0),
         S04_AXI_RDATA        => sAxiReadSlaves(4).rdata(63 downto 0),
         S04_AXI_RRESP        => sAxiReadSlaves(4).rresp,
         S04_AXI_RLAST        => sAxiReadSlaves(4).rlast,
         S04_AXI_RVALID       => sAxiReadSlaves(4).rvalid,
         S04_AXI_RREADY       => sAxiReadMasters(4).rready,
         -- SLAVE[5]
         S05_AXI_ARESET_OUT_N => open,
         S05_AXI_ACLK         => sAxiClk,
         S05_AXI_AWID(0)      => '0',
         S05_AXI_AWADDR       => sAxiWriteMasters(5).awaddr(37 downto 0),
         S05_AXI_AWLEN        => sAxiWriteMasters(5).awlen,
         S05_AXI_AWSIZE       => sAxiWriteMasters(5).awsize,
         S05_AXI_AWBURST      => sAxiWriteMasters(5).awburst,
         S05_AXI_AWLOCK       => sAxiWriteMasters(5).awlock(0),
         S05_AXI_AWCACHE      => "0000",  -- revert back the cache
         S05_AXI_AWPROT       => sAxiWriteMasters(5).awprot,
         S05_AXI_AWQOS        => sAxiWriteMasters(5).awqos,
         S05_AXI_AWVALID      => sAxiWriteMasters(5).awvalid,
         S05_AXI_AWREADY      => isAxiWriteSlaves(5).awready,
         S05_AXI_WDATA        => sAxiWriteMasters(5).wdata(63 downto 0),
         S05_AXI_WSTRB        => sAxiWriteMasters(5).wstrb( 7 downto 0),
         S05_AXI_WLAST        => sAxiWriteMasters(5).wlast,
         S05_AXI_WVALID       => sAxiWriteMasters(5).wvalid,
         S05_AXI_WREADY       => isAxiWriteSlaves(5).wready,
         S05_AXI_BID          => isAxiWriteSlaves(5).bid(0 downto 0),
         S05_AXI_BRESP        => isAxiWriteSlaves(5).bresp,
         S05_AXI_BVALID       => isAxiWriteSlaves(5).bvalid,
         S05_AXI_BREADY       => sAxiWriteMasters(5).bready,
         S05_AXI_ARID(0)      => '0',
         S05_AXI_ARADDR       => sAxiReadMasters(5).araddr(37 downto 0),
         S05_AXI_ARLEN        => sAxiReadMasters(5).arlen,
         S05_AXI_ARSIZE       => sAxiReadMasters(5).arsize,
         S05_AXI_ARBURST      => sAxiReadMasters(5).arburst,
         S05_AXI_ARLOCK       => sAxiReadMasters(5).arlock(0),
         S05_AXI_ARCACHE      => sAxiReadMasters(5).arcache,
         S05_AXI_ARPROT       => sAxiReadMasters(5).arprot,
         S05_AXI_ARQOS        => sAxiReadMasters(5).arqos,
         S05_AXI_ARVALID      => sAxiReadMasters(5).arvalid,
         S05_AXI_ARREADY      => sAxiReadSlaves(5).arready,
         S05_AXI_RID          => sAxiReadSlaves(5).rid(0 downto 0),
         S05_AXI_RDATA        => sAxiReadSlaves(5).rdata(63 downto 0),
         S05_AXI_RRESP        => sAxiReadSlaves(5).rresp,
         S05_AXI_RLAST        => sAxiReadSlaves(5).rlast,
         S05_AXI_RVALID       => sAxiReadSlaves(5).rvalid,
         S05_AXI_RREADY       => sAxiReadMasters(5).rready,
         -- MASTER         
         M00_AXI_ARESET_OUT_N => open,
         M00_AXI_ACLK         => mAxiClk,
         M00_AXI_AWID         => imAxiWriteMaster.awid(3 downto 0),
         M00_AXI_AWADDR       => imAxiWriteMaster.awaddr(37 downto 0),
         M00_AXI_AWLEN        => imAxiWriteMaster.awlen,
         M00_AXI_AWSIZE       => imAxiWriteMaster.awsize,
         M00_AXI_AWBURST      => imAxiWriteMaster.awburst,
         M00_AXI_AWLOCK       => imAxiWriteMaster.awlock(0),
         M00_AXI_AWCACHE      => imAxiWriteMaster.awcache,
         M00_AXI_AWPROT       => imAxiWriteMaster.awprot,
         M00_AXI_AWQOS        => imAxiWriteMaster.awqos,
         M00_AXI_AWVALID      => imAxiWriteMaster.awvalid,
         M00_AXI_AWREADY      => mAxiWriteSlave.awready,
         M00_AXI_WDATA        => imAxiWriteMaster.wdata(255 downto 0),
         M00_AXI_WSTRB        => imAxiWriteMaster.wstrb(31 downto 0),
         M00_AXI_WLAST        => imAxiWriteMaster.wlast,
         M00_AXI_WVALID       => imAxiWriteMaster.wvalid,
         M00_AXI_WREADY       => mAxiWriteSlave.wready,
         M00_AXI_BID          => mAxiWriteSlave.bid(3 downto 0),
         M00_AXI_BRESP        => mAxiWriteSlave.bresp,
         M00_AXI_BVALID       => mAxiWriteSlave.bvalid,
         M00_AXI_BREADY       => imAxiWriteMaster.bready,
         M00_AXI_ARID         => imAxiReadMaster.arid(3 downto 0),
         M00_AXI_ARADDR       => imAxiReadMaster.araddr(37 downto 0),
         M00_AXI_ARLEN        => imAxiReadMaster.arlen,
         M00_AXI_ARSIZE       => imAxiReadMaster.arsize,
         M00_AXI_ARBURST      => imAxiReadMaster.arburst,
         M00_AXI_ARLOCK       => imAxiReadMaster.arlock(0),
         M00_AXI_ARCACHE      => imAxiReadMaster.arcache,
         M00_AXI_ARPROT       => imAxiReadMaster.arprot,
         M00_AXI_ARQOS        => imAxiReadMaster.arqos,
         M00_AXI_ARVALID      => imAxiReadMaster.arvalid,
         M00_AXI_ARREADY      => mAxiReadSlave.arready,
         M00_AXI_RID          => mAxiReadSlave.rid(3 downto 0),
         M00_AXI_RDATA        => mAxiReadSlave.rdata(255 downto 0),
         M00_AXI_RRESP        => mAxiReadSlave.rresp,
         M00_AXI_RLAST        => mAxiReadSlave.rlast,
         M00_AXI_RVALID       => mAxiReadSlave.rvalid,
         M00_AXI_RREADY       => imAxiReadMaster.rready);

end mapping;


