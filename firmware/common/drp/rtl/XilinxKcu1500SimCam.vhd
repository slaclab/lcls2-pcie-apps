-------------------------------------------------------------------------------
-- File       : XilinxKcu1500Semi.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-04-06
-- Last update: 2018-02-20
-------------------------------------------------------------------------------
-- Description: AXI PCIe Core for KCU1500 board 
--
-- # KCU1500 Product Page
-- https://www.xilinx.com/products/boards-and-kits/dk-u1-kcu1500-g.html
--
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
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPkg.all;
use work.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity XilinxKcu1500SimCam is
   generic (
      TPD_G            : time                  := 1 ns;
      MASTER_G         : boolean               := true;
      BUILD_INFO_G     : BuildInfoType;
      DRIVER_TYPE_ID_G : slv(31 downto 0)      := x"00000000" );
   port (
      ------------------------      
      --  Top Level Interfaces
      ------------------------
      -- System Interface
      sysClk          : out   sl; -- 250MHz
      sysRst          : out   sl;
      -- Application AXI-Lite Interfaces [0x00800000:0x00FFFFFF] (appClk domain)
      appClk          : in    sl; -- 125MHz
      appRst          : in    sl;
      appReadMaster   : out   AxiLiteReadMasterType;
      appReadSlave    : in    AxiLiteReadSlaveType;
      appWriteMaster  : out   AxiLiteWriteMasterType;
      appWriteSlave   : in    AxiLiteWriteSlaveType;
      -------------------
      --  Top Level Ports
      -------------------      
      -- QSFP[0] Ports
      qsfp0RstL       : out   sl;
      qsfp0LpMode     : out   sl;
      qsfp0ModSelL    : out   sl;
      qsfp0ModPrsL    : in    sl;
      -- QSFP[1] Ports
      qsfp1RstL       : out   sl;
      qsfp1LpMode     : out   sl;
      qsfp1ModSelL    : out   sl;
      qsfp1ModPrsL    : in    sl;
      -- Boot Memory Ports 
      flashCsL        : out   sl;
      flashMosi       : out   sl;
      flashMiso       : in    sl := '0';
      flashHoldL      : out   sl;
      flashWp         : out   sl;
      --
      userCclk        : in    sl;
      sck             : out   sl;
      eos             : out   sl;
      -- PCIe Ports 
      pciRstL         : in    sl;
      pciRefClkP      : in    sl;
      pciRefClkN      : in    sl;
      pciRxP          : in    slv(7 downto 0);
      pciRxN          : in    slv(7 downto 0);
      pciTxP          : out   slv(7 downto 0);
      pciTxN          : out   slv(7 downto 0));
end XilinxKcu1500SimCam;

architecture mapping of XilinxKcu1500SimCam is

   constant AXI_ERROR_RESP_C : slv(1 downto 0) := AXI_RESP_OK_C;  -- Always return OK to a MMAP()

   signal regReadMaster  : AxiReadMasterType;
   signal regReadSlave   : AxiReadSlaveType;
   signal regWriteMaster : AxiWriteMasterType;
   signal regWriteSlave  : AxiWriteSlaveType;

   signal phyReadMaster  : AxiLiteReadMasterType;
   signal phyReadSlave   : AxiLiteReadSlaveType;
   signal phyWriteMaster : AxiLiteWriteMasterType;
   signal phyWriteSlave  : AxiLiteWriteSlaveType;

   signal sysClock    : sl;
   signal sysReset    : sl;
   signal systemReset : sl;
   signal cardReset   : sl;
   signal dmaIrq      : sl;

   signal bootCsL     : slv(1 downto 0);
   signal bootSck     : slv(1 downto 0);
   signal bootMosi    : slv(1 downto 0);
   signal bootMiso    : slv(1 downto 0);
   signal di          : slv(3 downto 0);
   signal do          : slv(3 downto 0);

begin

   sysClk <= sysClock;

   systemReset <= sysReset or cardReset;

   dmaIrq <= '0';
   
   U_Rst : entity work.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => sysClock,
         rstIn  => systemReset,
         rstOut => sysRst);

   qsfp0RstL    <= not(systemReset);
   qsfp0LpMode  <= '0';
   qsfp0ModSelL <= '1';
   qsfp1RstL    <= not(systemReset);
   qsfp1LpMode  <= '0';
   qsfp1ModSelL <= '1';

   ---------------
   -- AXI PCIe REG
   --------------- 
   U_REG : entity work.AxiPcieReg
      generic map (
         TPD_G            => TPD_G,
         MASTER_G         => MASTER_G,
         BUILD_INFO_G     => BUILD_INFO_G,
         XIL_DEVICE_G     => "ULTRASCALE",
         BOOT_PROM_G      => "SPI",
         DRIVER_TYPE_ID_G => DRIVER_TYPE_ID_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_C )
      port map (
         -- AXI4 Interfaces
         axiClk             => sysClock,
         axiRst             => sysReset,
         regReadMaster      => regReadMaster,
         regReadSlave       => regReadSlave,
         regWriteMaster     => regWriteMaster,
         regWriteSlave      => regWriteSlave,
         -- PHY AXI-Lite Interfaces
         phyReadMaster      => phyReadMaster,
         phyReadSlave       => phyReadSlave,
         phyWriteMaster     => phyWriteMaster,
         phyWriteSlave      => phyWriteSlave,
         -- (Optional) Application AXI-Lite Interfaces
         appClk             => appClk,
         appRst             => appRst,
         appReadMaster      => appReadMaster,
         appReadSlave       => appReadSlave,
         appWriteMaster     => appWriteMaster,
         appWriteSlave      => appWriteSlave,
         -- Application Force reset
         cardResetOut       => cardReset,
         cardResetIn        => systemReset,
         -- SPI Boot Memory Ports 
         spiCsL             => bootCsL,
         spiSck             => bootSck,
         spiMosi            => bootMosi,
         spiMiso            => bootMiso);

   flashCsL    <= bootCsL(1);
   flashMosi   <= bootMosi(1);
   bootMiso(1) <= flashMiso;
   flashHoldL  <= '1';
   flashWp     <= '1';

   GEN_MASTER : if MASTER_G generate
     ---------------
     -- AXI PCIe PHY
     ---------------   
     U_AxiPciePhy : entity work.PciePhySimCamWrapper
       generic map (
         TPD_G => TPD_G)
       port map (
         -- AXI4 Interfaces
         axiClk         => sysClock,
         axiRst         => sysReset,
         regReadMaster  => regReadMaster,
         regReadSlave   => regReadSlave,
         regWriteMaster => regWriteMaster,
         regWriteSlave  => regWriteSlave,
         phyReadMaster  => phyReadMaster,
         phyReadSlave   => phyReadSlave,
         phyWriteMaster => phyWriteMaster,
         phyWriteSlave  => phyWriteSlave,
         -- PCIe Ports 
         pciRstL        => pciRstL,
         pciRefClkP     => pciRefClkP,
         pciRefClkN     => pciRefClkN,
         pciRxP         => pciRxP,
         pciRxN         => pciRxN,
         pciTxP         => pciTxP,
         pciTxN         => pciTxN);

     U_STARTUPE3 : STARTUPE3
       generic map (
         PROG_USR      => "FALSE",  -- Activate program event security feature. Requires encrypted bitstreams.
         SIM_CCLK_FREQ => 0.0)  -- Set the Configuration Clock Frequency(ns) for simulation
       port map (
         CFGCLK    => open,  -- 1-bit output: Configuration main clock output
         CFGMCLK   => open,  -- 1-bit output: Configuration internal oscillator clock output
         DI        => di,  -- 4-bit output: Allow receiving on the D[3:0] input pins
         EOS       => eos,  -- 1-bit output: Active high output signal indicating the End Of Startup.
         PREQ      => open,  -- 1-bit output: PROGRAM request to fabric output
         DO        => do,  -- 4-bit input: Allows control of the D[3:0] pin outputs
         DTS       => "1110",  -- 4-bit input: Allows tristate of the D[3:0] pins
         FCSBO     => bootCsL(0),  -- 1-bit input: Contols the FCS_B pin for flash access
         FCSBTS    => '0',              -- 1-bit input: Tristate the FCS_B pin
         GSR       => '0',  -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
         GTS       => '0',  -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
         KEYCLEARB => '0',  -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
         PACK      => '0',  -- 1-bit input: PROGRAM acknowledge input
         USRCCLKO  => userCclk,         -- 1-bit input: User CCLK input
         USRCCLKTS => '0',  -- 1-bit input: User CCLK 3-state enable input
         USRDONEO  => '1',  -- 1-bit input: User DONE pin output control
         USRDONETS => '0');  -- 1-bit input: User DONE 3-state enable output
   end generate;

   do          <= "111" & bootMosi(0);
   bootMiso(0) <= di(1);
   sck         <= uOr(bootSck);

end mapping;
