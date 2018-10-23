------------------------------------------------------------------------------
-- File       : MigIlvToPcieWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-10-20
-------------------------------------------------------------------------------
-- Description: Receives transfer requests representing data buffers pending
-- in local DRAM and moves data to CPU host memory over PCIe AXI interface.
-- Captures histograms of local DRAM buffer depth and PCIe target address FIFO
-- depth.  Needs an AxiStream to AXI channel to write histograms to host memory.
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
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiDescPkg.all;
use work.AppMigPkg.all;

entity MigIlvToPcieWrapper is
  generic (  AXIL_BASE_ADDR_G : slv(31 downto 0) := x"00000000";
             AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
             DEBUG_G          : boolean          := true );
  port    ( -- Clock and reset
    axiClk           : in  sl; -- 200MHz
    axiRst           : in  sl; -- need a user reset to clear the pipeline
    usrRst           : out sl;
    -- AXI4 Interfaces to MIG
    axiReadMasters   : out AxiReadMasterType;
    axiReadSlaves    : in  AxiReadSlaveType;
    -- AxiStream Interfaces from MIG (Data Mover command)
    dscReadMasters   : in  AxiDescMasterType;
    dscReadSlaves    : out AxiDescSlaveType;
    -- AXI4 Interface to PCIe
    axiWriteMasters  : out AxiWriteMasterType;
    axiWriteSlaves   : in  AxiWriteSlaveType;
    -- AXI Lite Interface
    axilClk          : in  sl;
    axilRst          : in  sl;
    axilWriteMaster  : in  AxiLiteWriteMasterType;
    axilWriteSlave   : out AxiLiteWriteSlaveType;
    axilReadMaster   : in  AxiLiteReadMasterType;
    axilReadSlave    : out AxiLiteReadSlaveType;
    -- (axiClk domain)
    migConfig        : out MigConfigType;
    migStatus        : in  MigStatusType );
end MigIlvToPcieWrapper;

architecture mapping of MigIlvToPcieWrapper is

  COMPONENT MigIlvToPcie
    PORT (
      m_axi_mm2s_aclk : IN STD_LOGIC;
      m_axi_mm2s_aresetn : IN STD_LOGIC;
      mm2s_err : OUT STD_LOGIC;
      m_axis_mm2s_cmdsts_aclk : IN STD_LOGIC;
      m_axis_mm2s_cmdsts_aresetn : IN STD_LOGIC;
      s_axis_mm2s_cmd_tvalid : IN STD_LOGIC;
      s_axis_mm2s_cmd_tready : OUT STD_LOGIC;
      s_axis_mm2s_cmd_tdata : IN STD_LOGIC_VECTOR(79 DOWNTO 0);
      m_axis_mm2s_sts_tvalid : OUT STD_LOGIC;
      m_axis_mm2s_sts_tready : IN STD_LOGIC;
      m_axis_mm2s_sts_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axis_mm2s_sts_tkeep : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axis_mm2s_sts_tlast : OUT STD_LOGIC;
--      m_axi_mm2s_arid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_mm2s_araddr : OUT STD_LOGIC_VECTOR(37 DOWNTO 0);
      m_axi_mm2s_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_mm2s_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_mm2s_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_mm2s_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_mm2s_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_mm2s_aruser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_mm2s_arvalid : OUT STD_LOGIC;
      m_axi_mm2s_arready : IN STD_LOGIC;
      m_axi_mm2s_rdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
      m_axi_mm2s_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_mm2s_rlast : IN STD_LOGIC;
      m_axi_mm2s_rvalid : IN STD_LOGIC;
      m_axi_mm2s_rready : OUT STD_LOGIC;
      m_axis_mm2s_tdata : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
      m_axis_mm2s_tkeep : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0);
      m_axis_mm2s_tlast : OUT STD_LOGIC;
      m_axis_mm2s_tvalid : OUT STD_LOGIC;
      m_axis_mm2s_tready : IN STD_LOGIC;
      m_axi_s2mm_aclk : IN STD_LOGIC;
      m_axi_s2mm_aresetn : IN STD_LOGIC;
      s2mm_err : OUT STD_LOGIC;
      m_axis_s2mm_cmdsts_awclk : IN STD_LOGIC;
      m_axis_s2mm_cmdsts_aresetn : IN STD_LOGIC;
      s_axis_s2mm_cmd_tvalid : IN STD_LOGIC;
      s_axis_s2mm_cmd_tready : OUT STD_LOGIC;
      s_axis_s2mm_cmd_tdata : IN STD_LOGIC_VECTOR(79 DOWNTO 0);
      m_axis_s2mm_sts_tvalid : OUT STD_LOGIC;
      m_axis_s2mm_sts_tready : IN STD_LOGIC;
      m_axis_s2mm_sts_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axis_s2mm_sts_tkeep : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      m_axis_s2mm_sts_tlast : OUT STD_LOGIC;
--      m_axi_s2mm_awid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_s2mm_awaddr : OUT STD_LOGIC_VECTOR(37 DOWNTO 0);
      m_axi_s2mm_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_s2mm_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_s2mm_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_s2mm_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_s2mm_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_s2mm_awuser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_s2mm_awvalid : OUT STD_LOGIC;
      m_axi_s2mm_awready : IN STD_LOGIC;
      m_axi_s2mm_wdata : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
      m_axi_s2mm_wstrb : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0);
      m_axi_s2mm_wlast : OUT STD_LOGIC;
      m_axi_s2mm_wvalid : OUT STD_LOGIC;
      m_axi_s2mm_wready : IN STD_LOGIC;
      m_axi_s2mm_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_s2mm_bvalid : IN STD_LOGIC;
      m_axi_s2mm_bready : OUT STD_LOGIC;
      s_axis_s2mm_tdata : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
      s_axis_s2mm_tkeep : IN STD_LOGIC_VECTOR( 31 DOWNTO 0);
      s_axis_s2mm_tlast : IN STD_LOGIC;
      s_axis_s2mm_tvalid : IN STD_LOGIC;
      s_axis_s2mm_tready : OUT STD_LOGIC
      );
  END COMPONENT;

  signal axiRstN : sl;
  
  --  Assumes 40b memory addresses
  signal intDscReadMasters  : AxiDescMasterType;
  signal intDscReadSlaves   : AxiDescSlaveType := AXI_DESC_SLAVE_INIT_C;
  signal intDscWriteMasters : AxiDescMasterType;
  signal intDscWriteSlaves  : AxiDescSlaveType := AXI_DESC_SLAVE_INIT_C;

  signal intSlaves          : AxiStreamSlaveType;
  signal intMasters_tValid  : sl;
  signal intMasters_tLast   : sl;
  signal intMasters_tData   : slv(255 downto 0);
  signal intMasters_tKeep   : slv( 31 downto 0);

  --  Assumes 16b buffer ids
  signal dcountRamAddr  : slv(11 downto 0) := (others=>'0');
  signal rdRamAddr      : sl := '0';
  signal validRamAddr   : sl := '0';
  signal doutRamAddr    : slv(63 downto 0) := (others=>'0');
  signal doutWriteDesc  : slv(43 downto 0) := (others=>'0');
  signal dcountWriteDesc: slv( 4 downto 0) := (others=>'0');
  signal rdWriteDesc    : sl;
  signal validWriteDesc : sl;
  signal fullWriteDesc  : sl;
  
  signal sAxilReadMaster  : AxiLiteReadMasterType;
  signal sAxilReadSlave   : AxiLiteReadSlaveType;
  signal sAxilWriteMaster : AxiLiteWriteMasterType;
  signal sAxilWriteSlave  : AxiLiteWriteSlaveType;
  
  type RegType is record
    axilWriteSlave : AxiLiteWriteSlaveType;
    axilReadSlave  : AxiLiteReadSlaveType;
    migConfig      : MigConfigType;
    fifoDin        : slv(63 downto 0);
    wrRamAddr      : sl;
    rdRamAddr      : sl;
    wrDesc         : sl;
    wrDescDin      : slv                 (43 downto 0);
    rdDesc         : sl;
    readMasters    : AxiStreamMasterType; -- command stream
    readSlaves     : AxiStreamSlaveType ; -- command stream
    writeMasters   : AxiStreamMasterType; -- command stream
    writeSlaves    : AxiStreamSlaveType ; -- status stream
    wrBaseAddr     : slv(63 downto 0);
    wrIndex        : slv(11 downto 0);
    autoFill       : sl;
    axiBusy        : sl;
    axiWriteMaster : AxiWriteMasterType; -- Descriptor
    readQueCnt     : slv(7 downto 0);
    writeQueCnt    : slv(7 downto 0);
    descQueCnt     : slv(7 downto 0);
    -- Diagnostics control
    monEnable      : sl;
    monSampleInt   : slv                 (15 downto 0);
    monReadoutInt  : slv                 (19 downto 0);
    monBaseAddr    : slv                 (39 downto 0);
    monSample      : sl;
    monSampleCnt   : slv                 (15 downto 0);
    monReadout     : sl;
    monReadoutCnt  : slv                 (19 downto 0);
    usrRst         : slv                 ( 9 downto 0);
    tlastd         : sl;
  end record;

  constant REG_INIT_C : RegType := (
    axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
    axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
    migConfig      => MIG_CONFIG_INIT_C,
    fifoDin        => (others=>'0'),
    wrRamAddr      => '0',
    rdRamAddr      => '0',
    wrDesc         => '0',
    wrDescDin      => (others=>'0'),
    rdDesc         => '0',
    readMasters    => AXI_STREAM_MASTER_INIT_C,
    readSlaves     => AXI_STREAM_SLAVE_INIT_C,
    writeMasters   => axiStreamMasterInit(DESC_STREAM_CONFIG_INIT_C),
    writeSlaves    => AXI_STREAM_SLAVE_INIT_C,
    wrBaseAddr     => (others=>'0'),
    wrIndex        => (others=>'0'),
    autoFill       => '0',
    axiBusy        => '0',
    axiWriteMaster => AXI_WRITE_MASTER_INIT_C,
    readQueCnt     => (others=>'0'),
    writeQueCnt    => (others=>'0'),
    descQueCnt     => (others=>'0'),
    monEnable      => '0',
    monSampleInt   => toSlv(200,16),     -- 1MHz
    monReadoutInt  => toSlv(1000000,20), -- 1MHz -> 1Hz
    monBaseAddr    => (others=>'0'),
    monSample      => '0',
    monSampleCnt   => (others=>'0'),
    monReadout     => '0',
    monReadoutCnt  => (others=>'0'),
    usrRst         => "1111110000",
    tlastd         => '0' );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal monRst     : sl;
  signal monMigStatusMaster : AxiStreamMasterType;
  signal monMigStatusSlave  : AxiStreamSlaveType;
  signal monWriteDescMaster : AxiStreamMasterType;
  signal monWriteDescSlave  : AxiStreamSlaveType;
  signal monStatus  : slv(8 downto 0);
  
  constant MON_MIG_STATUS_AWIDTH_C : integer := 8;
  constant MON_WRITE_DESC_AWIDTH_C : integer := 8;

  signal iaxiReadMasters  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
  signal iaxiWriteMasters : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
  signal iaxiWriteSlaves  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
  signal raxiWriteSlave   : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
  signal saxiWriteMasters : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
  signal usrRstN          : sl;

  signal s2mm_err         : sl;
  signal mm2s_err         : sl;

  signal monAxiWriteMaster : AxiWriteMasterType;
  signal monAxiWriteSlave  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
  
  constant DEBUG_C : boolean := DEBUG_G;

  component ila_0
    port ( clk : in sl;
           probe0 : in slv(255 downto 0) );
  end component;
  
begin

  GEN_DEBUG : if DEBUG_C generate
    U_ILA : ila_0
      port map ( clk                    => axiClk,
                 probe0(             0) => s2mm_err,
                 probe0(  3 downto   1) => (others=>'0'),
                 probe0(             4) => mm2s_err,
                 probe0(  7 downto   5) => (others=>'0'),
                 probe0(             8) => r.axiWriteMaster.awvalid,
                 probe0(             9) => r.axiWriteMaster.bready,
                 probe0( 47 downto  10) => r.axiWriteMaster.awaddr        (37 downto 0),
                 probe0( 71 downto  48) => r.axiWriteMaster.wdata         (23 downto 0),
                 probe0( 95 downto  72) => r.axiWriteMaster.wdata         (55 downto 32),
                 probe0(167 downto  96) => (others=>'0'),
                 probe0(205 downto 168) => iaxiWriteMasters.awaddr        (37 downto 0),
                 probe0(           206) => r.writeMasters.tValid,
                 probe0(214 downto 207) => (others=>'0'),
                 probe0(218 downto 215) => intDscWriteSlaves.status.tData( 3 downto 0),
                 probe0(255 downto 219) => (others=>'0') );
  end generate;
  
  axiRstN                             <= not axiRst;
  axiReadMasters                      <= iaxiReadMasters;
  usrRst                              <= r.usrRst(0);
  usrRstN                             <= not r.usrRst(0);
  
  U_AxilAsync : entity work.AxiLiteAsync
    port map ( sAxiClk         => axilClk,
               sAxiClkRst      => axilRst,
               sAxiReadMaster  => axilReadMaster,
               sAxiReadSlave   => axilReadSlave,
               sAxiWriteMaster => axilWriteMaster,
               sAxiWriteSlave  => axilWriteSlave,
               mAxiClk         => axiClk,
               mAxiClkRst      => axiRst,
               mAxiReadMaster  => sAxilReadMaster,
               mAxiReadSlave   => sAxilReadSlave,
               mAxiWriteMaster => sAxilWriteMaster,
               mAxiWriteSlave  => sAxilWriteSlave );

  --
  --  Mux the data write master and the descriptor write master
  --
  U_Mux : entity work.AxiWritePathMux
    generic map ( NUM_SLAVES_G => 2 )
    port map ( axiClk              => axiClk,
               axiRst              => r.usrRst(0),
               sAxiWriteMasters(0) => iaxiWriteMasters,
               sAxiWriteMasters(1) => r.axiWriteMaster,
               sAxiWriteSlaves (0) => iaxiWriteSlaves ,
               sAxiWriteSlaves (1) => raxiWriteSlave  ,
               mAxiWriteMaster     => axiWriteMasters ,
               mAxiWriteSlave      => axiWriteSlaves  );

  U_ADM : MigIlvToPcie
    port map ( m_axi_mm2s_aclk            => axiClk,
               m_axi_mm2s_aresetn         => usrRstN,
               mm2s_err                   => mm2s_err,
               m_axis_mm2s_cmdsts_aclk    => axiClk,
               m_axis_mm2s_cmdsts_aresetn => usrRstN,
               s_axis_mm2s_cmd_tvalid     => intDscReadMasters.command.tValid,
               s_axis_mm2s_cmd_tready     => intDscReadSlaves.command .tReady,
               s_axis_mm2s_cmd_tdata      => intDscReadMasters.command.tData(79 DOWNTO 0),
               m_axis_mm2s_sts_tvalid     => intDscReadSlaves .status.tValid,
               m_axis_mm2s_sts_tready     => intDscReadMasters.status.tReady,
               m_axis_mm2s_sts_tdata      => intDscReadSlaves.status.tData(7 DOWNTO 0),
               m_axis_mm2s_sts_tkeep      => intDscReadSlaves.status.tKeep(0 DOWNTO 0),
               m_axis_mm2s_sts_tlast      => intDscReadSlaves.status.tLast,
--                 m_axi_mm2s_arid            => iaxiReadMasters.arid(3 downto 0),
               m_axi_mm2s_araddr          => iaxiReadMasters.araddr(37 downto 0),
               m_axi_mm2s_arlen           => iaxiReadMasters.arlen,
               m_axi_mm2s_arsize          => iaxiReadMasters.arsize,
               m_axi_mm2s_arburst         => iaxiReadMasters.arburst,
               m_axi_mm2s_arprot          => iaxiReadMasters.arprot,
               m_axi_mm2s_arcache         => iaxiReadMasters.arcache,
--                 m_axi_mm2s_aruser          => iaxiReadMasters(i).aruser,
               m_axi_mm2s_arvalid         => iaxiReadMasters.arvalid,
               m_axi_mm2s_arready         => axiReadSlaves .arready,
               m_axi_mm2s_rdata           => axiReadSlaves .rdata(511 downto 0),
               m_axi_mm2s_rresp           => axiReadSlaves .rresp,
               m_axi_mm2s_rlast           => axiReadSlaves .rlast,
               m_axi_mm2s_rvalid          => axiReadSlaves .rvalid,
               m_axi_mm2s_rready          => iaxiReadMasters.rready,
               m_axis_mm2s_tdata          => intMasters_tData,
               m_axis_mm2s_tkeep          => intMasters_tKeep,
               m_axis_mm2s_tlast          => intMasters_tLast,
               m_axis_mm2s_tvalid         => intMasters_tValid,
               m_axis_mm2s_tready         => intSlaves .tReady,
               m_axi_s2mm_aclk            => axiClk,
               m_axi_s2mm_aresetn         => usrRstN,
               s2mm_err                   => s2mm_err,
               m_axis_s2mm_cmdsts_awclk   => axiClk,
               m_axis_s2mm_cmdsts_aresetn => usrRstN,
               s_axis_s2mm_cmd_tvalid     => r.writeMasters.tValid,
               s_axis_s2mm_cmd_tready     => intDscWriteSlaves.command.tReady,
               s_axis_s2mm_cmd_tdata      => r.writeMasters.tData(79 DOWNTO 0),
               m_axis_s2mm_sts_tvalid     => intDscWriteSlaves .status.tValid,
               m_axis_s2mm_sts_tready     => intDscWriteMasters.status.tReady,
               m_axis_s2mm_sts_tdata      => intDscWriteSlaves .status.tData(7 DOWNTO 0),
               m_axis_s2mm_sts_tkeep      => intDscWriteSlaves .status.tKeep(0 DOWNTO 0),
               m_axis_s2mm_sts_tlast      => intDscWriteSlaves .status.tLast,
--                 m_axi_s2mm_awid            => iaxiWriteMasters.awid(3 downto 0),
               m_axi_s2mm_awaddr          => iaxiWriteMasters.awaddr(37 downto 0),
               m_axi_s2mm_awlen           => iaxiWriteMasters.awlen,
               m_axi_s2mm_awsize          => iaxiWriteMasters.awsize,
               m_axi_s2mm_awburst         => iaxiWriteMasters.awburst,
               m_axi_s2mm_awprot          => iaxiWriteMasters.awprot,
               m_axi_s2mm_awcache         => iaxiWriteMasters.awcache,
--                 m_axi_s2mm_awuser          => iaxiWriteMasters(i).awuser,
               m_axi_s2mm_awvalid         => iaxiWriteMasters.awvalid,
               m_axi_s2mm_awready         => iaxiWriteSlaves .awready,
               m_axi_s2mm_wdata           => iaxiWriteMasters.wdata(255 downto 0),
               m_axi_s2mm_wstrb           => iaxiWriteMasters.wstrb( 31 downto 0),
               m_axi_s2mm_wlast           => iaxiWriteMasters.wlast,
               m_axi_s2mm_wvalid          => iaxiWriteMasters.wvalid,
               m_axi_s2mm_wready          => iaxiWriteSlaves .wready,
               m_axi_s2mm_bresp           => iaxiWriteSlaves .bresp,
               m_axi_s2mm_bvalid          => iaxiWriteSlaves .bvalid,
               m_axi_s2mm_bready          => iaxiWriteMasters.bready,
               s_axis_s2mm_tdata          => intMasters_tData,
               s_axis_s2mm_tkeep          => intMasters_tKeep,
               s_axis_s2mm_tlast          => intMasters_tLast,
               s_axis_s2mm_tvalid         => intMasters_tValid,
               s_axis_s2mm_tready         => intSlaves .tReady
               );

  U_WriteFifoDesc : entity work.FifoSync
    generic map ( DATA_WIDTH_G => 44,
                  ADDR_WIDTH_G => 5,
                  FWFT_EN_G    => true )
    port map ( rst        => r.usrRst(0),
               clk        => axiClk,
               wr_en      => r.wrDesc       ,
               din        => r.wrDescDin    ,
               data_count => dcountWriteDesc,
               rd_en      => rdWriteDesc    ,
               dout       => doutWriteDesc  ,
               valid      => validWriteDesc ,
               full       => fullWriteDesc  );

  monRst <= not r.monEnable or r.usrRst(0);
  U_MonMigStatus : entity work.AxisHistogram
    generic map ( ADDR_WIDTH_G => MON_MIG_STATUS_AWIDTH_C,
                  INLET_G      => true )
    port map ( clk  => axiClk,
               rst  => monRst,
               wen  => r.monSample,
               addr => migStatus.blocksFree(BLOCK_INDEX_SIZE_C-1 downto BLOCK_INDEX_SIZE_C-8),
               axisClk => axiClk,
               axisRst => axiRst,
               sPush   => r.monReadout,
               mAxisMaster => monMigStatusMaster,
               mAxisSlave  => monMigStatusSlave );

  U_WriteFifoIn : entity work.FifoSync
    generic map ( DATA_WIDTH_G => 64,
                  ADDR_WIDTH_G => 12,
                  FWFT_EN_G    => true )
    port map ( rst        => r.usrRst(0),
               clk        => axiClk,
               wr_en      => r.wrRamAddr    ,
               din        => r.fifoDin      ,
               data_count => dcountRamAddr  ,
               rd_en      => rdRamAddr      ,
               dout       => doutRamAddr    ,
               valid      => validRamAddr   );

  U_MonWriteDesc : entity work.AxisHistogram
    generic map ( ADDR_WIDTH_G => MON_WRITE_DESC_AWIDTH_C )
    port map ( clk  => axiClk,
               rst  => monRst,
               wen  => r.monSample,
               addr => dcountRamAddr(11 downto 4),
               axisClk => axiClk,
               axisRst => axiRst,
               sAxisMaster => monMigStatusMaster,
               sAxisSlave  => monMigStatusSlave ,
               mAxisMaster => monWriteDescMaster,
               mAxisSlave  => monWriteDescSlave );

  GEN_MON_AXI : entity work.MonToPcieWrapper
    port map ( axiClk          => axiClk,
               axiRst          => r.usrRst(0),
               -- AXI Stream Interface
               sAxisMaster     => monWriteDescMaster,
               sAxisSlave      => monWriteDescSlave ,
               -- AXI4 Interface to PCIe
               mAxiWriteMaster => monAxiWriteMaster,
               mAxiWriteSlave  => monAxiWriteSlave,
               -- Configuration
               enable          => r.monEnable,
               mAxiAddr        => r.monBaseAddr,
               -- Status
               ready           => monStatus(8),
               rdIndex         => monStatus(3 downto 0),
               wrIndex         => monStatus(7 downto 4) );

  comb : process ( r, axiRst, 
                   doutRamAddr  , validRamAddr  , dcountRamAddr  ,
                   doutWriteDesc, validWriteDesc, dcountWriteDesc, fullWriteDesc,
                   intDscWriteSlaves, raxiWriteSlave,
                   dscReadMasters, intDscReadSlaves,
                   intDscWriteMasters, intDscWriteSlaves,
                   migStatus, monStatus, s2mm_err, mm2s_err,
                   sAxilWriteMaster, sAxilReadMaster ) is
    variable v : RegType;
    variable regCon : AxiLiteEndPointType;
    variable regAddr : slv(11 downto 0);
    variable regRst  : sl;
    variable i, app  : integer;
    variable wdata   : slv(63 downto 0);
    variable wbusy   : sl;
    variable tready  : sl;
  begin
    v := r;

    --  Reset strobing signals
    v.rdRamAddr   := '0';
    v.wrDesc      := '0';
    v.wrRamAddr   := '0';
    v.rdDesc      := '0';
    v.readSlaves  := AXI_STREAM_SLAVE_INIT_C;
    v.writeSlaves := AXI_STREAM_SLAVE_INIT_C;
    
    -- Start transaction block
    axiSlaveWaitTxn(regCon, sAxilWriteMaster, sAxilReadMaster, v.axilWriteSlave, v.axilReadSlave);

    regAddr := toSlv(0,12);
    axiSlaveRegisterR(regCon, regAddr, 0, toSlv(1,4));
    axiSlaveRegisterR(regCon, regAddr, 4, toSlv(1,4));
    axiSlaveRegisterR(regCon, regAddr, 8, toSlv(MON_MIG_STATUS_AWIDTH_C,4));
    axiSlaveRegisterR(regCon, regAddr, 12, toSlv(MON_WRITE_DESC_AWIDTH_C,4));
    regAddr := regAddr + 4;
    regRst  := '0';
    axiWrDetect(regCon, regAddr, regRst);
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 0, v.monSampleInt);
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 0, v.monReadoutInt);
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 0, v.monEnable );
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 0, v.monBaseAddr(31 downto  0));
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 0, v.monBaseAddr(39 downto 32));
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, v.monSampleCnt);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, v.monReadoutCnt);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, monStatus);

    -- Loop over applications
    --
    --   Push DMA addresses to the FIFOs associated with each application
    regAddr := toSlv(128, 12);
    axiSlaveRegister(regCon, regAddr, 0, v.wrBaseAddr(31 downto  0));
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 0, v.wrBaseAddr(39 downto 32));
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 0, v.fifoDin(31 downto 0));
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 0, v.fifoDin(63 downto 32));
    axiWrDetect     (regCon, regAddr, v.wrRamAddr);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, dcountRamAddr);
    axiSlaveRegisterR(regCon, regAddr,16, dcountWriteDesc);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, r.wrIndex);
    regAddr := regAddr + 4;
    axiSlaveRegister (regCon, regAddr, 0, v.autoFill);

    regAddr := toSlv(256,12);
--        axiSlaveRegister(regCon, regAddr, 0, v.app(i));
    v.migConfig.inhibit := '0';
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 0, v.migConfig.blockSize);
    regAddr := regAddr + 4;
    axiSlaveRegister(regCon, regAddr, 8, v.migConfig.blocksPause);
    regAddr := regAddr + 12;
    tready := validRamAddr;
    wbusy  := r.writeMasters.tValid and not intDscWriteSlaves.command.tReady;
    axiSlaveRegisterR(regCon, regAddr, 0, migStatus.blocksFree);
    axiSlaveRegisterR(regCon, regAddr,12, migStatus.blocksQueued);
    axiSlaveRegisterR(regCon, regAddr,24, r.axiBusy);
    axiSlaveRegisterR(regCon, regAddr,25, tready);
    axiSlaveRegisterR(regCon, regAddr,26, wbusy);
    axiSlaveRegisterR(regCon, regAddr,27, migStatus.writeSlaveBusy);
    axiSlaveRegisterR(regCon, regAddr,28, migStatus.readMasterBusy);
    axiSlaveRegisterR(regCon, regAddr,29, mm2s_err);
    axiSlaveRegisterR(regCon, regAddr,30, s2mm_err);
    axiSlaveRegisterR(regCon, regAddr,31, migStatus.memReady);
    regAddr := regAddr + 4;
    axiSlaveRegisterR(regCon, regAddr, 0, migStatus.writeQueCnt);
    axiSlaveRegisterR(regCon, regAddr, 8, r.readQueCnt );
    axiSlaveRegisterR(regCon, regAddr,16, r.writeQueCnt);
    axiSlaveRegisterR(regCon, regAddr,24, r.descQueCnt );

    -- End transaction block
    axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

    sAxilWriteSlave <= r.axilWriteSlave;
    sAxilReadSlave  <= r.axilReadSlave;

    if regRst = '1' then
      v.usrRst := REG_INIT_C.usrRst;
    else
      v.usrRst := '0' & r.usrRst(r.usrRst'left downto 1);
    end if;

    -- Loop over lanes
    v.axiWriteMaster.bready := '1';

    if intDscReadSlaves .command.tReady = '1' then
      v.readMasters .tValid := '0';
    end if;
    
    if intDscWriteSlaves.command.tReady = '1' then
      v.writeMasters.tValid := '0';
    end if;
    
    --  statistics
    if (r.readMasters.tValid='1' and
        intDscReadSlaves .command.tReady='1') then
      v.readQueCnt := v.readQueCnt+1;
    end if;
    if (dscReadMasters.status.tReady='1' and
        intDscReadSlaves .status.tValid='1') then
      v.readQueCnt := v.readQueCnt-1;
    end if;
    if (intDscWriteMasters.command.tValid='1' and
        intDscWriteSlaves .command.tReady='1') then
      v.writeQueCnt := v.writeQueCnt+1;
    end if;
    if (intDscWriteMasters.status.tReady='1' and
        intDscWriteSlaves .status.tValid='1') then
      v.writeQueCnt := v.writeQueCnt-1;
    end if;
    if (r.axiWriteMaster.awvalid='1' and
        raxiWriteSlave  .awready='1') then
      v.descQueCnt := v.descQueCnt+1;
    end if;
    if (v.axiWriteMaster.bready='1' and
        raxiWriteSlave  .bvalid='1') then
      v.descQueCnt := v.descQueCnt-1;
    end if;

    --   Queue the write address to the data mover engine when a new
    --   transfer is waiting and a target buffer is available.
    if (dscReadMasters.command.tValid = '1') then
      --  Dump packets when no app is receiving
      --  (but still assert FULL)
      if (v.writeMasters.tValid = '0' and
          v.readMasters .tValid = '0' and
          validRamAddr = '1' and
          fullWriteDesc  = '0') then
        v.readSlaves  .tReady := '1';
        v.readMasters .tValid := '1';
        v.writeMasters.tValid := '1';
        v.readMasters .tData  := dscReadMasters.command.tData;
        v.writeMasters.tData  := dscReadMasters.command.tData;
        v.writeMasters.tData(79 downto 32) := x"0" & toSlv(0,4) &
                                              doutRamAddr(39 downto 0);
        v.rdRamAddr := '1';
        v.wrDescDin(43 downto 20) := '0' & dscReadMasters.command.tData(22 downto 0);
        v.wrDescDin(19 downto  0) := doutRamAddr(59 downto 40);
        v.wrDesc    := '1';

        if r.autoFill = '1' then
          v.fifoDin   := doutRamAddr;
          v.wrRamAddr := '1';
        end if;
      end if;
    end if;

    --  Reset strobing signals
    if raxiWriteSlave.awready = '1' then
      v.axiWriteMaster.awvalid := '0';
    end if;

    if raxiWriteSlave.wready = '1' then
      v.axiWriteMaster.wvalid  := '0';
      v.axiWriteMaster.wlast   := '0';
    end if;

    if raxiWriteSlave  .bvalid = '1' then
      v.axiBusy := '0';
    end if;
    
    --  Translate the write status to a descriptor axi write
    if r.axiBusy = '0' then
      if (intDscWriteSlaves.status.tValid = '1' and
          validWriteDesc = '1') then
        -- Write address channel
        v.axiWriteMaster.awaddr := r.wrBaseAddr + (r.wrIndex & "000");
        v.axiWriteMaster.awlen  := x"00";  -- Single transaction
        v.axiWriteMaster.awsize := toSlv(5,3); -- 32 byte bus

        -- Write data channel
        v.axiWriteMaster.wlast := '1';
        case (r.wrIndex(1 downto 0)) is
          when "00" =>
            v.axiWriteMaster.wstrb := resize(x"000000FF", 128);
          when "01" =>
            v.axiWriteMaster.wstrb := resize(x"0000FF00", 128);
          when "10" =>
            v.axiWriteMaster.wstrb := resize(x"00FF0000", 128);
          when "11" =>
            v.axiWriteMaster.wstrb := resize(x"FF000000", 128);
        end case;
        
        -- Descriptor data
        wdata(63 downto 56) := toSlv(0,3) & toSlv(0,5); -- vc
        wdata(55 downto 32) := doutWriteDesc(43 downto 20);
        wdata(31 downto 28) := toSlv(0,4); -- firstUser
        wdata(27 downto 24) := toSlv(0,4); -- lastUser
        wdata(23 downto 4)  := doutWriteDesc(19 downto 0);
        wdata(3)            := '0'; -- continue
        wdata(2 downto 0)   := intDscWriteSlaves.status.tData(6 downto 4);

        v.axiWriteMaster.wdata(255 downto 192) := wdata;
        v.axiWriteMaster.wdata(191 downto 128) := wdata;
        v.axiWriteMaster.wdata(127 downto  64) := wdata;
        v.axiWriteMaster.wdata( 63 downto   0) := wdata;
        
        v.axiWriteMaster.awvalid := '1';
        v.axiWriteMaster.awcache := x"3";
        v.axiWriteMaster.awburst := "01";
        v.axiWriteMaster.wvalid  := '1';
        v.wrIndex                := r.wrIndex + 1;
        v.axiBusy                := '1';
        v.rdDesc                 := '1';
        v.writeSlaves.tReady     := '1';
      end if;
    end if;

    v.monSample  := '0';
    v.monReadout := '0';

    if r.monEnable = '1' then
      if r.monSampleCnt = r.monSampleInt then
        v.monSample    := '1';
        v.monSampleCnt := (others=>'0');
      else
        v.monSampleCnt := r.monSampleCnt + 1;
      end if;
      if r.monSample = '1' then
        if r.monReadoutCnt = r.monReadoutInt then
          v.monReadout    := '1';
          v.monReadoutCnt := (others=>'0');
        else
          v.monReadoutCnt := r.monReadoutCnt + 1;
        end if;
      end if;
    else
      v.monSampleCnt  := (others=>'0');
      v.monReadoutCnt := (others=>'0');
    end if;

    --
    --  Assign these before the reset processing
    --
    intDscReadMasters          <= dscReadMasters;
    intDscReadMasters .command <= r.readMasters ;
    dscReadSlaves              <= intDscReadSlaves;
    dscReadSlaves     .command <= v.readSlaves  ;
    intDscWriteMasters.command <= r.writeMasters;
    intDscWriteMasters.status  <= v.writeSlaves ;

    rdRamAddr   <= v.rdRamAddr;
    rdWriteDesc <= v.rdDesc;

    if axiRst = '1' then
      v := REG_INIT_C;
    end if;

    if r.usrRst(0) = '1' then
      v.monEnable := '0';
      v.wrIndex   := (others=>'0');
    end if;
    
    rin <= v;

    migConfig <= r.migConfig;
    
  end process comb;

  seq: process(axiClk) is
  begin
    if rising_edge(axiClk) then
      r <= rin;
    end if;
  end process seq;
  
  
end mapping;



