-------------------------------------------------------------------------------
-- File       : MonToPcieWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-10-20
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
use work.AppMigPkg.all;

entity MonToPcieWrapper is
  generic ( MAX_BYTES_C : slv(22 downto 0) := toSlv(65536,23) );
  port    ( -- Clock and reset
    axiClk           : in  sl; -- 200MHz
    axiRst           : in  sl;
    sAxisMaster      : in  AxiStreamMasterType;
    sAxisSlave       : out AxiStreamSlaveType ;
    -- AXI4 Interface to PCIe
    mAxiWriteMaster  : out AxiWriteMasterType ;
    mAxiWriteSlave   : in  AxiWriteSlaveType  ;
    -- Configuration
    enable           : in  sl;
    mAxiAddr         : in  slv(39 downto 0);
    -- Status
    ready            : out sl;
    rdIndex          : out slv(3 downto 0);
    wrIndex          : out slv(3 downto 0) );
end MonToPcieWrapper;

architecture mapping of MonToPcieWrapper is

  COMPONENT MonToPcie
    PORT (
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
      m_axis_s2mm_sts_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axis_s2mm_sts_tkeep : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
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
      m_axi_s2mm_wdata : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
      m_axi_s2mm_wstrb : OUT STD_LOGIC_VECTOR( 15 DOWNTO 0);
      m_axi_s2mm_wlast : OUT STD_LOGIC;
      m_axi_s2mm_wvalid : OUT STD_LOGIC;
      m_axi_s2mm_wready : IN STD_LOGIC;
      m_axi_s2mm_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_s2mm_bvalid : IN STD_LOGIC;
      m_axi_s2mm_bready : OUT STD_LOGIC;
      s_axis_s2mm_tdata : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
      s_axis_s2mm_tkeep : IN STD_LOGIC_VECTOR( 15 DOWNTO 0);
      s_axis_s2mm_tlast : IN STD_LOGIC;
      s_axis_s2mm_tvalid : IN STD_LOGIC;
      s_axis_s2mm_tready : OUT STD_LOGIC
      );
  END COMPONENT;

  signal intDscWriteMaster : AxiDescMasterType := AXI_DESC_MASTER_INIT_C;
  signal intDscWriteSlave  : AxiDescSlaveType  := AXI_DESC_SLAVE_INIT_C;

  signal wrTransfer   : sl;
  signal dinTransfer  : slv(22 downto 0);
  
  signal axiRstN : sl;

  constant INDEX_SIZE_C : integer := 4;
  
  type RegType is record
    idle           : sl;
    wrIndex        : slv(INDEX_SIZE_C-1 downto 0);
    rdIndex        : slv(INDEX_SIZE_C-1 downto 0);
    locMaster      : AxiDescMasterType;
  end record;

  constant REG_INIT_C : RegType := (
    idle           => '1',
    wrIndex        => (others=>'0'),
    rdIndex        => (others=>'0'),
    locMaster      => AXI_DESC_MASTER_INIT_C );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal isAxisMaster     : AxiStreamMasterType;
  signal isAxisSlave      : AxiStreamSlaveType;
  signal imAxiWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
  signal mAxisSlave  : AxiStreamSlaveType;
  signal s2mm_err : sl;

  constant SAXIS_CONFIG_C : AxiStreamConfigType := (
    TSTRB_EN_C   => false,
    TDATA_BYTES_C => 4,
    TDEST_BITS_C  => 0,
    TID_BITS_C    => 0,
    TKEEP_MODE_C  => TKEEP_NORMAL_C,
    TUSER_BITS_C  => 0,
    TUSER_MODE_C  => TUSER_NORMAL_C );
  
  constant MAXIS_CONFIG_C : AxiStreamConfigType := (
    TSTRB_EN_C   => false,
    TDATA_BYTES_C => 16,
    TDEST_BITS_C  => 0,
    TID_BITS_C    => 0,
    TKEEP_MODE_C  => TKEEP_NORMAL_C,
    TUSER_BITS_C  => 0,
    TUSER_MODE_C  => TUSER_NORMAL_C );
  
  constant DEBUG_C : boolean := false;
  
  component ila_0
    port ( clk    : in sl;
           probe0 : in slv(255 downto 0) );
  end component;
  
begin

  GEN_DEBUG : if DEBUG_C generate
    U_ILA : ila_0
      port map ( clk                   => axiClk,
                 probe0(0)             => isAxisMaster.tValid,
                 probe0(1)             => isAxisMaster.tLast,
                 probe0(33 downto 2)   => isAxisMaster.tData(31 downto 0),
                 probe0(34)            => '0',
                 probe0(35)            => mAxisSlave.tReady,
                 probe0(36)            => imAxiWriteMaster.awvalid,
                 probe0(76 downto 37)  => imAxiWriteMaster.awaddr(39 downto 0),
                 probe0(84 downto 77)   => imAxiWriteMaster.awlen,
                 probe0(87 downto 85)   => imAxiWriteMaster.awsize,
                 probe0(88)             => mAxiWriteSlave.awready,
                 probe0(89)              => imAxiWriteMaster.wvalid,
                 probe0(90)              => imAxiWriteMaster.wlast,
                 probe0(91)              => mAxiWriteSlave.wready,
                 probe0(92)              => mAxiWriteSlave.bvalid,
                 probe0(94 downto 93)    => mAxiWriteSlave.bresp,
                 probe0(95)              => imAxiWriteMaster.bready,
                 probe0(96)              => intDscWriteMaster.command.tValid,
                 probe0(176 downto 97)   => intDscWriteMaster.command.tData(79 downto 0),
                 probe0(177)             => intDscWriteMaster.command.tLast,
                 probe0(178)             => intDscWriteSlave .command.tReady,
                 probe0(179)             => intDscWriteSlave .status .tValid,
                 probe0(211 downto 180)  => intDscWriteSlave .status .tData(31 downto 0),
                 probe0(212)             => intDscWriteMaster.status .tReady,
                 probe0(213)             => s2mm_err,
                 probe0(255 downto 214)  => (others=>'0') );
  end generate;

  GEN_FIFO : entity work.AxiStreamFifo
    generic map ( SLAVE_AXI_CONFIG_G  => SAXIS_CONFIG_C,
                  MASTER_AXI_CONFIG_G => MAXIS_CONFIG_C )
    port map ( sAxisClk    => axiClk,
               sAxisRst    => axiRst,
               sAxisMaster => sAxisMaster,
               sAxisSlave  => sAxisSlave,
               mAxisClk    => axiClk,
               mAxisRst    => axiRst,
               mAxisMaster => isAxisMaster,
               mAxisSlave  => isAxisSlave );
  
  isAxisSlave                <= mAxisSlave;
  
  axiRstN                   <= not axiRst;
  mAxiWriteMaster           <= imAxiWriteMaster;

  ready   <= not r.locMaster.command.tValid;
  rdIndex <= r.rdIndex;
  wrIndex <= r.wrIndex;
  
  --
  --  Translate AxiStream to Axi using fixed size starting block addresses
  --
  U_ADM : MonToPcie
    port map ( m_axi_s2mm_aclk            => axiClk,
               m_axi_s2mm_aresetn         => axiRstN,
               s2mm_err                   => s2mm_err,
               m_axis_s2mm_cmdsts_awclk   => axiClk,
               m_axis_s2mm_cmdsts_aresetn => axiRstN,
               s_axis_s2mm_cmd_tvalid     => intDscWriteMaster.command.tValid,
               s_axis_s2mm_cmd_tready     => intDscWriteSlave .command.tReady,
               s_axis_s2mm_cmd_tdata      => intDscwriteMaster.command.tData(79 DOWNTO 0),
               m_axis_s2mm_sts_tvalid     => intDscWriteSlave .status.tValid,
               m_axis_s2mm_sts_tready     => intDscWriteMaster.status.tReady,
               m_axis_s2mm_sts_tdata      => intDscWriteSlave .status.tData(31 DOWNTO 0),
               m_axis_s2mm_sts_tkeep      => intDscWriteSlave .status.tKeep(3 DOWNTO 0),
               m_axis_s2mm_sts_tlast      => intDscWriteSlave .status.tLast,
               m_axi_s2mm_awid            => imAxiWriteMaster.awid(3 downto 0),
               m_axi_s2mm_awaddr          => imAxiWriteMaster.awaddr(37 downto 0),
               m_axi_s2mm_awlen           => imAxiWriteMaster.awlen,
               m_axi_s2mm_awsize          => imAxiWriteMaster.awsize,
               m_axi_s2mm_awburst         => imAxiWriteMaster.awburst,
               m_axi_s2mm_awprot          => imAxiWriteMaster.awprot,
               m_axi_s2mm_awcache         => imAxiWriteMaster.awcache,
--                 m_axi_s2mm_awuser          => imAxiWriteMaster.awuser,
               m_axi_s2mm_awvalid         => imAxiWriteMaster.awvalid,
               m_axi_s2mm_awready         => mAxiWriteSlave .awready,
               m_axi_s2mm_wdata           => imAxiWriteMaster.wdata(127 downto 0),
               m_axi_s2mm_wstrb           => imAxiWriteMaster.wstrb( 15 downto 0),
               m_axi_s2mm_wlast           => imAxiWriteMaster.wlast,
               m_axi_s2mm_wvalid          => imAxiWriteMaster.wvalid,
               m_axi_s2mm_wready          => mAxiWriteSlave .wready,
               m_axi_s2mm_bresp           => mAxiWriteSlave .bresp,
               m_axi_s2mm_bvalid          => mAxiWriteSlave .bvalid,
               m_axi_s2mm_bready          => imAxiWriteMaster.bready,
               s_axis_s2mm_tdata          => isAxisMaster.tData(127 downto 0),
               s_axis_s2mm_tkeep          => isAxisMaster.tKeep( 15 downto 0),
               s_axis_s2mm_tlast          => isAxisMaster.tLast,
               s_axis_s2mm_tvalid         => isAxisMaster.tValid,
               s_axis_s2mm_tready         => mAxisSlave.tReady
               );
  
  wrTransfer  <= intDscWriteSlave.status.tValid and intDscWriteMaster.status.tReady;
  dinTransfer <= intDscWriteSlave.status.tData(30 downto 8);
  
  comb : process ( r, axiRst,
                   isAxisMaster,
                   mAxisSlave,
                   intDscWriteSlave,
                   enable, mAxiAddr ) is
    variable v       : RegType;
    variable i       : integer;
    variable waddr   : slv(39 downto 0);
  begin
    v := r;

    --
    --  Detect new stream packets
    --
    if (enable = '1' and
        isAxisMaster.tValid = '1' and
        r.idle = '1') then
      v.idle    := '0';
      v.wrIndex := r.wrIndex + 1;
    end if;

    if isAxisMaster.tLast = '1' and mAxisSlave.tReady = '1' then
      v.idle := '1';
    end if;
    
    --
    --  Keep stuffing new block addresses into the Axi engine
    --
    if intDscWriteSlave.command.tReady = '1' then
      v.locMaster.command.tValid := '0';
    end if;

    if (v.locMaster.command.tValid = '0' and
        r.wrIndex /= r.rdIndex) then
      waddr   := resize(mAxiAddr,40);
      v.locMaster.command.tData(79 downto 0) := x"0" & toSlv(0,4) &
                                                waddr &
                                                "01" & toSlv(0,6) &
                                                '1' & MAX_BYTES_C;
      v.locMaster.command.tValid := '1';
      v.locMaster.command.tLast  := '1';
      v.rdIndex := r.rdIndex + 1;
    end if;

    --  Must hold to one clock edge
    if r.locMaster.status.tReady = '1' then
      v.locMaster.status.tReady := '0';
    end if;

    if intDscWriteSlave.status.tValid = '1' then
      v.locMaster.status.tReady := '1';
    end if;
    
    intDscWriteMaster.command <= r.locMaster.command;
    intDscWriteMaster.status  <= v.locMaster.status;
    
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



