-------------------------------------------------------------------------------
-- File       : DrpTDet.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-24
-- Last update: 2018-10-22
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-dev'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-dev', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiDmaPkg.all;
use work.AxiPciePkg.all;
use work.I2cPkg.all;
use work.MigPkg.all;
use work.Pgp3Pkg.all;
use work.AppMigPkg.all;
use work.TDetPkg.all;

library unisim;
use unisim.vcomponents.all;

entity DrpTDet is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      timingRefClkP : in    sl;
      timingRefClkN : in    sl;
      timingRxP     : in    sl;
      timingRxN     : in    sl;
      timingTxP     : out   sl;
      timingTxN     : out   sl;
      --------------
      --  Core Ports
      --------------
      -- System Ports
      emcClk       : in    sl;
      userClkP     : in    sl;
      userClkN     : in    sl;
      swDip        : in    slv(3 downto 0);
      led          : out   slv(7 downto 0);
      scl          : inout sl;
      sda          : inout sl;
      i2c_rst_l    : out   sl;
      -- QSFP[0] Ports
      qsfp0RstL    : out   sl;
      qsfp0LpMode  : out   sl;
      qsfp0ModSelL : out   sl;
      qsfp0ModPrsL : in    sl;
      -- QSFP[1] Ports
      qsfp1RstL    : out   sl;
      qsfp1LpMode  : out   sl;
      qsfp1ModSelL : out   sl;
      qsfp1ModPrsL : in    sl;
      -- Boot Memory Ports 
      flashCsL     : out   sl;
      flashMosi    : out   sl;
      flashMiso    : in    sl;
      flashHoldL   : out   sl;
      flashWp      : out   slv          (1 downto 0);
      -- DDR Ports
      ddrClkP      : in    slv          (1 downto 0);
      ddrClkN      : in    slv          (1 downto 0);
      ddrOut       : out   DdrOutArray  (1 downto 0);
      ddrInOut     : inout DdrInOutArray(1 downto 0);
      -- PCIe Ports
      pciRstL      : in    sl;
      pciRefClkP   : in    sl;
      pciRefClkN   : in    sl;
      pciRxP       : in    slv(7 downto 0);
      pciRxN       : in    slv(7 downto 0);
      pciTxP       : out   slv(7 downto 0);
      pciTxN       : out   slv(7 downto 0);
      -- Extended PCIe Interface
      pciExtRefClkP   : in    sl;
      pciExtRefClkN   : in    sl;
      pciExtRxP       : in    slv(7 downto 0);
      pciExtRxN       : in    slv(7 downto 0);
      pciExtTxP       : out   slv(7 downto 0);
      pciExtTxN       : out   slv(7 downto 0) );
end DrpTDet;

architecture top_level of DrpTDet is

   signal sysClks    : slv(1 downto 0);
   signal sysRsts    : slv(1 downto 0);
   signal clk200     : slv(1 downto 0);
   signal rst200     : slv(1 downto 0);
   signal irst200    : slv(1 downto 0);
   signal urst200    : slv(1 downto 0);
   signal userReset  : slv(1 downto 0);
   signal userSwDip  : slv(3 downto 0);
   signal userLed    : slv(7 downto 0);

   signal axilClks         : slv                    (1 downto 0);
   signal axilRsts         : slv                    (1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray (1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray  (1 downto 0);
   signal axilWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray (1 downto 0);

   signal dmaObMasters    : AxiStreamMasterArray (9 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray  (9 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray (9 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray  (9 downto 0);

   signal hwClks          : slv                 (7 downto 0);
   signal hwRsts          : slv                 (7 downto 0);
   signal hwObMasters     : AxiStreamMasterArray(7 downto 0);
   signal hwObSlaves      : AxiStreamSlaveArray (7 downto 0);
   signal hwIbMasters     : AxiStreamMasterArray(7 downto 0);
   signal hwIbSlaves      : AxiStreamSlaveArray (7 downto 0);
   signal hwIbAlmostFull  : slv                 (7 downto 0);
   signal hwIbFull        : slv                 (7 downto 0);

   signal memReady        : slv                (1 downto 0);
   signal memWriteMasters : AxiWriteMasterArray(7 downto 0);
   signal memWriteSlaves  : AxiWriteSlaveArray (7 downto 0);
   signal memReadMasters  : AxiReadMasterArray (7 downto 0);
   signal memReadSlaves   : AxiReadSlaveArray  (7 downto 0);

   constant RNG_AXIL_MASTERS_C : IntegerArray(3 downto 0) := (5,4,3,0);
   constant NUM_AXIL_MASTERS_SUM : integer := 6;
   signal mAxilReadMasters  : AxiLiteReadMasterArray (RNG_AXIL_MASTERS_C(3) downto 0);
   signal mAxilReadSlaves   : AxiLiteReadSlaveArray  (RNG_AXIL_MASTERS_C(3) downto 0);
   signal mAxilWriteMasters : AxiLiteWriteMasterArray(RNG_AXIL_MASTERS_C(3) downto 0);
   signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray (RNG_AXIL_MASTERS_C(3) downto 0);
   constant AXIL0_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(3 downto 0) := (
     0 => (baseAddr     => x"00800000",
           addrBits     => 21,
           connectivity => x"FFFF"),
     1 => (baseAddr     => x"00A00000",
           addrBits     => 21,
           connectivity => x"FFFF"),
     2 => (baseAddr     => x"00C00000",
           addrBits     => 21,
           connectivity => x"FFFF"),
     3 => (baseAddr     => x"00E00000",
           addrBits     => 21,
           connectivity => x"FFFF") );
   constant AXIL1_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(1 downto 0) := (
     0 => (baseAddr     => x"00800000",
           addrBits     => 21,
           connectivity => x"FFFF"),
     1 => (baseAddr     => x"00A00000",
           addrBits     => 21,
           connectivity => x"FFFF") );

   signal migConfig : MigConfigArray(7 downto 0) := (others=>MIG_CONFIG_INIT_C);
   signal migStatus : MigStatusArray(7 downto 0);
   

   signal mmcmClkOut : Slv3Array(1 downto 0);
   signal mmcmRstOut : Slv3Array(1 downto 0);

   constant NDET_C   : integer := 8;
   signal tdetClk    : sl;
   signal tdetRst    : sl;
   signal tdetTiming : TDetTimingArray(NDET_C-1 downto 0);
   signal tdetEvent  : TDetEventArray (NDET_C-1 downto 0);
   signal tdetStatus : TDetStatusArray(NDET_C-1 downto 0);

   constant DEVICE_MAP_C : I2cAxiLiteDevArray(3 downto 0) := (
    -----------------------
    -- PC821 I2C DEVICES --
    -----------------------
    -- PCA9548A I2C Mux
    0 => MakeI2cAxiLiteDevType( "1110100", 8, 0, '0' ),
    -- QSFP1, QSFP0, EEPROM;  I2C Mux = 1, 4, 5
    1 => MakeI2cAxiLiteDevType( "1010000", 8, 8, '0' ),
    -- SI570                  I2C Mux = 2
    2 => MakeI2cAxiLiteDevType( "1011101", 8, 8, '0' ),
    -- Fan                    I2C Mux = 3
    3 => MakeI2cAxiLiteDevType( "1001100", 8, 8, '0' ) );

   signal usrClkP, usrClkN : slv(1 downto 0);
   signal emcClock         : slv(1 downto 0);

   signal rdDescReq : AxiReadDmaDescReqArray(7 downto 0);
   signal rdDescRet : AxiReadDmaDescRetArray(7 downto 0);
   signal rdDescReqAck : slv(7 downto 0);
   signal rdDescRetAck : slv(7 downto 0);

   signal qsfpModPrsL  : slv(1 downto 0);

   constant AXIO_STREAM_CONFIG_C : AxiStreamConfigType := (
     TSTRB_EN_C    => false,
     TDATA_BYTES_C => 16,
     TDEST_BITS_C  => 0,
     TID_BITS_C    => 0,
     TKEEP_MODE_C  => TKEEP_NORMAL_C,
     TUSER_BITS_C  => 2,
     TUSER_MODE_C  => TUSER_NORMAL_C);

begin

  i2c_rst_l      <= '1';
  qsfpModPrsL(0) <= qsfp0ModPrsL;
  qsfpModPrsL(1) <= qsfp1ModPrsL;

  U_AxilXbar0 : entity work.AxiLiteCrossbar
    generic map ( NUM_SLAVE_SLOTS_G  => 1,
                  NUM_MASTER_SLOTS_G => 4,
                  MASTERS_CONFIG_G   => AXIL0_CROSSBAR_MASTERS_CONFIG_C )
    port map    ( axiClk              => axilClks        (0),
                  axiClkRst           => axilRsts        (0),
                  sAxiWriteMasters(0) => axilWriteMasters(0),
                  sAxiWriteSlaves (0) => axilWriteSlaves (0),
                  sAxiReadMasters (0) => axilReadMasters (0),
                  sAxiReadSlaves  (0) => axilReadSlaves  (0),
                  mAxiWriteMasters    => mAxilWriteMasters(3 downto 0),
                  mAxiWriteSlaves     => mAxilWriteSlaves (3 downto 0),
                  mAxiReadMasters     => mAxilReadMasters (3 downto 0),
                  mAxiReadSlaves      => mAxilReadSlaves  (3 downto 0) );

  U_AxilXbar1 : entity work.AxiLiteCrossbar
    generic map ( NUM_SLAVE_SLOTS_G  => 1,
                  NUM_MASTER_SLOTS_G => 2,
                  MASTERS_CONFIG_G   => AXIL1_CROSSBAR_MASTERS_CONFIG_C )
    port map    ( axiClk              => axilClks        (1),
                  axiClkRst           => axilRsts        (1),
                  sAxiWriteMasters(0) => axilWriteMasters(1),
                  sAxiWriteSlaves (0) => axilWriteSlaves (1),
                  sAxiReadMasters (0) => axilReadMasters (1),
                  sAxiReadSlaves  (0) => axilReadSlaves  (1),
                  mAxiWriteMasters    => mAxilWriteMasters(5 downto 4),
                  mAxiWriteSlaves     => mAxilWriteSlaves (5 downto 4),
                  mAxiReadMasters     => mAxilReadMasters (5 downto 4),
                  mAxiReadSlaves      => mAxilReadSlaves  (5 downto 4) );
  
  U_I2C : entity work.AxiI2cRegMaster
    generic map ( DEVICE_MAP_G   => DEVICE_MAP_C,
                  AXI_CLK_FREQ_G => 125.0E+6 )
    port map ( scl            => scl,
               sda            => sda,
               axiReadMaster  => mAxilReadMasters (RNG_AXIL_MASTERS_C(0)+3),
               axiReadSlave   => mAxilReadSlaves  (RNG_AXIL_MASTERS_C(0)+3),
               axiWriteMaster => mAxilWriteMasters(RNG_AXIL_MASTERS_C(0)+3),
               axiWriteSlave  => mAxilWriteSlaves (RNG_AXIL_MASTERS_C(0)+3),
               axiClk         => axilClks(0),
               axiRst         => axilRsts(0) );

  U_Timing : entity work.TDetTiming
    generic map ( NDET_G          => 8,
                  AXIL_BASEADDR_G => AXIL0_CROSSBAR_MASTERS_CONFIG_C(2).baseAddr )
    port map ( -- AXI-Lite Interface
      axilClk          => axilClks(0),
      axilRst          => axilRsts(0),
      axilReadMaster   => maxilReadMasters (RNG_AXIL_MASTERS_C(0)+2),
      axilReadSlave    => maxilReadSlaves  (RNG_AXIL_MASTERS_C(0)+2),
      axilWriteMaster  => maxilWriteMasters(RNG_AXIL_MASTERS_C(0)+2),
      axilWriteSlave   => maxilWriteSlaves (RNG_AXIL_MASTERS_C(0)+2),
      -- Timing Interface
      tdetClk          => tdetClk   ,
      tdetTiming       => tdetTiming,
      tdetEvent        => tdetEvent ,
      tdetStatus       => tdetStatus,
      -- Timing Phy Ports
      timingRxP        => timingRxP,
      timingRxN        => timingRxN,
      timingTxP        => timingTxP,
      timingTxN        => timingTxN,
      timingRefClkInP  => timingRefClkP,
      timingRefClkInN  => timingRefClkN );

  tdetClk <= mmcmClkOut(0)(2);
  tdetRst <= mmcmRstOut(0)(2);
  
  GEN_SEMI : for i in 0 to 1 generate
    clk200  (i) <= mmcmClkOut(i)(0);
    axilClks(i) <= mmcmClkOut(i)(1);
    axilRsts(i) <= mmcmRstOut(i)(1);
    
    -- Forcing BUFG for reset that's used everywhere      
    U_BUFG : BUFG
      port map (
        I => mmcmRstOut(i)(0),
        O => rst200(i));
    
    irst200(i) <= rst200(i) or userReset(i);
    -- Forcing BUFG for reset that's used everywhere      
    U_BUFGU : BUFG
      port map (
        I => irst200(i),
        O => urst200(i));

    U_MMCM : entity work.ClockManagerUltraScale
      generic map ( INPUT_BUFG_G       => false,
                    NUM_CLOCKS_G       => 3,
                    CLKIN_PERIOD_G     => 4.0,
                    DIVCLK_DIVIDE_G    => 1,
                    CLKFBOUT_MULT_F_G  => 5.0,  -- 1.25 GHz
                    CLKOUT0_DIVIDE_F_G => 6.25, -- 200 MHz
                    CLKOUT1_DIVIDE_G   => 10,   -- 125 MHz
                    CLKOUT2_DIVIDE_G   =>  8 )  -- 156.25 MHz
      port map ( clkIn     => sysClks(1-i),
                 rstIn     => sysRsts(1-i),
                 clkOut    => mmcmClkOut(i),
                 rstOut    => mmcmRstOut(i) );
    
    U_Hw : entity work.TDetSemi
      generic map ( DEBUG_G => (i<1) )
      port map (
        ------------------------      
        --  Top Level Interfaces
        ------------------------         
        -- AXI-Lite Interface (axilClk domain)
        axilClk         => axilClks        (i),
        axilRst         => axilRsts        (i),
        axilReadMaster  => mAxilReadMasters (RNG_AXIL_MASTERS_C(2*i)+1),
        axilReadSlave   => mAxilReadSlaves  (RNG_AXIL_MASTERS_C(2*i)+1),
        axilWriteMaster => mAxilWriteMasters(RNG_AXIL_MASTERS_C(2*i)+1),
        axilWriteSlave  => mAxilWriteSlaves (RNG_AXIL_MASTERS_C(2*i)+1),
        -- DMA Interface (dmaClk domain)
        dmaClks         => hwClks        (4*i+3 downto 4*i),
        dmaRsts         => hwRsts        (4*i+3 downto 4*i),
        dmaObMasters    => hwObMasters   (4*i+3 downto 4*i),
        dmaObSlaves     => hwObSlaves    (4*i+3 downto 4*i),
        dmaIbMasters    => hwIbMasters   (4*i+3 downto 4*i),
        dmaIbSlaves     => hwIbSlaves    (4*i+3 downto 4*i),
        dmaIbAlmostFull => hwIbAlmostFull(4*i+3 downto 4*i),
        dmaIbFull       => hwIbFull      (4*i+3 downto 4*i),
        ------------------
        --  TDET Ports
        ------------------       
        tdetClk         => tdetClk,
        tdetClkRst      => tdetRst,
        tdetTiming      => tdetTiming(4*i+3 downto 4*i),
        tdetEvent       => tdetEvent (4*i+3 downto 4*i),
        tdetStatus      => tdetStatus(4*i+3 downto 4*i),
        modPrsL         => qsfpModPrsL(i) );

     GEN_HWDMA : for j in 4*i+0 to 4*i+3 generate
       U_HwDma : entity work.AppToMigDma
         generic map ( AXI_BASE_ADDR_G     => (toSlv(j,2) & toSlv(0,30)) )
         port map ( sAxisClk        => hwClks         (j),
                    sAxisRst        => hwRsts         (j),
                    sAxisMaster     => hwIbMasters    (j),
                    sAxisSlave      => hwIbSlaves     (j),
                    sAlmostFull     => hwIbAlmostFull (j),
                    sFull           => hwIbFull       (j),
                    mAxiClk         => clk200         (i),
                    mAxiRst         => urst200        (i),
                    mAxiWriteMaster => memWriteMasters(j),
                    mAxiWriteSlave  => memWriteSlaves (j),
                    rdDescReq       => rdDescReq      (j), -- exchange
                    rdDescReqAck    => rdDescReqAck   (j),
                    rdDescRet       => rdDescRet      (j),
                    rdDescRetAck    => rdDescRetAck   (j),
                    memReady        => memReady       (i),
                    config          => migConfig      (j),
                    status          => migStatus      (j) );
       U_ObFifo : entity work.AxiStreamFifoV2
         generic map ( FIFO_ADDR_WIDTH_G   => 4,
                       SLAVE_AXI_CONFIG_G  => AXIO_STREAM_CONFIG_C,
                       MASTER_AXI_CONFIG_G => PGP3_AXIS_CONFIG_C )
         port map ( sAxisClk    => sysClks     (i),
                    sAxisRst    => sysRsts     (i),
                    sAxisMaster => dmaObMasters(j+i),
                    sAxisSlave  => dmaObSlaves (j+1),
                    sAxisCtrl   => open,
                    mAxisClk    => hwClks      (j),
                    mAxisRst    => hwRsts      (j),
                    mAxisMaster => hwObMasters (j),
                    mAxisSlave  => hwObSlaves  (j) );
     end generate;

     U_Mig2Pcie : entity work.MigToPcieDma
       generic map ( LANES_G          => 4 )
--                     DEBUG_G          => (i<1) )
       port map ( axiClk          => clk200(i),
                  axiRst          => rst200(i),
                  usrRst          => userReset(i),
                  axiReadMasters  => memReadMasters(4*i+3 downto 4*i),
                  axiReadSlaves   => memReadSlaves (4*i+3 downto 4*i),
                  rdDescReq       => rdDescReq     (4*i+3 downto 4*i),
                  rdDescAck       => rdDescReqAck  (4*i+3 downto 4*i),
                  rdDescRet       => rdDescRet     (4*i+3 downto 4*i),
                  rdDescRetAck    => rdDescRetAck  (4*i+3 downto 4*i),
                  axisMasters     => dmaIbMasters  (5*i+4 downto 5*i),
                  axisSlaves      => dmaIbSlaves   (5*i+4 downto 5*i),
                  axilClk         => axilClks        (i),
                  axilRst         => axilRsts        (i),
                  axilWriteMaster => mAxilWriteMasters(RNG_AXIL_MASTERS_C(2*i)+0),
                  axilWriteSlave  => mAxilWriteSlaves (RNG_AXIL_MASTERS_C(2*i)+0),
                  axilReadMaster  => mAxilReadMasters (RNG_AXIL_MASTERS_C(2*i)+0),
                  axilReadSlave   => mAxilReadSlaves  (RNG_AXIL_MASTERS_C(2*i)+0),
                  migConfig       => migConfig      (4*i+3 downto 4*i),
                  migStatus       => migStatus      (4*i+3 downto 4*i) );
  end generate;

  U_Core : entity work.XilinxKcu1500Core
    generic map (
      TPD_G             => TPD_G,
      DRIVER_TYPE_ID_G  => toSlv(0,32),
      DMA_SIZE_G        => 5,
      BUILD_INFO_G      => BUILD_INFO_G,
      DMA_AXIS_CONFIG_G => AXIO_STREAM_CONFIG_C )
    port map (
      ------------------------      
      --  Top Level Interfaces
      ------------------------
      userClk156      => open,
--      userSwDip       => userSwDip,
--      userLed         => userLed,
      -- System Clock and Reset
      dmaClk          => sysClks(0),
      dmaRst          => sysRsts(0),
      -- DMA Interfaces
      dmaObMasters    => dmaObMasters   (5*0+4 downto 5*0),
      dmaObSlaves     => dmaObSlaves    (5*0+4 downto 5*0),
      dmaIbMasters    => dmaIbMasters   (5*0+4 downto 5*0),
      dmaIbSlaves     => dmaIbSlaves    (5*0+4 downto 5*0),
      --
      -- AXI-Lite Interface
      appClk          => axilClks        (0),
      appRst          => axilRsts        (0),
      appReadMaster   => axilReadMasters (0),
      appReadSlave    => axilReadSlaves  (0),
      appWriteMaster  => axilWriteMasters(0),
      appWriteSlave   => axilWriteSlaves (0),
      --------------
      --  Core Ports
      --------------
      emcClk          => emcClk,
      userClkP        => userClkP,
      userClkN        => userClkN,
--      swDip           => swDip,
--      led             => led,
      -- QSFP[0] Ports
      qsfp0RstL       => qsfp0RstL   ,
      qsfp0LpMode     => qsfp0LpMode ,
      qsfp0ModSelL    => qsfp0ModSelL,
      qsfp0ModPrsL    => qsfp0ModPrsL,
      -- QSFP[1] Ports
      qsfp1RstL       => qsfp1RstL   ,
      qsfp1LpMode     => qsfp1LpMode ,
      qsfp1ModSelL    => qsfp1ModSelL,
      qsfp1ModPrsL    => qsfp1ModPrsL,
      -- Boot Memory Ports 
      flashCsL        => flashCsL  ,
      flashMosi       => flashMosi ,
      flashMiso       => flashMiso ,
      flashHoldL      => flashHoldL,
      flashWp         => flashWp(0),
       -- PCIe Ports 
      pciRstL         => pciRstL,
      pciRefClkP      => pciRefClkP,
      pciRefClkN      => pciRefClkN,
      pciRxP          => pciRxP,
      pciRxN          => pciRxN,
      pciTxP          => pciTxP,
      pciTxN          => pciTxN );

  U_Extended : entity work.XilinxKcu1500PcieExtendedCore
    generic map ( TPD_G             => TPD_G,
                  BUILD_INFO_G      => BUILD_INFO_G,
                  DRIVER_TYPE_ID_G  => toSlv(1,32),
                  DMA_SIZE_G        => 5,
                  DMA_AXIS_CONFIG_G => AXIO_STREAM_CONFIG_C )
    port map (
      ------------------------      
      --  Top Level Interfaces
      ------------------------        
      -- DMA Interfaces
      dmaClk         => sysClks(1),
      dmaRst         => sysRsts(1),
      --
      dmaObMasters    => dmaObMasters   (5*1+4 downto 5*1),
      dmaObSlaves     => dmaObSlaves    (5*1+4 downto 5*1),
      dmaIbMasters    => dmaIbMasters   (5*1+4 downto 5*1),
      dmaIbSlaves     => dmaIbSlaves    (5*1+4 downto 5*1),
      -- AXI-Lite Interface
      appClk         => axilClks        (1),
      appRst         => axilRsts        (1),
      appReadMaster  => axilReadMasters (1),
      appReadSlave   => axilReadSlaves  (1),
      appWriteMaster => axilWriteMasters(1),
      appWriteSlave  => axilWriteSlaves (1),
      --------------
      --  Core Ports
      --------------   
      -- Extended PCIe Ports 
      pciRstL        => pciRstL,
      pciExtRefClkP  => pciExtRefClkP,
      pciExtRefClkN  => pciExtRefClkN,
      pciExtRxP      => pciExtRxP,
      pciExtRxN      => pciExtRxN,
      pciExtTxP      => pciExtTxP,
      pciExtTxN      => pciExtTxN);

  U_MIG0 : entity work.MigA
    port map ( axiReady        => memReady(0),
               --
               axiClk          => clk200         (0),
               axiRst          => urst200        (0),
               axiWriteMasters => memWriteMasters(3 downto 0),
               axiWriteSlaves  => memWriteSlaves (3 downto 0),
               axiReadMasters  => memReadMasters (3 downto 0),
               axiReadSlaves   => memReadSlaves  (3 downto 0),
               --
               ddrClkP         => ddrClkP (0),
               ddrClkN         => ddrClkN (0),
               ddrOut          => ddrOut  (0),
               ddrInOut        => ddrInOut(0) );

  U_MIG1 : entity work.MigB
    port map ( axiReady        => memReady(1),
               --
               axiClk          => clk200         (1),
               axiRst          => urst200        (1),
               axiWriteMasters => memWriteMasters(7 downto 4),
               axiWriteSlaves  => memWriteSlaves (7 downto 4),
               axiReadMasters  => memReadMasters (7 downto 4),
               axiReadSlaves   => memReadSlaves  (7 downto 4),
               --
               ddrClkP         => ddrClkP (1),
               ddrClkN         => ddrClkN (1),
               ddrOut          => ddrOut  (1),
               ddrInOut        => ddrInOut(1) );
  
  -- Unused user signals
  userLed <= (others => '0');


end top_level;
