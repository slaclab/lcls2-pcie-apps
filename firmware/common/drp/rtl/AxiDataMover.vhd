-------------------------------------------------------------------------------
-- File       : AxiDataMover.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-10-13
-------------------------------------------------------------------------------
-- Description: Wrapper for Xilinx Axi Data Mover
-- Axi stream input (dscReadMasters.command) launches an AxiReadMaster to
-- read from a memory mapped device and write to another memory mapped device
-- with an AxiWriteMaster to a start address given by the AxiLite bus register
-- writes.  Completion of the transfer results in another axi write.
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

entity AxiDataMover is
   generic (  LANES_G          : integer          := 4;
              NAPP_G           : integer          := 1;
              AXIL_BASE_ADDR_G : slv(31 downto 0) := x"00000000";
              AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C );
   port    ( -- Clock and reset
             axiClk           : in  sl; -- 200MHz
             axiRst           : in  sl; -- need a user reset to clear the pipeline
             -- AXI4 Interfaces to MIG
             axiReadMasters   : out AxiReadMasterArray(LANES_G-1 downto 0);
             axiReadSlaves    : in  AxiReadSlaveArray (LANES_G-1 downto 0);
             -- AxiStream Interfaces from MIG (Data Mover command)
             dscReadMasters   : in  AxiDescMasterArray(LANES_G-1 downto 0);
             dscReadSlaves    : out AxiDescSlaveArray (LANES_G-1 downto 0);
             -- AXI4 Interface to PCIe
             axiWriteMasters  : out AxiWriteMasterArray(LANES_G downto 0);
             axiWriteSlaves   : in  AxiWriteSlaveArray (LANES_G downto 0);
             -- AXI Lite Interface
             axilClk          : in  sl;
             axilRst          : in  sl;
             axilWriteMaster  : in  AxiLiteWriteMasterType;
             axilWriteSlave   : out AxiLiteWriteSlaveType;
             axilReadMaster   : in  AxiLiteReadMasterType;
             axilReadSlave    : out AxiLiteReadSlaveType );
end AxiDataMover;

architecture mapping of AxiDataMover is

  COMPONENT MigToPcie
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
      m_axi_mm2s_arid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
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
      m_axis_mm2s_tdata : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
      m_axis_mm2s_tkeep : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
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
      m_axi_s2mm_awid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_s2mm_awaddr : OUT STD_LOGIC_VECTOR(37 DOWNTO 0);
      m_axi_s2mm_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_s2mm_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_s2mm_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_s2mm_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_s2mm_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_s2mm_awuser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_s2mm_awvalid : OUT STD_LOGIC;
      m_axi_s2mm_awready : IN STD_LOGIC;
      m_axi_s2mm_wdata : OUT STD_LOGIC_VECTOR(511 DOWNTO 0);
      m_axi_s2mm_wstrb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axi_s2mm_wlast : OUT STD_LOGIC;
      m_axi_s2mm_wvalid : OUT STD_LOGIC;
      m_axi_s2mm_wready : IN STD_LOGIC;
      m_axi_s2mm_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_s2mm_bvalid : IN STD_LOGIC;
      m_axi_s2mm_bready : OUT STD_LOGIC;
      s_axis_s2mm_tdata : IN STD_LOGIC_VECTOR(511 DOWNTO 0);
      s_axis_s2mm_tkeep : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      s_axis_s2mm_tlast : IN STD_LOGIC;
      s_axis_s2mm_tvalid : IN STD_LOGIC;
      s_axis_s2mm_tready : OUT STD_LOGIC
      );
  END COMPONENT;

  type Slv512Array is array (natural range <>) of slv(511 downto 0);

  signal axiRstN : sl;
  
  --  Assumes 40b memory addresses
  signal intDscReadMasters  : AxiDescMasterArray(LANES_G-1 downto 0);
  signal intDscReadSlaves   : AxiDescSlaveArray (LANES_G-1 downto 0);
  signal intDscWriteMasters : AxiDescMasterArray(LANES_G-1 downto 0);
  signal intDscWriteSlaves  : AxiDescSlaveArray (LANES_G-1 downto 0);

  signal intMasters       : AxiStreamMasterArray(LANES_G-1 downto 0);
  signal intSlaves        : AxiStreamSlaveArray (LANES_G-1 downto 0);
  signal intMasters_tdata : Slv512Array         (LANES_G-1 downto 0);
  signal intMasters_tkeep : Slv64Array          (LANES_G-1 downto 0);

  signal dinTransfer    : Slv23Array(LANES_G-1 downto 0);
  signal doutTransfer   : Slv23Array(LANES_G-1 downto 0);
  signal dcountTransfer : Slv4Array (LANES_G-1 downto 0);
  signal rdTransfer     : slv       (LANES_G-1 downto 0);
  signal validTransfer  : slv       (LANES_G-1 downto 0);
  signal fullTransfer   : slv       (LANES_G-1 downto 0);
  signal wrTransfer     : slv       (LANES_G-1 downto 0);

  --  Assumes 16b buffer ids
  constant NAPP_C : integer := NAPP_G;
  signal addrRamAddr    : Slv12Array(NAPP_C-1 downto 0);
  signal dcountRamAddr  : Slv12Array(NAPP_C-1 downto 0);
  signal rdRamAddr      : slv       (NAPP_C-1 downto 0);
  signal validRamAddr   : slv       (NAPP_C-1 downto 0);
  signal doutRamAddr    : Slv40Array(NAPP_C-1 downto 0);
  signal doutWriteDesc  : Slv36Array(NAPP_C-1 downto 0);
  signal dcountWriteDesc: Slv4Array (NAPP_C-1 downto 0);
  signal rdWriteDesc    : slv       (NAPP_C-1 downto 0);
  signal validWriteDesc : slv       (NAPP_C-1 downto 0);
  
  constant NUM_AXIL_MASTERS_C : integer := NAPP_C+1;
  signal sAxilReadMaster  : AxiLiteReadMasterType;
  signal sAxilReadSlave   : AxiLiteReadSlaveType;
  signal sAxilWriteMaster : AxiLiteWriteMasterType;
  signal sAxilWriteSlave  : AxiLiteWriteSlaveType;
  signal axilReadMasters  : AxiLiteReadMasterArray (NUM_AXIL_MASTERS_C-1 downto 0);
  signal axilReadSlaves   : AxiLiteReadSlaveArray  (NUM_AXIL_MASTERS_C-1 downto 0);
  signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
  signal axilWriteSlaves  : AxiLiteWriteSlaveArray (NUM_AXIL_MASTERS_C-1 downto 0);
  constant AXIL_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig( NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 18, 15);
  
  type RegType is record
    axilWriteSlave : AxiLiteWriteSlaveType;
    axilReadSlave  : AxiLiteReadSlaveType;
    fifoDin        : slv(15 downto 0);
    wrFifoWr       : slv                 (NAPP_C-1 downto 0);
    rdTransfer     : slv                 (NAPP_C-1 downto 0);
    rdRamAddr      : slv                 (NAPP_C-1 downto 0);
    wrDesc         : slv                 (NAPP_C-1 downto 0);
    wrDescDin      : slv                 (35 downto 0);
    rdDesc         : slv                 (NAPP_C-1 downto 0);
    laneGate       : integer range 0 to NAPP_C-1; 
    app            : Slv4Array           (LANES_G-1 downto 0);
    writeMasters   : AxiStreamMasterArray(LANES_G-1 downto 0); -- command stream
    writeSlaves    : AxiStreamSlaveArray (LANES_G-1 downto 0); -- status stream
    wrBaseAddr     : Slv64Array          (NAPP_C-1 downto 0);
    wrIndex        : Slv12Array          (NAPP_C-1 downto 0);
    axiBusy        : sl;
    axiWriteMaster : AxiWriteMasterType;
  end record;

  constant REG_INIT_C : RegType := (
    axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
    axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
    fifoDin        => (others=>'0'),
    wrFifoWr       => (others=>'0'),
    rdTransfer     => (others=>'0'),
    rdRamAddr      => (others=>'0'),
    wrDesc         => (others=>'0'),
    wrDescDin      => (others=>'0'),
    rdDesc         => (others=>'0'),
    laneGate       => 0,
    app            => (others=>(others=>'1')),
    writeMasters   => (others=>axiStreamMasterInit(DESC_STREAM_CONFIG_INIT_C)),
    writeSlaves    => (others=>AXI_STREAM_SLAVE_INIT_C),
    wrBaseAddr     => (others=>(others=>'0')),
    wrIndex        => (others=>(others=>'0')),
    axiBusy        => '0',
    axiWriteMaster => AXI_WRITE_MASTER_INIT_C );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;
  
begin

  axiRstN                  <= not axiRst;
  axiWriteMasters(LANES_G) <= r.axiWriteMaster;

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

  U_AxilCrossbar : entity work.AxiLiteCrossbar
    generic map ( NUM_SLAVE_SLOTS_G  => 1,
                  NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
                  MASTERS_CONFIG_G   => AXIL_CROSSBAR_MASTERS_CONFIG_C )
    port map    ( axiClk        => axiClk,
                  axiClkRst     => axiRst,
                  sAxiWriteMasters(0) => sAxilWriteMaster,
                  sAxiWriteSlaves (0) => sAxilWriteSlave,
                  sAxiReadMasters (0) => sAxilReadMaster,
                  sAxiReadSlaves  (0) => sAxilReadSlave,
                  mAxiWriteMasters    => axilWriteMasters,
                  mAxiWriteSlaves     => axilWriteSlaves,
                  mAxiReadMasters     => axilReadMasters,
                  mAxiReadSlaves      => axilReadSlaves );
  
  GEN_CHAN : for i in 0 to LANES_G-1 generate

    U_ADM : MigToPcie
      port map ( m_axi_mm2s_aclk            => axiClk,
                 m_axi_mm2s_aresetn         => axiRstN,
                 mm2s_err                   => open,
                 m_axis_mm2s_cmdsts_aclk    => axiClk,
                 m_axis_mm2s_cmdsts_aresetn => axiRstN,
                 s_axis_mm2s_cmd_tvalid     => intDscReadMasters(i).command.tValid,
                 s_axis_mm2s_cmd_tready     => intDscReadSlaves(i).command .tReady,
                 s_axis_mm2s_cmd_tdata      => intDscReadMasters(i).command.tData(79 DOWNTO 0),
                 m_axis_mm2s_sts_tvalid     => intDscReadSlaves(i) .status.tValid,
                 m_axis_mm2s_sts_tready     => intDscReadMasters(i).status.tReady,
                 m_axis_mm2s_sts_tdata      => intDscReadSlaves(i).status.tData(7 DOWNTO 0),
                 m_axis_mm2s_sts_tkeep      => intDscReadSlaves(i).status.tKeep(0 DOWNTO 0),
                 m_axis_mm2s_sts_tlast      => intDscReadSlaves(i).status.tLast,
                 m_axi_mm2s_arid            => axiReadMasters(i).arid(3 downto 0),
                 m_axi_mm2s_araddr          => axiReadMasters(i).araddr(37 downto 0),
                 m_axi_mm2s_arlen           => axiReadMasters(i).arlen,
                 m_axi_mm2s_arsize          => axiReadMasters(i).arsize,
                 m_axi_mm2s_arburst         => axiReadMasters(i).arburst,
                 m_axi_mm2s_arprot          => axiReadMasters(i).arprot,
                 m_axi_mm2s_arcache         => axiReadMasters(i).arcache,
--                 m_axi_mm2s_aruser          => axiReadMasters(i).aruser,
                 m_axi_mm2s_arvalid         => axiReadMasters(i).arvalid,
                 m_axi_mm2s_arready         => axiReadSlaves(i) .arready,
                 m_axi_mm2s_rdata           => axiReadSlaves(i) .rdata(511 downto 0),
                 m_axi_mm2s_rresp           => axiReadSlaves(i) .rresp,
                 m_axi_mm2s_rlast           => axiReadSlaves(i) .rlast,
                 m_axi_mm2s_rvalid          => axiReadSlaves(i) .rvalid,
                 m_axi_mm2s_rready          => axiReadMasters(i).rready,
                 m_axis_mm2s_tdata          => intMasters_tdata(i)(511 downto 0),
                 m_axis_mm2s_tkeep          => intMasters_tkeep(i),
                 m_axis_mm2s_tlast          => intMasters(i).tLast,
                 m_axis_mm2s_tvalid         => intMasters(i).tValid,
                 m_axis_mm2s_tready         => intSlaves(i) .tReady,
                 m_axi_s2mm_aclk            => axiClk,
                 m_axi_s2mm_aresetn         => axiRstN,
                 s2mm_err                   => open,
                 m_axis_s2mm_cmdsts_awclk   => axiClk,
                 m_axis_s2mm_cmdsts_aresetn => axiRstN,
                 s_axis_s2mm_cmd_tvalid     => r.writeMasters(i).tValid,
                 s_axis_s2mm_cmd_tready     => intDscWriteSlaves(i).command.tReady,
                 s_axis_s2mm_cmd_tdata      => r.writeMasters(i).tData(79 DOWNTO 0),
                 m_axis_s2mm_sts_tvalid     => intDscWriteSlaves(i) .status.tValid,
                 m_axis_s2mm_sts_tready     => intDscWriteMasters(i).status.tReady,
                 m_axis_s2mm_sts_tdata      => intDscWriteSlaves(i) .status.tData(7 DOWNTO 0),
                 m_axis_s2mm_sts_tkeep      => intDscWriteSlaves(i) .status.tKeep(0 DOWNTO 0),
                 m_axis_s2mm_sts_tlast      => intDscWriteSlaves(i) .status.tLast,
                 m_axi_s2mm_awid            => axiWriteMasters(i).awid(3 downto 0),
                 m_axi_s2mm_awaddr          => axiWriteMasters(i).awaddr(37 downto 0),
                 m_axi_s2mm_awlen           => axiWriteMasters(i).awlen,
                 m_axi_s2mm_awsize          => axiWriteMasters(i).awsize,
                 m_axi_s2mm_awburst         => axiWriteMasters(i).awburst,
                 m_axi_s2mm_awprot          => axiWriteMasters(i).awprot,
                 m_axi_s2mm_awcache         => axiWriteMasters(i).awcache,
--                 m_axi_s2mm_awuser          => axiWriteMasters(i).awuser,
                 m_axi_s2mm_awvalid         => axiWriteMasters(i).awvalid,
                 m_axi_s2mm_awready         => axiWriteSlaves(i) .awready,
                 m_axi_s2mm_wdata           => axiWriteMasters(i).wdata(511 downto 0),
                 m_axi_s2mm_wstrb           => axiWriteMasters(i).wstrb(63 downto 0),
                 m_axi_s2mm_wlast           => axiWriteMasters(i).wlast,
                 m_axi_s2mm_wvalid          => axiWriteMasters(i).wvalid,
                 m_axi_s2mm_wready          => axiWriteSlaves(i) .wready,
                 m_axi_s2mm_bresp           => axiWriteSlaves(i) .bresp,
                 m_axi_s2mm_bvalid          => axiWriteSlaves(i) .bvalid,
                 m_axi_s2mm_bready          => axiWriteMasters(i).bready,
                 s_axis_s2mm_tdata          => intMasters_tdata(i),
                 s_axis_s2mm_tkeep          => intMasters_tkeep(i),
                 s_axis_s2mm_tlast          => intMasters(i).tLast,
                 s_axis_s2mm_tvalid         => intMasters(i).tValid,
                 s_axis_s2mm_tready         => intSlaves(i) .tReady
                 );
    --
    --  Keep a (small) FIFO of transfer lengths to attach to write commands
    --

    process ( dscReadMasters, intDscReadSlaves, fullTransfer ) is
    begin
      intDscReadMasters(i)                <= dscReadMasters(i);
      intDscReadMasters(i).command.tValid <= dscReadMasters(i).command.tValid and not fullTransfer(i);
      dscReadSlaves    (i)                <= intDscReadSlaves(i);
    end process;
    
    wrTransfer (i) <= intDscReadMasters(i).command.tValid and intDscReadSlaves(i).command.tReady;
    dinTransfer(i) <= dscReadMasters(i).command.tData(22 downto 0);
    
    U_TransferFifo : entity work.FifoSync
      generic map ( DATA_WIDTH_G => 23,
                    ADDR_WIDTH_G =>  4,
                    FWFT_EN_G    => true )
      port map ( rst        => axiRst,
                 clk        => axiClk,
                 wr_en      => wrTransfer    (i),
                 din        => dinTransfer   (i),
                 data_count => dcountTransfer(i),
                 rd_en      => rdTransfer    (i),
                 dout       => doutTransfer  (i),
                 valid      => validTransfer (i),
                 full       => fullTransfer  (i));
  end generate;

  GEN_APP : for i in 0 to NAPP_C-1 generate
    U_WrAddrRam : entity work.AxiDualPortRam
      generic map ( REG_EN_G     => true,
                    BRAM_EN_G    => true,
                    AXI_WR_EN_G  => true,
                    COMMON_CLK_G => true,
                    ADDR_WIDTH_G => 12,
                    DATA_WIDTH_G => 40)
      port map (
        axiClk         => axiClk,
        axiRst         => axiRst,
        axiReadMaster  => axilReadMasters (i+1),
        axiReadSlave   => axilReadSlaves  (i+1),
        axiWriteMaster => axilWriteMasters(i+1),
        axiWriteSlave  => axilWriteSlaves (i+1),
        clk            => axiClk,
        rst            => axiRst,
        addr           => addrRamAddr(i),
        dout           => doutRamAddr(i) );
    
    -- For receive
    U_WriteFifoIn : entity work.FifoSync
      generic map ( DATA_WIDTH_G => 12,
                    ADDR_WIDTH_G => 12,
                    FWFT_EN_G    => true )
      port map ( rst        => axiRst,
                 clk        => axiClk,
                 wr_en      => r.wrFifoWr     (i),
                 din        => r.fifoDin      (11 downto 0),
                 data_count => dcountRamAddr  (i),
                 rd_en      => rdRamAddr      (i),
                 dout       => addrRamAddr    (i),
                 valid      => validRamAddr   (i) );

    U_WriteFifoDesc : entity work.FifoSync
      generic map ( DATA_WIDTH_G => 36,
                    ADDR_WIDTH_G => 4,
                    FWFT_EN_G    => true )
      port map ( rst        => axiRst,
                 clk        => axiClk,
                 wr_en      => r.wrDesc       (i),
                 din        => r.wrDescDin,
                 data_count => dcountWriteDesc(i),
                 rd_en      => rdWriteDesc    (i),
                 dout       => doutWriteDesc  (i),
                 valid      => validWriteDesc (i));
  end generate;

  rdTransfer  <= rin.rdTransfer;
  rdRamAddr   <= rin.rdRamAddr;
  rdWriteDesc <= rin.rdDesc;

  GEN_DESC_WRITE_MASTERS : for i in 0 to LANES_G-1 generate
    intDscWriteMasters(i).command <= r.writeMasters(i);
    intDscWriteMasters(i).status  <= rin.writeSlaves(i);
  end generate;
      
  comb : process ( r, axiRst, 
                   doutTransfer , validTransfer , dcountTransfer ,
                   doutRamAddr  , validRamAddr  , dcountRamAddr  ,
                   doutWriteDesc, validWriteDesc, dcountWriteDesc,
                   intDscWriteSlaves, axiWriteSlaves,
                   axilWriteMasters, axilReadMasters ) is
      variable v : RegType;
      variable regCon : AxiLiteEndPointType;
      variable regAddr : slv(11 downto 0);
      variable i, app  : integer;
    begin
      v := r;

      v.rdTransfer  := (others=>'0');
      v.rdRamAddr   := (others=>'0');
      v.wrDesc      := (others=>'0');
      v.wrFifoWr    := (others=>'0');
      v.rdDesc      := (others=>'0');
      v.axiWriteMaster.bready := '1';
      
       -- Start transaction block
      axiSlaveWaitTxn(regCon, axilWriteMasters(0), axilReadMasters(0), v.axilWriteSlave, v.axilReadSlave);

      -- Loop over applications
      --
      --   Push DMA addresses to the FIFOs associated with each application
      for i in 0 to NAPP_C-1 loop
        regAddr := toSlv(i*16, 12);
        axiSlaveRegister(regCon, regAddr, 0, v.wrBaseAddr(i)(31 downto  0));
        regAddr := regAddr + 4;
        axiSlaveRegister(regCon, regAddr, 0, v.wrBaseAddr(i)(39 downto 32));
        regAddr := regAddr + 4;
        axiSlaveRegister(regCon, regAddr, 0, v.fifoDin);
        axiWrDetect     (regCon, regAddr, v.wrFifoWr(i));
        regAddr := regAddr + 4;
        axiSlaveRegisterR(regCon, regAddr, 0, dcountRamAddr(i));
        axiSlaveRegisterR(regCon, regAddr,16, dcountWriteDesc(i));
      end loop;

      for i in 0 to LANES_G-1 loop
        regAddr := toSlv(128+i*8,12);
        axiSlaveRegister(regCon, regAddr, 0, v.app(i));
        regAddr := regAddr + 4;
        axiSlaveRegisterR(regCon, regAddr, 0, dcountTransfer (i));
      end loop;
      
      -- End transaction block
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      axilWriteSlaves(0) <= r.axilWriteSlave;
      axilReadSlaves (0) <= r.axilReadSlave;

      -- Loop over lanes
      for i in 0 to LANES_G-1 loop
        if intDscWriteSlaves(i).command.tReady = '1' then
          v.writeMasters(i).tValid := '0';
        end if;
        if r.writeSlaves(i).tReady = '1' then
          v.writeSlaves(i).tReady := '0';
        end if;
      end loop;

      --   Serialize access to the application FIFOs
      --  Allocate each clock to one lane's arbitration
      i          := r.laneGate;
      app        := conv_integer(r.app(i));
      if r.laneGate = NAPP_C-1 then
        v.laneGate := 0;
      else
        v.laneGate := r.laneGate+1;
      end if;

      --   Queue the write address to the data mover engine when a new
      --   transfer is waiting and a target buffer is available.
      if (v.writeMasters(i).tValid = '0' and
          validTransfer(i) = '1' and
          validRamAddr(app) = '1' and
          app < NAPP_C) then
        v.writeMasters(i).tValid := '1';
        v.writeMasters(i).tLast  := '1';
        v.writeMasters(i).tData(79 downto 0) := x"0" & toSlv(app,4) &
                                                doutRamAddr(app) &
                                                "01" & toSlv(0,6) &
                                                '1' & doutTransfer(i);
        v.rdTransfer(i) := '1';
        v.rdRamAddr(app) := '1';
        v.wrDescDin(35 downto 12) := '0' & doutTransfer(i);
        v.wrDescDin(11 downto  0) := addrRamAddr(app);
        v.wrDesc(app) := '1';
      end if;

      --  Reset strobing signals
      if axiWriteSlaves(LANES_G).awready = '1' then
        v.axiWriteMaster.awvalid := '0';
      end if;

      if axiWriteSlaves(LANES_G).wready = '1' then
        v.axiWriteMaster.wvalid  := '0';
        v.axiWriteMaster.wlast   := '0';
      end if;

      --  Translate the write status to a descriptor axi write
      if r.axiBusy = '0' then
        if (intDscWriteSlaves(i).status.tValid = '1' and
            validWriteDesc(app) = '1') then
          -- Write address channel
          v.axiWriteMaster.awaddr := r.wrBaseAddr(app) + (r.wrIndex(app) & "000");
          v.axiWriteMaster.awlen  := x"00";  -- Single transaction

          -- Write data channel
          v.axiWriteMaster.wlast := '1';
          v.axiWriteMaster.wstrb := resize(x"FF", 128);

          -- Descriptor data
          v.axiWriteMaster.wdata(63 downto 56) := toSlv(i,3) & toSlv(0,5); -- vc
          v.axiWriteMaster.wdata(55 downto 32) := doutWriteDesc(app)(35 downto 12);
          v.axiWriteMaster.wdata(31 downto 24) := toSlv(0,8); -- firstUser
          v.axiWriteMaster.wdata(23 downto 16) := toSlv(0,8); -- lastUser
          v.axiWriteMaster.wdata(15 downto 4)  := doutWriteDesc(app)(11 downto 0);
          v.axiWriteMaster.wdata(3)            := '0'; -- continue
          v.axiWriteMaster.wdata(2 downto 0)   := intDscWriteSlaves(i).status.tData(7 downto 5);

          v.axiWriteMaster.awvalid := '1';
          v.axiWriteMaster.wvalid  := '1';
          v.wrIndex(app)           := r.wrIndex(app) + 1;
          v.axiBusy                := '1';

          v.rdDesc(app)            := '1';
          v.writeSlaves(i).tReady  := '1';
        end if;
      else
        if (v.axiWriteMaster.awvalid = '0' and v.axiWriteMaster.wvalid = '0' and
            axiWriteSlaves(LANES_G).bvalid = '1') then
          v.axiBusy := '0';
        end if;
      end if;
      
      if axiRst = '1' then
        v := REG_INIT_C;
      end if;
      
      rin <= v;

    end process comb;

    seq: process(axiClk) is
    begin
      if rising_edge(axiClk) then
        r <= rin;
      end if;
    end process seq;
            
      
 end mapping;



