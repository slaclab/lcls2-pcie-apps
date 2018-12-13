library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiDmaPkg.all;
use work.AppMigPkg.all;
use work.TDetPkg.all;
use work.Pgp3Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity DrpTDetSim is
end DrpTDetSim;

architecture top_level_app of DrpTDetSim is

  constant LANES_C : integer := 4;
  
  signal axiClk, axiRst : sl;
  signal axilWriteMaster     : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
  signal axilWriteSlave      : AxiLiteWriteSlaveType;
  signal axilReadMaster      : AxiLiteReadMasterType := AXI_LITE_READ_MASTER_INIT_C;
  signal axilReadSlave       : AxiLiteReadSlaveType := AXI_LITE_READ_SLAVE_INIT_C;
  signal axilDone : sl;
  
  constant sAxisConfig : AxiStreamConfigType := (
    TSTRB_EN_C    => true,
    TDATA_BYTES_C => 8,
    TDEST_BITS_C  => 0,
    TID_BITS_C    => 0,
    TKEEP_MODE_C  => TKEEP_NORMAL_C,
    TUSER_BITS_C  => 0,
    TUSER_MODE_C  => TUSER_NONE_C );
  
  -- DMA AXI Stream Configuration
  constant AXIO_STREAM_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 16,
      TDEST_BITS_C  => 8,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_NORMAL_C,
      TUSER_BITS_C  => 4,
      TUSER_MODE_C  => TUSER_NORMAL_C);

   -- DMA AXI Configuration   
   constant DMA_AXI_CONFIG_C : AxiConfigType := (
      ADDR_WIDTH_C => 40,
      DATA_BYTES_C => AXIO_STREAM_CONFIG_C.TDATA_BYTES_C,  -- Matches the AXIS stream
      ID_BITS_C    => 4,
      LEN_BITS_C   => 8 );

  -- AXI DMA descriptor  
  constant AXI_DESC_CONFIG_C : AxiConfigType := (
    ADDR_WIDTH_C => 40,
    DATA_BYTES_C => 16,               -- always 128-bit AXI DMA descriptor 
    ID_BITS_C    => 4,
    LEN_BITS_C   => 8 );

  signal axisClk, axisRst    : sl;
  signal sAxisMasters        : AxiStreamMasterArray(LANES_C-1 downto 0) := (others=>axiStreamMasterInit(sAxisConfig));
  signal sAxisSlaves         : AxiStreamSlaveArray (LANES_C-1 downto 0);
  
  signal memWriteMasters : AxiWriteMasterArray(LANES_C-1 downto 0) := (others=>AXI_WRITE_MASTER_INIT_C);
  signal memReadMasters  : AxiReadMasterArray (LANES_C-1 downto 0) := (others=>AXI_READ_MASTER_INIT_C);
  signal memWriteSlaves  : AxiWriteSlaveArray (LANES_C-1 downto 0) := (others=>AXI_WRITE_SLAVE_INIT_C);
  signal memReadSlaves   : AxiReadSlaveArray  (LANES_C-1 downto 0) := (others=>AXI_READ_SLAVE_INIT_C);

  signal ddrClk         : sl;
  signal ddrRst         : sl;
  signal ddrWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
  signal ddrReadMaster  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
  signal ddrWriteSlave  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
  signal ddrReadSlave   : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;

  signal mem_wdata  : Slv128Array(3 downto 0);
  signal mem_rdata  : Slv128Array(3 downto 0);

   signal rdDescReq : AxiReadDmaDescReqArray(LANES_C-1 downto 0);
   signal rdDescRet : AxiReadDmaDescRetArray(LANES_C-1 downto 0);
   signal rdDescReqAck : slv(LANES_C-1 downto 0);
   signal rdDescRetAck : slv(LANES_C-1 downto 0);

  signal dmaIbMasters : AxiStreamMasterArray(LANES_C downto 0);
  signal dmaIbSlaves  : AxiStreamSlaveArray (LANES_C downto 0) := (
    others=>AXI_STREAM_SLAVE_FORCE_C );
  signal dmaObMasters : AxiStreamMasterArray(LANES_C downto 0);
  signal dmaObSlaves  : AxiStreamSlaveArray (LANES_C downto 0) := (
    others=>AXI_STREAM_SLAVE_FORCE_C );

  signal mtpIbMasters : AxiStreamMasterArray(LANES_C downto 0);
  signal mtpIbSlaves  : AxiStreamSlaveArray (LANES_C downto 0) := (
    others=>AXI_STREAM_SLAVE_FORCE_C );
  
  constant NDET_C : integer := 4;
  signal tdetClk    : sl;
  signal tdetRst    : sl;
  signal tdetTiming : TDetTimingArray(NDET_C-1 downto 0);
  signal tdetStatus : TDetStatusArray(NDET_C-1 downto 0);
  signal tdetEventM : AxiStreamMasterArray (NDET_C-1 downto 0) := (others=>AXI_STREAM_MASTER_INIT_C);
  signal tdetEventS : AxiStreamSlaveArray  (NDET_C-1 downto 0);
  signal tdetTransM : AxiStreamMasterArray (NDET_C-1 downto 0) := (others=>AXI_STREAM_MASTER_INIT_C);
  signal tdetTransS : AxiStreamSlaveArray  (NDET_C-1 downto 0);

  signal hwClks          : slv                 (3 downto 0);
  signal hwRsts          : slv                 (3 downto 0);
  signal hwObMasters     : AxiStreamMasterArray(3 downto 0) := (others=>AXI_STREAM_MASTER_INIT_C);
  signal hwObSlaves      : AxiStreamSlaveArray (3 downto 0);
  signal hwIbMasters     : AxiStreamMasterArray(3 downto 0);
  signal hwIbSlaves      : AxiStreamSlaveArray (3 downto 0);
  signal hwIbAlmostFull  : slv                 (3 downto 0);
  signal hwIbFull        : slv                 (3 downto 0);

  signal migConfig : MigConfigArray(3 downto 0) := (others=>MIG_CONFIG_INIT_C);
  signal migStatus : MigStatusArray(3 downto 0);

  signal pciReadMasters  : AxiReadMasterArray (LANES_C+1 downto 0);
  signal pciReadSlaves   : AxiReadSlaveArray  (LANES_C+1 downto 0) := (others=>AXI_READ_SLAVE_FORCE_C);
  signal pciWriteMasters : AxiWriteMasterArray(LANES_C+1 downto 0);
  signal pciWriteSlaves  : AxiWriteSlaveArray (LANES_C+1 downto 0) := (others=>AXI_WRITE_SLAVE_FORCE_C);
  signal pciWriteMastersData : Slv128Array(LANES_C+1 downto 0);
  signal pciWriteMastersStrb : Slv16Array (LANES_C+1 downto 0);

  signal dmaAxilWriteMaster  : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
  signal dmaAxilWriteSlave   : AxiLiteWriteSlaveType;
  signal dmaAxilReadMaster   : AxiLiteReadMasterType := AXI_LITE_READ_MASTER_INIT_C;
  signal dmaAxilReadSlave    : AxiLiteReadSlaveType;
  
  signal sysClk, sysRst : sl;
  signal dmaIrq : sl;
  
begin

  U_TDetTiming : entity work.TDetTimingSim
    generic map ( NDET_G => NDET_C )
    port map ( tdetClk          => tdetClk   ,
               tdetRst          => tdetRst   ,
               tdetTiming       => tdetTiming,
               tdetStatus       => tdetStatus,
               tdetEventMaster  => tdetEventM ,
               tdetEventSlave   => tdetEventS ,
               tdetTransMaster  => tdetTransM ,
               tdetTransSlave   => tdetTransS );

  U_Hw : entity work.TDetSemi
    generic map ( DEBUG_G => false )
    port map (
      ------------------------      
      --  Top Level Interfaces
      ------------------------         
      -- AXI-Lite Interface (axilClk domain)
      axilClk         => axiClk,
      axilRst         => axiRst,
      axilReadMaster  => axilReadMaster ,
      axilReadSlave   => axilReadSlave  ,
      axilWriteMaster => axilWriteMaster,
      axilWriteSlave  => axilWriteSlave ,
      -- DMA Interface (dmaClk domain)
      dmaClks         => hwClks        ,
      dmaRsts         => hwRsts        ,
      dmaObMasters    => hwObMasters   ,
      dmaObSlaves     => hwObSlaves    ,
      dmaIbMasters    => hwIbMasters   ,
      dmaIbSlaves     => hwIbSlaves    ,
      dmaIbAlmostFull => hwIbAlmostFull,
      dmaIbFull       => hwIbFull      ,
      ------------------
      --  TDET Ports
      ------------------       
      tdetClk         => tdetClk,
      tdetClkRst      => tdetRst,
      tdetTiming      => tdetTiming,
      tdetStatus      => tdetStatus,
      tdetEventMaster => tdetEventM,
      tdetEventSlave  => tdetEventS,
      tdetTransMaster => tdetTransM,
      tdetTransSlave  => tdetTransS,
      modPrsL         => '0' );

  --hwIbSlaves     <= (others=>AXI_STREAM_SLAVE_FORCE_C);
--  hwIbAlmostFull <= (others=>'0');
--  hwIbFull       <= (others=>'0');
  
  GEN_HWDMA : for j in 0 to NDET_C-1 generate
    migConfig(j).inhibit <= '0';
    U_HwDma : entity work.AppToMigDma
      generic map ( AXI_BASE_ADDR_G     => (toSlv(j,2) & toSlv(0,30)) )
      port map ( sAxisClk        => hwClks         (j),
                 sAxisRst        => hwRsts         (j),
                 sAxisMaster     => hwIbMasters    (j),
                 sAxisSlave      => hwIbSlaves     (j),
                 sAlmostFull     => hwIbAlmostFull (j),
                 sFull           => hwIbFull       (j),
                 mAxiClk         => axiClk,
                 mAxiRst         => axiRst,
                 mAxiWriteMaster => memWriteMasters(j),
                 mAxiWriteSlave  => memWriteSlaves (j),
                 rdDescReq       => rdDescReq      (j), -- exchange
                 rdDescReqAck    => rdDescReqAck   (j),
                 rdDescRet       => rdDescRet      (j),
                 rdDescRetAck    => rdDescRetAck   (j),
                 memReady        => '1',
                 config          => migConfig      (j),
                 status          => migStatus      (j) );
  end generate;

  U_DUT2 : entity work.MigToPcieDma
    generic map ( LANES_G       => LANES_C,
                  AXIS_CONFIG_G => AXIO_STREAM_CONFIG_C )
    port map (  -- Clock and reset
      axiClk           => axiClk,
      axiRst           => axiRst,
      -- AXI4 Interfaces to MIG
      axiReadMasters   => memReadMasters,
      axiReadSlaves    => memReadSlaves,
      -- AxiStream Interfaces from MIG (Data Mover command)
      rdDescReq        => rdDescReq,
      rdDescAck        => rdDescReqAck,
      rdDescRet        => rdDescRet,
      rdDescRetAck     => rdDescRetAck,
      -- AxiStream Interface to PCIe
      axisMasters      => mtpIbMasters,
      axisSlaves       => mtpIbSlaves,
      -- AXI Lite Interface
      axilClk          => axiClk,
      axilRst          => axiRst,
      axilWriteMaster  => AXI_LITE_WRITE_MASTER_INIT_C,
      axilWriteSlave   => open,
      axilReadMaster   => AXI_LITE_READ_MASTER_INIT_C,
      axilReadSlave    => open,
      monClk           => (others=>'0'),
      --
      migStatus        => migStatus );

  U_MIG0 : entity work.MigXbarV3Wrapper
    port map (
      -- Slave Interfaces
      sAxiClk          => axiClk,
      sAxiRst          => axiRst,
      sAxiWriteMasters => memWriteMasters,
      sAxiWriteSlaves  => memWriteSlaves ,
      sAxiReadMasters  => memReadMasters ,
      sAxiReadSlaves   => memReadSlaves  ,
      -- Master Interface
      mAxiClk          => ddrClk,
      mAxiRst          => ddrRst,
      mAxiWriteMaster  => ddrWriteMaster,
      mAxiWriteSlave   => ddrWriteSlave ,
      mAxiReadMaster   => ddrReadMaster ,
      mAxiReadSlave    => ddrReadSlave  );
  U_AxiReadSlave : entity work.AxiReadSlaveSim
    port map ( axiClk         => ddrClk,
               axiRst         => ddrRst,
               axiReadMaster  => ddrReadMaster,
               axiReadSlave   => ddrReadSlave );
  U_AxiWriteSlave : entity work.AxiWriteSlaveSim
    port map ( axiClk         => ddrClk,
               axiRst         => ddrRst,
               axiWriteMaster => ddrWriteMaster,
               axiWriteSlave  => ddrWriteSlave );

  U_DdrRecord_0 : entity work.AxiRecord
    generic map ( filename => "ddr_miga.txt" )
    port map ( axiClk    => ddrClk,
               axiMaster => ddrWriteMaster,
               axiSlave  => ddrWriteSlave );

  GEN_DMAIB : for j in 0 to LANES_C generate
    U_IbFifo : entity work.AxiStreamFifoV2
      generic map (
        -- General Configurations
        INT_PIPE_STAGES_G   => 1,
        PIPE_STAGES_G       => 1,
        -- FIFO configurations
        FIFO_ADDR_WIDTH_G   => 4,
        -- AXI Stream Port Configurations
        SLAVE_AXI_CONFIG_G  => AXIO_STREAM_CONFIG_C,
        MASTER_AXI_CONFIG_G => AXIO_STREAM_CONFIG_C)
      port map (
        -- Slave Port
        sAxisClk    => axiClk,
        sAxisRst    => axiRst,
        sAxisMaster => mtpIbMasters(j),
        sAxisSlave  => mtpIbSlaves (j),
        -- Master Port
        mAxisClk    => sysClk,
        mAxisRst    => sysRst,
        mAxisMaster => dmaIbMasters(j),
        mAxisSlave  => dmaIbSlaves (j));
  end generate;

  U_Dma : entity work.AxiStreamDmaV2
    generic map (
      SIMULATION_G      => false,
      DESC_AWIDTH_G     => 12,       -- 4096 entries
      DESC_ARB_G        => false,   -- Round robin to help with timing
      AXIL_BASE_ADDR_G  => x"00000000",
      AXI_READY_EN_G    => true,  -- Using "Packet FIFO" option in AXI Interconnect IP core
      AXIS_READY_EN_G   => true,
      AXIS_CONFIG_G     => AXIO_STREAM_CONFIG_C,
      AXI_DESC_CONFIG_G => AXI_DESC_CONFIG_C,
      AXI_DMA_CONFIG_G  => DMA_AXI_CONFIG_C,
      CHAN_COUNT_G      => LANES_C+1,
      RD_PIPE_STAGES_G  => 1,
      BURST_BYTES_G     => 256,  -- 256B chucks (prevent out of ordering PCIe TLP)
      RD_PEND_THRESH_G  => 1)
    port map (
      axiClk           => sysClk,
      axiRst           => sysRst,
      -- AXI4 Interfaces (
      axiReadMaster    => pciReadMasters,
      axiReadSlave     => pciReadSlaves,
      axiWriteMaster   => pciWriteMasters,
      axiWriteSlave    => pciWriteSlaves,
      axiWriteCtrl     => (others=>AXI_CTRL_UNUSED_C),
      -- AXI4-Lite Interfaces
      axilReadMaster   => dmaAxilReadMaster,
      axilReadSlave    => dmaAxilReadSlave,
      axilWriteMaster  => dmaAxilWriteMaster,
      axilWriteSlave   => dmaAxilWriteSlave,
      -- DMA Interfaces
      sAxisMaster      => dmaIbMasters,
      sAxisSlave       => dmaIbSlaves,
      mAxisMaster      => dmaObMasters,
      mAxisSlave       => dmaObSlaves,
      mAxisCtrl        => (others=>AXI_STREAM_CTRL_UNUSED_C));

  GEN_PCI : for i in 0 to LANES_C+1 generate
    U_PciReadSlave : entity work.AxiReadSlaveSim
      port map ( axiClk         => sysClk,
                 axiRst         => sysRst,
                 axiReadMaster  => pciReadMasters(i),
                 axiReadSlave   => pciReadSlaves (i) );
    U_PciWriteSlave : entity work.AxiWriteSlaveSim
      port map ( axiClk         => sysClk,
                 axiRst         => sysRst,
                 axiWriteMaster => pciWriteMasters(i),
                 axiWriteSlave  => pciWriteSlaves (i) );
  end generate;

  U_PciRecord_0 : entity work.AxiRecord
    generic map ( filename => "pci_dma.txt" )
    port map ( axiClk    => sysClk,
               axiMaster => pciWriteMasters(1),
               axiSlave  => pciWriteSlaves (1) );
  
  process is
  begin
    sysClk <= '1';
    wait for 2.0 ns;
    sysClk <= '0';
    wait for 2.0 ns;
  end process;
  
  process is
  begin
    axiClk <= '1';
    wait for 2.5 ns;
    axiClk <= '0';
    wait for 2.5 ns;
  end process;

  process is
  begin
    axiRst <= '1';
    wait for 100 ns;
    axiRst <= '0';
    wait;
  end process;

  process is
  begin
    axisClk <= '1';
    wait for 3.2 ns;
    axisClk <= '0';
    wait for 3.2 ns;
  end process;

  axisRst <= axiRst;
  sysRst  <= axiRst;

  process is
  begin
    ddrClk <= '1';
    wait for 1.667 ns;
    ddrClk <= '0';
    wait for 1.667 ns;
  end process;

  ddrRst  <= axiRst;

  tdetClk <= axisClk;
  tdetRst <= axisRst;
  
   process is
     procedure wreg(addr : slv(31 downto 0); data : slv(31 downto 0)) is
     begin
       wait until axiClk='0';
       axilWriteMaster.awaddr  <= addr;
       axilWriteMaster.awvalid <= '1';
       axilWriteMaster.wdata   <= data;
       axilWriteMaster.wvalid  <= '1';
       axilWriteMaster.bready  <= '1';
       wait until axiClk='1';
       wait until axilWriteSlave.bvalid='1';
       wait until axiClk='0';
       wait until axiClk='1';
       wait until axiClk='0';
       axilWriteMaster.awvalid <= '0';
       axilWriteMaster.wvalid  <= '0';
       axilWriteMaster.bready  <= '0';
       wait for 50 ns;
     end procedure;
     procedure rreg(addr : slv(31 downto 0)) is
     begin
       wait until axiClk='0';
       axilReadMaster.araddr  <= addr;
       axilReadMaster.arvalid <= '1';
       wait until axiClk='1';
       wait until axilReadSlave.rvalid='1';
       wait until axiClk='0';
       wait until axiClk='1';
       wait until axiClk='0';
       axilReadMaster.arvalid <= '0';
       wait for 50 ns;
     end procedure;
  begin
    axilDone <= '0';
    wait until axiRst='0';
    wait for 20 ns;
    wreg(x"00a00000",x"f0000800"); -- fexLength/Delay
    rreg(x"00a00000");
    wait for 200 ns;
    axilDone <= '1';
    wait;
  end process;

   process is
     procedure wreg(addr : slv(31 downto 0); data : slv(31 downto 0)) is
     begin
       wait until sysClk='0';
       dmaAxilWriteMaster.awaddr  <= addr;
       dmaAxilWriteMaster.awvalid <= '1';
       dmaAxilWriteMaster.wdata   <= data;
       dmaAxilWriteMaster.wvalid  <= '1';
       dmaAxilWriteMaster.bready  <= '1';
       wait until sysClk='1';
       wait until dmaAxilWriteSlave.bvalid='1';
       wait until sysClk='0';
       wait until sysClk='1';
       wait until sysClk='0';
       dmaAxilWriteMaster.awvalid <= '0';
       dmaAxilWriteMaster.wvalid  <= '0';
       dmaAxilWriteMaster.bready  <= '0';
       wait for 50 ns;
     end procedure;
     procedure rreg(addr : slv(31 downto 0)) is
     begin
       wait until sysClk='0';
       dmaAxilReadMaster.araddr  <= addr;
       dmaAxilReadMaster.arvalid <= '1';
       wait until sysClk='1';
       wait until dmaAxilReadSlave.rvalid='1';
       wait until sysClk='0';
       wait until sysClk='1';
       wait until sysClk='0';
       dmaAxilReadMaster.arvalid <= '0';
       wait for 50 ns;
     end procedure;
  begin
    wait until sysRst='0';
    wait for 20 ns;

    wreg(x"0000003C",x"00000000");  -- Desc Cache mode -- Will the XBar work??
    wreg(x"00000028",x"00100000");  -- Max Size
    wreg(x"00000000",x"00000001");  -- Enable Ver
    wreg(x"00000020",x"00000001");  -- Fifo Reset
    wreg(x"00000020",x"00000000");  -- Fifo Reset
    wreg(x"00000008",x"00000001");  -- Continue Enable
    wreg(x"0000000C",x"00000000");  -- Drop Enable
    
    for i in 0 to 31 loop
      wreg(toSlv(16384+4*i,32),(toSlv(i,12)&toSlv(0,20)));
      wreg(x"00000048",toSlv(i,32));
    end loop;

    wreg(x"0000002C",toSlv(1,32)); -- Online
    wreg(x"00000004",toSlv(1,32)); -- Int Enable
    
    wait for 200 ns;
    wait;
  end process;

  GEN_PCIWRM : for i in 0 to LANES_C+1 generate
    pciWriteMastersData(i) <= pciWriteMasters(i).wdata(127 downto 0);
    pciWriteMastersStrb(i) <= pciWriteMasters(i).wstrb( 15 downto 0);
  end generate;
     
end architecture;
  
