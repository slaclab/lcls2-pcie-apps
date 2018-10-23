-------------------------------------------------------------------------------
-- File       : AppToMigWrapper.vhd
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
use work.Pgp3Pkg.all;
use work.AppMigPkg.all;

entity AppToMigWrapper is
  generic ( AXI_BASE_ADDR_G     : slv(31 downto 0) := (others=>'0');
            DEBUG_G             : boolean          := false );
  port    ( -- Clock and reset
    sAxisClk         : in  sl; -- 156MHz
    sAxisRst         : in  sl;
    sAxisMaster      : in  AxiStreamMasterType;
    sAxisSlave       : out AxiStreamSlaveType ;
    sAlmostFull      : out sl;
    sFull            : out sl;
    -- AXI4 Interface to MIG
    mAxiClk          : in  sl; -- 200MHz
    mAxiRst          : in  sl;
    mAxiWriteMaster  : out AxiWriteMasterType ;
    mAxiWriteSlave   : in  AxiWriteSlaveType  ;
    -- Command/Status
    dscReadMaster    : out AxiDescMasterType  ;
    dscReadSlave     : in  AxiDescSlaveType   ;
    -- Configuration
    memReady         : in  sl := '0';
    config           : in  MigConfigType;
    -- Status
    status           : out MigStatusType );
end AppToMigWrapper;

architecture mapping of AppToMigWrapper is

  COMPONENT AppToMig
    PORT (
      m_axi_s2mm_aclk : IN STD_LOGIC;
      m_axi_s2mm_aresetn : IN STD_LOGIC;
      s2mm_err : OUT STD_LOGIC;
      m_axis_s2mm_cmdsts_awclk : IN STD_LOGIC;
      m_axis_s2mm_cmdsts_aresetn : IN STD_LOGIC;
      s_axis_s2mm_cmd_tvalid : IN STD_LOGIC;
      s_axis_s2mm_cmd_tready : OUT STD_LOGIC;
      s_axis_s2mm_cmd_tdata : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
      m_axis_s2mm_sts_tvalid : OUT STD_LOGIC;
      m_axis_s2mm_sts_tready : IN STD_LOGIC;
      m_axis_s2mm_sts_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axis_s2mm_sts_tkeep : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axis_s2mm_sts_tlast : OUT STD_LOGIC;
      m_axi_s2mm_awid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_s2mm_awaddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
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

  signal mAxisMaster : AxiStreamMasterType;
  signal mAxisSlave  : AxiStreamSlaveType;

  signal intDscWriteMaster : AxiDescMasterType;
  signal intDscWriteSlave  : AxiDescSlaveType;

  signal doutTransfer  : slv(22 downto 0);
  
  signal axiRstN : sl;
  signal mPause  : sl;
  signal mFull   : sl;

  type TagState is (IDLE_T, REQUESTED_T, COMPLETED_T);
  type TagStateArray is array(natural range<>) of TagState;
  
  constant BIS : integer := BLOCK_INDEX_SIZE_C;
  
  type RegType is record
    wrIndex        : slv(BIS-1 downto 0);  -- write request
    wcIndex        : slv(BIS-1 downto 0);  -- write complete
    rdIndex        : slv(BIS-1 downto 0);  -- read complete
    wrTag          : TagStateArray(15 downto 0);
    wrTransfer     : sl;
    wrTransferAddr : slv(BIS-1 downto 0);
    wrTransferDin  : slv(22 downto 0);
    rdenb          : sl;
    locMaster      : AxiDescMasterType;
    remMaster      : AxiDescMasterType;
    blocksFree     : slv(BIS-1 downto 0);
    tlast          : sl;
    recvdQueCnt    : slv(7 downto 0);
    writeQueCnt    : slv(7 downto 0);
    wstrbl         : sl;
    framecnt       : slv(7 downto 0);
    framecnt_err   : sl;
  end record;

  constant REG_INIT_C : RegType := (
    wrIndex        => (others=>'0'),
    wcIndex        => (others=>'0'),
    rdIndex        => (others=>'0'),
    wrTag          => (others=>IDLE_T),
    wrTransfer     => '0',
    wrTransferAddr => (others=>'0'),
    wrTransferDin  => (others=>'0'),
    rdenb          => '0',
    locMaster      => AXI_DESC_MASTER_INIT_C,
    remMaster      => AXI_DESC_MASTER_INIT_C,
    blocksFree     => (others=>'0'),
    tlast          => '1',
    recvdQueCnt    => (others=>'0'),
    writeQueCnt    => (others=>'0'),
    wstrbl         => '0',
    framecnt       => (others=>'0'),
    framecnt_err   => '0' );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal isAxisSlave : AxiStreamSlaveType;
  signal isPause     : sl;
  signal isFull      : sl;
  
  signal imAxiWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;

  -- DMA AXI Stream Configuration
  constant AXIO_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 16,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_NORMAL_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_NORMAL_C);
  
  component ila_0
    port ( clk          : in sl;
           probe0       : in slv(255 downto 0) );
  end component;

  signal s2mm_err      : sl;
  signal sframecnt     : slv(7 downto 0) := (others=>'0');
  signal sframecnt_err : sl := '0';
  signal sBlocksFree   : slv(BIS-1 downto 0);
  signal sBlocksFreeD  : slv(9 downto 0);

  signal rdenb          : sl;
  signal rdTransferAddr : slv(BIS-1 downto 0);  -- read complete

begin

  GEN_DEBUG : if DEBUG_G generate
    sBlocksFreeD <= resize(sBlocksFree,10);
    U_ILA_APP : ila_0
      port map ( clk          => sAxisClk,
                 probe0(0)    => sAxisRst,
                 probe0(1)    => sAxisMaster.tValid,
                 probe0(2)    => sAxisMaster.tLast,
                 probe0(3)    => isAxisSlave.tReady,
                 probe0(4)    => isPause,
                 probe0( 68 downto  5) => sAxisMaster.tData(63 downto 0),
                 probe0( 76 downto 69) => sframecnt,
                 probe0( 77 )          => sframecnt_err,
                 probe0( 78 )          => isFull,
                 probe0( 88 downto 79) => sBlocksFreeD,
                 probe0(255 downto 89) => (others=>'0') );
    U_ILA_MIG : ila_0
      port map ( clk          => mAxiClk,
                 probe0(0)              => imAxiWriteMaster.awvalid,
                 probe0(32 downto 1)    => imAxiWriteMaster.awaddr(31 downto 0),
                 probe0(40 downto 33)    => imAxiWriteMaster.awlen,
                 probe0(43 downto 41)    => imAxiWriteMaster.awsize,
                 probe0(44)              => mAxiWriteSlave.awready,
                 probe0(45)              => imAxiWriteMaster.wvalid,
                 probe0(46)              => imAxiWriteMaster.wlast,
                 probe0(47)              => mAxiWriteSlave.wready,
                 probe0(48)              => mAxiWriteSlave.bvalid,
                 probe0(50 downto 49)    => mAxiWriteSlave.bresp,
                 probe0(51)              => imAxiWriteMaster.bready,
                 probe0(52)              => intDscWriteMaster.command.tValid,
                 probe0(124 downto 53)   => intDscWriteMaster.command.tData(71 downto 0),
                 probe0(125)             => intDscWriteMaster.command.tLast,
                 probe0(126)             => intDscWriteSlave .command.tReady,
                 probe0(127)             => intDscWriteSlave .status .tValid,
                 probe0(159 downto 128)  => intDscWriteSlave .status .tData(31 downto 0),
                 probe0(160)             => intDscWriteMaster.status .tReady,
                 probe0(161)             => r.remMaster.command.tValid,
                 probe0(184 downto 162)  => r.remMaster.command.tData(22 downto 0),
                 probe0(196 downto 185)  => r.remMaster.command.tData(63 downto 52),
                 probe0(197)             => r.rdenb,
                 probe0(201 downto 198)  => r.wrIndex(3 downto 0),
                 probe0(205 downto 202)  => r.wcIndex(3 downto 0),
                 probe0(209 downto 206)  => r.rdIndex(3 downto 0),
                 probe0(210)             => '0',
                 probe0(233 downto 211)  => doutTransfer,
                 probe0(234)             => dscReadSlave.command.tReady,
                 probe0(235)             => s2mm_err,
                 probe0(236)             => r.framecnt_err,
                 probe0(244 downto 237)  => r.framecnt,
                 probe0(255 downto 245)  => (others=>'0') );
  end generate;

  sAxisSlave                <= isAxisSlave;
  sAlmostFull               <= isPause;
  sFull                     <= isFull;
  mAxiWriteMaster           <= imAxiWriteMaster;
  
  mPause <= '1' when (r.blocksFree < config.blocksPause) else '0';
  mFull  <= '1' when ((r.blocksFree < 4) or (config.inhibit='1')) else '0';

  U_Free  : entity work.SynchronizerFifo
    generic map ( DATA_WIDTH_G => BIS )
    port map ( wr_clk  => mAxiClk,
               din     => r.blocksFree,
               rd_clk  => sAxisClk,
               dout    => sBlocksFree );
  
  U_Pause : entity work.Synchronizer
    port map ( clk     => sAxisClk,
               rst     => sAxisRst,
               dataIn  => mPause,
               dataOut => isPause );

  U_Full : entity work.Synchronizer
    port map ( clk     => sAxisClk,
               rst     => sAxisRst,
               dataIn  => mFull,
               dataOut => isFull );

  U_Ready : entity work.Synchronizer
    port map ( clk     => mAxiClk,
               rst     => mAxiRst,
               dataIn  => memReady,
               dataOut => status.memReady );
  
  --
  --  Insert a fifo to cross clock domains
  --
  U_AxisFifo : entity work.AxiStreamFifo
    generic map ( FIFO_ADDR_WIDTH_G   => 8,
                  SLAVE_AXI_CONFIG_G  => PGP3_AXIS_CONFIG_C,
                  MASTER_AXI_CONFIG_G => AXIO_STREAM_CONFIG_C )
    port map ( sAxisClk    => sAxisClk,
               sAxisRst    => sAxisRst,
               sAxisMaster => sAxisMaster,
               sAxisSlave  => isAxisSlave,
               sAxisCtrl   => open,
               mAxisClk    => mAxiClk,
               mAxisRst    => mAxiRst,
               mAxisMaster => mAxisMaster,
               mAxisSlave  => mAxisSlave );
  
  axiRstN                  <= not mAxiRst;

  --
  --  Translate AxiStream to Axi using fixed size starting block addresses
  --
  U_ADM : AppToMig
    port map ( m_axi_s2mm_aclk            => mAxiClk,
               m_axi_s2mm_aresetn         => axiRstN,
               s2mm_err                   => s2mm_err,
               m_axis_s2mm_cmdsts_awclk   => mAxiClk,
               m_axis_s2mm_cmdsts_aresetn => axiRstN,
               s_axis_s2mm_cmd_tvalid     => intDscWriteMaster.command.tValid,
               s_axis_s2mm_cmd_tready     => intDscWriteSlave .command.tReady,
               s_axis_s2mm_cmd_tdata      => intDscWriteMaster.command.tData(71 DOWNTO 0),
               m_axis_s2mm_sts_tvalid     => intDscWriteSlave .status.tValid,
               m_axis_s2mm_sts_tready     => intDscWriteMaster.status.tReady,
               m_axis_s2mm_sts_tdata      => intDscWriteSlave .status.tData(31 DOWNTO 0),
               m_axis_s2mm_sts_tkeep      => intDscWriteSlave .status.tKeep(3 DOWNTO 0),
               m_axis_s2mm_sts_tlast      => intDscWriteSlave .status.tLast,
               m_axi_s2mm_awid            => imAxiWriteMaster.awid(3 downto 0),
               m_axi_s2mm_awaddr          => imAxiWriteMaster.awaddr(31 downto 0),
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
               s_axis_s2mm_tdata          => mAxisMaster.tData(127 downto 0),
               s_axis_s2mm_tkeep          => mAxisMaster.tKeep( 15 downto 0),
               s_axis_s2mm_tlast          => mAxisMaster.tLast,
               s_axis_s2mm_tvalid         => mAxisMaster.tValid,
               s_axis_s2mm_tready         => mAxisSlave.tReady
               );
  
  U_TransferFifo : entity work.SimpleDualPortRam
    generic map ( DATA_WIDTH_G => 23,
                  ADDR_WIDTH_G => BIS )
    port map ( clka       => mAxiClk,
               wea        => r.wrTransfer,
               addra      => r.wrTransferAddr,
               dina       => r.wrTransferDin,
               clkb       => mAxiClk,
               enb        => rdenb,
               addrb      => rdTransferAddr,
               doutb      => doutTransfer );

  comb : process ( r, mAxiRst,
                   mAxisMaster, mAxisSlave,
                   doutTransfer ,
                   dscReadSlave,
                   intDscWriteSlave,
                   config,
                   imAxiWriteMaster ) is
    variable v       : RegType;
    variable i       : integer;
    variable wlen    : slv(22 downto 0);
    variable waddr   : slv(31 downto 0);
    variable rlen    : slv(22 downto 0);
    variable raddr   : slv(31 downto 0);
    variable stag    : slv( 3 downto 0);
    variable itag    : integer;
    variable axiRstQ : slv( 2 downto 0) := (others=>'1');
  begin
    v := r;

    v.locMaster.command.tLast  := '1'; -- always a single word
    v.locMaster.status.tReady  := '0';
    v.wrTransfer               := '0';
    
    i := BLOCK_BASE_SIZE_C;
    
    --
    --  Stuff a new block address into the Axi engine
    --    on the first transfer of a new frame
    if (mAxisMaster.tValid = '1' and
        mAxisSlave.tReady  = '1') then
      if r.tlast = '1' then
        v.recvdQueCnt := v.recvdQueCnt + 1;
      end if;
      v.tlast := mAxisMaster.tLast;
    end if;
    
    if intDscWriteSlave.command.tReady = '1' then
      v.locMaster.command.tValid := '0';
    end if;

    itag := conv_integer(r.wrIndex(3 downto 0));
    if (v.locMaster.command.tValid = '0') then
      waddr   := resize(r.wrIndex & toSlv(0,i), 32) + AXI_BASE_ADDR_G;
      wlen    := (others=>'0');
      wlen(i) := '1';
      v.locMaster.command.tData(71 downto 0) :=
        x"0" &                   -- reserved
        toSlv(itag,4) &          -- tag
        waddr &                  -- address[31:0]
        "01" & toSlv(0,6) &      -- EOF command
        '1' & wlen;              -- max write length
      if (r.wrTag(itag) = IDLE_T and
          r.recvdQueCnt /= 0 and
          r.wrIndex + 16 /= r.rdIndex) then  -- prevent overwrite
        v.wrIndex                  := r.wrIndex + 1;
        v.recvdQueCnt              := v.recvdQueCnt - 1;
        v.wrTag(itag)              := REQUESTED_T;
        v.locMaster.command.tValid := '1';
      end if;
    end if;

    stag := intDscWriteSlave.status.tData(3 downto 0);
    itag := conv_integer(stag);
    if intDscWriteSlave.status.tValid = '1' then
      v.locMaster.status.tReady := '1';
      v.wrTag(itag)      := COMPLETED_T;
      v.wrTransfer       := '1';
      v.wrTransferDin    := intDscWriteSlave.status.tData(30 downto 8);
      if stag < r.wcIndex(3 downto 0) then
        v.wrTransferAddr := (r.wcIndex(BIS-1 downto 4)+1) & stag;
      else
        v.wrTransferAddr := (r.wcIndex(BIS-1 downto 4)+0) & stag;
      end if;
    end if;
    
    itag := conv_integer(r.wcIndex(3 downto 0));
    if r.wrTag(itag) = COMPLETED_T then
      v.wrTag(itag) := IDLE_T;
      v.wcIndex     := r.wcIndex + 1;
    end if;
    
    if dscReadSlave.command.tReady = '1' then
      v.remMaster.command.tValid := '0';
    end if;

    if (v.remMaster.command.tValid = '0' and
        r.rdenb ='1' and
        r.rdIndex /= r.wcIndex) then
      raddr   := resize(r.rdIndex & toSlv(0,i), 32) + AXI_BASE_ADDR_G;
      rlen                       := doutTransfer;
      v.remMaster.command.tData(71 downto 0) := x"0" & toSlv(0,4) &
                                                raddr &
                                                "01" & toSlv(0,6) &
                                                '1' & rlen;
      v.remMaster.command.tValid := '1';
      v.remMaster.command.tLast  := '1';
      v.rdIndex                  := r.rdIndex + 1;
    end if;

    if (r.wrTransfer = '1' and
        r.wrTransferAddr = v.rdIndex) then
      v.rdenb := '0';
    else
      v.rdenb := '1';
    end if;
    
    v.remMaster.status.tReady := '0';
    if dscReadSlave.status.tValid = '1' then
      v.remMaster.status.tReady := '1';
    end if;

    if (r.locMaster.command.tValid = '1' and
        intDscWriteSlave.command.tReady = '1') then
      v.writeQueCnt := v.writeQueCnt + 1;
    end if;

    if (v.locMaster.status.tReady = '1' and
        intDscWriteSlave.status.tValid = '1') then
      v.writeQueCnt := v.writeQueCnt - 1;
    end if;
    
    
    v.blocksFree              := resize(r.rdIndex - r.wcIndex - 1, BIS);

    status.blocksFree         <= r.blocksFree;
    status.blocksQueued       <= resize(r.wrIndex - r.rdIndex, BIS);
    status.readMasterBusy     <= r.remMaster.command.tValid and not dscReadSlave    .command.tReady;
    status.writeSlaveBusy     <= r.locMaster.command.tValid and not intDscWriteSlave.command.tReady;
    status.writeQueCnt        <= r.writeQueCnt;
    dscReadMaster             <= r.remMaster;
    intDscWriteMaster.command <= r.locMaster.command;
    intDscWriteMaster.status  <= v.locMaster.status;

    if imAxiWriteMaster.wvalid = '1' then
      v.wstrbl := imAxiWriteMaster.wstrb(15);
      if (imAxiWriteMaster.wstrb(15) = '1' and
          r.wstrbl                   = '0') then
        v.framecnt := imAxiWriteMaster.wdata(7 downto 0);
        if v.framecnt /= r.framecnt+1 then
          v.framecnt_err := '1';
        else
          v.framecnt_err := '0';
        end if;
      end if;
    end if;

    rdenb          <= v.rdenb;
    rdTransferAddr <= v.rdIndex;
    
    if axiRstQ(0) = '1' then
      v := REG_INIT_C;
    end if;
    
    rin <= v;

    axiRstQ := mAxiRst & axiRstQ(2 downto 1);
    
  end process comb;

  seq: process(mAxiClk) is
  begin
    if rising_edge(mAxiClk) then
      r <= rin;
    end if;
  end process seq;

  sseq : process (sAxisClk) is
    variable tLastd : sl := '1';
  begin
    if rising_edge(sAxisClk) then
      if (sAxisMaster.tValid = '1' and
          sAxisMaster.tLast  = '0' and
          tLastd             = '1') then
        if sAxisMaster.tData(7 downto 0) /= sframecnt+1 then
          sframecnt_err <= '1';
        else
          sframecnt_err <= '0';
        end if;
        sframecnt <= sAxisMaster.tData(7 downto 0);
      end if;
      tLastd := sAxisMaster.tLast;
    end if;
  end process sseq;
  
end mapping;



