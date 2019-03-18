-------------------------------------------------------------------------------
-- File       : AppIlvToMigDma.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2019-02-07
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
use work.AxiDmaPkg.all;
use work.AppMigPkg.all;

entity AppIlvToMigDma is
  generic ( LANES_G             : integer          := 4;
            AXIS_CONFIG_G       : AxiStreamConfigType;
            AXI_BASE_ADDR_G     : slv(31 downto 0) := (others=>'0') );
  port    ( -- Clock and reset
    sAxisClk         : in  slv                 (LANES_G-1 downto 0);
    sAxisRst         : in  slv                 (LANES_G-1 downto 0);
    sAxisMaster      : in  AxiStreamMasterArray(LANES_G-1 downto 0);
    sAxisSlave       : out AxiStreamSlaveArray (LANES_G-1 downto 0);
    sAlmostFull      : out slv                 (LANES_G-1 downto 0);
    sFull            : out slv                 (LANES_G-1 downto 0);
    sOverflow        : out Slv8Array           (LANES_G-1 downto 0);
    -- AXI4 Interface to MIG
    mAxiClk          : in  sl; -- 200MHz
    mAxiRst          : in  sl;
    mAxiWriteMaster  : out AxiWriteMasterType ;
    mAxiWriteSlave   : in  AxiWriteSlaveType  ;
    sAxisOflow       : out Slv8Array           (LANES_G-1 downto 0);
    -- Command/Status to MigToPcieDma
    rdDescReq        : out AxiReadDmaDescReqType;
    rdDescReqAck     : in  sl;
    rdDescRet        : in  AxiReadDmaDescRetType;
    rdDescRetAck     : out sl;
    -- Configuration
    memReady         : in  sl := '0';
    config           : in  MigConfigType;
    -- Status
    status           : out MigStatusType );
end AppIlvToMigDma;

architecture mapping of AppIlvToMigDma is

  signal imAxisMaster : AxiStreamMasterArray(LANES_G-1 downto 0);
  signal imAxisSlave  : AxiStreamSlaveArray (LANES_G-1 downto 0);
  signal mAxisMaster  : AxiStreamMasterType;
  signal mAxisSlave   : AxiStreamSlaveType;

  signal doutTransfer  : slv(22 downto 0);
  signal doutUserBits  : slv(15 downto 0);
  
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
    wrUserBits     : slv(15 downto 0);
    rdenb          : sl;
    wrDescAck      : AxiWriteDmaDescAckType;
    wrDescRetAck   : sl;
    rdDescReq      : AxiReadDmaDescReqType;
    rdDescRetAck   : sl;
    blocksFree     : slv(BIS-1 downto 0);
    tlast          : sl;
    recvdQueCnt    : slv(7 downto 0);
    writeQueCnt    : slv(7 downto 0);
  end record;

  constant REG_INIT_C : RegType := (
    wrIndex        => (others=>'0'),
    wcIndex        => (others=>'0'),
    rdIndex        => (others=>'0'),
    wrTag          => (others=>IDLE_T),
    wrTransfer     => '0',
    wrTransferAddr => (others=>'0'),
    wrTransferDin  => (others=>'0'),
    wrUserBits     => (others=>'0'),
    rdenb          => '0',
    wrDescAck      => AXI_WRITE_DMA_DESC_ACK_INIT_C,
    wrDescRetAck   => '0',
    rdDescReq      => AXI_READ_DMA_DESC_REQ_INIT_C,
    rdDescRetAck   => '0',
    blocksFree     => (others=>'0'),
    tlast          => '1',
    recvdQueCnt    => (others=>'0'),
    writeQueCnt    => (others=>'0') );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  constant AXIS_ILV_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 4*AXIS_CONFIG_G.TDATA_BYTES_C,
      TDEST_BITS_C  => AXIS_CONFIG_G.TDEST_BITS_C,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => AXIS_CONFIG_G.TKEEP_MODE_C,
      TUSER_BITS_C  => AXIS_CONFIG_G.TUSER_BITS_C,
      TUSER_MODE_C  => AXIS_CONFIG_G.TUSER_MODE_C );
  
  -- DMA AXI Stream Configuration
  constant AXIO_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => AXIS_ILV_CONFIG_C.TDATA_BYTES_C,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COUNT_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_NORMAL_C);

  constant AXI_ILV_CONFIG_C : AxiConfigType := (
      ADDR_WIDTH_C => APP2MIG_AXI_CONFIG_C.ADDR_WIDTH_C,
      DATA_BYTES_C => AXIS_ILV_CONFIG_C.TDATA_BYTES_C,
      ID_BITS_C    => APP2MIG_AXI_CONFIG_C.ID_BITS_C,
      LEN_BITS_C   => 6 );
    
  component ila_0
    port ( clk          : in sl;
           probe0       : in slv(255 downto 0) );
  end component;

  signal rdenb          : sl;
  signal rdTransferAddr : slv(BIS-1 downto 0);  -- read complete

  signal wrDescReq    : AxiWriteDmaDescReqType;
  signal wrDescAck    : AxiWriteDmaDescAckType;
  signal wrDescRet    : AxiWriteDmaDescRetType;
  signal wrDescRetAck : sl;

  signal sAxisCtrl    : AxiStreamCtrlArray  (LANES_G-1 downto 0);
  
begin

  sAlmostFull <= (others=>'1') when (r.blocksFree < config.blocksPause         ) else (others=>'0');
  sFull       <= (others=>'1') when ((r.blocksFree < 4) or (config.inhibit='1')) else (others=>'0');

  U_Ready : entity work.Synchronizer
    port map ( clk     => mAxiClk,
               rst     => mAxiRst,
               dataIn  => memReady,
               dataOut => status.memReady );
  
  GEN_LANE : for i in 0 to LANES_G-1 generate
    --
    --  Insert a fifo to cross clock domains
    --
    U_AxisFifo : entity work.AxiStreamFifoV2
      generic map ( FIFO_ADDR_WIDTH_G   => 10,
                    SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_G,
                    MASTER_AXI_CONFIG_G => AXIS_CONFIG_G )
      port map ( sAxisClk    => sAxisClk    (i),
                 sAxisRst    => sAxisRst    (i),
                 sAxisMaster => sAxisMaster (i),
                 sAxisSlave  => sAxisSlave  (i),
                 sAxisCtrl   => sAxisCtrl   (i),
                 mAxisClk    => mAxiClk,
                 mAxisRst    => mAxiRst,
                 mAxisMaster => imAxisMaster(i),
                 mAxisSlave  => imAxisSlave (i));

    U_Oflow : entity work.SynchronizerOneShotCnt
      generic map ( CNT_WIDTH_G  => sOverflow(0)'length )
      port map ( dataIn     => sAxisCtrl(i).overflow,
                 rollOverEn => '0',
                 cntOut     => sOverflow(i),
                 wrClk      => sAxisClk (i),
                 rdClk      => mAxiClk );
    
    --tData((i+1)*AXIS_CONFIG_G.TDATA_BYTES_C*8-1 downto
    --      (i+0)*AXIS_CONFIG_G.TDATA_BYTES_C*8) <=
    --  mAxisMaster(i).tData(AXIS_CONFIG_G.TDATA_BYTES_C*8-1 downto 0);
    --tKeep((i+1)*AXIS_CONFIG_G.TDATA_BYTES_C-1 downto
    --      (i+0)*AXIS_CONFIG_G.TDATA_BYTES_C) <=
    --  mAxisMaster(i).tKeep(AXIS_CONFIG_G.TDATA_BYTES_C-1 downto 0);
  end generate;
  
  U_Deinterleave : entity work.AxiStreamDeinterleave
    generic map ( LANES_G        => LANES_G,
                  AXIS_CONFIG_G  => AXIS_CONFIG_G )
    port map ( axisClk     => mAxiClk,
               axisRst     => mAxiRst,
               sAxisMaster => imAxisMaster,
               sAxisSlave  => imAxisSlave ,
               mAxisMaster => mAxisMaster,
               mAxisSlave  => mAxisSlave );
  
  U_SeqTest : entity work.AppSeqTest
    port map ( axisClk    => mAxiClk,
               axisRst    => mAxiRst,
               axisMaster => mAxisMaster,
               axisSlave  => mAxisSlave );
  
  --
  --  Insert a fifo to cross clock domains
  --
  --U_AxisFifo : entity work.AxiStreamFifoV2
  --  generic map ( FIFO_ADDR_WIDTH_G   => 8,
  --                SLAVE_AXI_CONFIG_G  => AXIS_ILV_CONFIG_C,
  --                MASTER_AXI_CONFIG_G => AXIO_STREAM_CONFIG_C )
  --  port map ( sAxisClk    => sAxisClk,
  --             sAxisRst    => sAxisRst,
  --             sAxisMaster => sAxisMaster,
  --             sAxisSlave  => isAxisSlave,
  --             sAxisCtrl   => open,
  --             mAxisClk    => mAxiClk,
  --             mAxisRst    => mAxiRst,
  --             mAxisMaster => mAxisMaster,
  --             mAxisSlave  => mAxisSlave );
  
  U_DmaWrite : entity work.AxiStreamDmaV2Write
    generic map ( AXI_READY_EN_G => true,
                  AXIS_CONFIG_G  => AXIS_ILV_CONFIG_C,
                  AXI_CONFIG_G   => AXI_ILV_CONFIG_C )
    port map ( axiClk         => mAxiClk,
               axiRst         => mAxiRst,
               dmaWrDescReq   => wrDescReq,
               dmaWrDescAck   => wrDescAck,
               dmaWrDescRet   => wrDescRet,
               dmaWrDescRetAck=> wrDescRetAck,
               dmaWrIdle      => open,
               axiCache       => x"3",
               axisMaster     => mAxisMaster,
               axisSlave      => mAxisSlave,
               axiWriteMaster => mAxiWriteMaster,
               axiWriteSlave  => mAxiWriteSlave );
                    
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

  U_UserBitFifo : entity work.SimpleDualPortRam
    generic map ( DATA_WIDTH_G => 16,
                  ADDR_WIDTH_G => BIS )
    port map ( clka       => mAxiClk,
               wea        => r.wrTransfer,
               addra      => r.wrTransferAddr,
               dina       => r.wrUserBits,
               clkb       => mAxiClk,
               enb        => rdenb,
               addrb      => rdTransferAddr,
               doutb      => doutUserBits );

  
  comb : process ( r, mAxiRst,
                   mAxisMaster, mAxisSlave,
                   wrDescReq,
                   wrDescRet,
                   rdDescReqAck,
                   rdDescRet,
                   doutTransfer ,
                   doutUserBits ,
                   config ) is
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
    
    itag := conv_integer(r.wrIndex(3 downto 0));
    if (wrDescReq.valid = '1') then
      waddr   := resize(r.wrIndex & toSlv(0,i), 32) + AXI_BASE_ADDR_G;
      wlen    := (others=>'0');
      wlen(i) := '1';
      v.wrDescAck.valid   := '0';
      v.wrDescAck.address := resize(waddr,64);
      v.wrDescAck.dropEn  := '0';
      v.wrDescAck.maxSize := resize(wlen,32);
      v.wrDescAck.contEn  := '1';
      v.wrDescAck.buffId  := toSlv(itag,32);
      if (r.wrTag(itag) = IDLE_T and
          r.recvdQueCnt /= 0 and
          r.wrIndex + 16 /= r.rdIndex) then  -- prevent overwrite
        v.wrIndex                  := r.wrIndex + 1;
        v.recvdQueCnt              := v.recvdQueCnt - 1;
        v.wrTag(itag)              := REQUESTED_T;
        v.wrDescAck.valid          := '1';
      end if;
    end if;

    stag := wrDescRet.buffId(3 downto 0);
    itag := conv_integer(stag);
    v.wrDescRetAck := wrDescRet.valid;
    if wrDescRet.valid = '1' then
      v.wrTag(itag)      := COMPLETED_T;
      v.wrTransfer       := '1';
      v.wrTransferDin    := resize(wrDescRet.size,23);
      v.wrUserBits       := wrDescRet.lastUser & wrDescRet.firstUser;
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

    if rdDescReqAck='1' then
      v.rdDescReq.valid := '0';
    end if;
    
    if (v.rdDescReq.valid='0' and
        r.rdenb ='1' and
        r.rdIndex /= r.wcIndex) then
      raddr   := resize(r.rdIndex & toSlv(0,i), 32) + AXI_BASE_ADDR_G;
      rlen                       := doutTransfer;
      v.rdDescReq.valid          := '1';
      v.rdDescReq.address        := resize(raddr,64);
      v.rdDescReq.buffId         := resize(r.rdIndex,32);
      v.rdDescReq.firstUser      := doutUserBits( 7 downto 0);
      v.rdDescReq.lastUser       := doutUserBits(15 downto 8);
      v.rdDescReq.size           := resize(rlen,32);
      v.rdIndex                  := r.rdIndex + 1;
    end if;

    if (r.wrTransfer = '1' and
        r.wrTransferAddr = v.rdIndex) then
      v.rdenb := '0';
    else
      v.rdenb := '1';
    end if;
    
    v.rdDescRetAck := rdDescRet.valid;
    if (rdDescRet.valid = '1') then
      v.writeQueCnt := v.writeQueCnt + 1;
    end if;

    v.blocksFree              := resize(r.rdIndex - r.wcIndex - 1, BIS);

    status.blocksFree         <= r.blocksFree;
    status.blocksQueued       <= resize(r.wrIndex - r.rdIndex, BIS);
    status.writeQueCnt        <= r.writeQueCnt;
    status.wrIndex            <= r.wrIndex;
    status.wcIndex            <= r.wcIndex;
    status.rdIndex            <= r.rdIndex;
    
    wrDescAck                 <= r.wrDescAck;
    wrDescRetAck              <= v.wrDescRetAck;
    rdDescReq                 <= r.rdDescReq;
    rdDescRetAck              <= v.rdDescRetAck;

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

end mapping;
