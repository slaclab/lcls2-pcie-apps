-------------------------------------------------------------------------------
-- File       : Mig1D.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-08-03
-- Last update: 2018-10-20
-------------------------------------------------------------------------------
-- Description: Wrapper for the MIG core
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-co1re', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;
use work.AxiPciePkg.all;
use work.MigPkg.all;

library unisim;
use unisim.vcomponents.all;

entity Mig1D is
   generic ( TPD_G        : time          := 1 ns );
   port (
      -- AXI MEM Interface (sysClk domain)
      axiReady        : out   sl;
      --
      axiClk          : in    sl;
      axiRst          : in    sl;
      axiWriteMaster  : in    AxiWriteMasterType;
      axiWriteSlave   : out   AxiWriteSlaveType;
      axiReadMaster   : in    AxiReadMasterType;
      axiReadSlave    : out   AxiReadSlaveType;
      -- DDR Ports
      ddrClkP         : in    sl;
      ddrClkN         : in    sl;
      ddrOut          : out   DdrOutType;
      ddrInOut        : inout DdrInOutType);
end Mig1D;

architecture mapping of Mig1D is

   component XilinxKcu1500Mig1Core
      port (
         c0_init_calib_complete     : out   std_logic;
         dbg_clk                    : out   std_logic;
         c0_sys_clk_p               : in    std_logic;
         c0_sys_clk_n               : in    std_logic;
         dbg_bus                    : out   std_logic_vector(511 downto 0);
         c0_ddr4_adr                : out   std_logic_vector(16 downto 0);
         c0_ddr4_ba                 : out   std_logic_vector(1 downto 0);
         c0_ddr4_cke                : out   std_logic_vector(0 downto 0);
         c0_ddr4_cs_n               : out   std_logic_vector(1 downto 0);
         c0_ddr4_dm_dbi_n           : inout std_logic_vector(7 downto 0);
         c0_ddr4_dq                 : inout std_logic_vector(63 downto 0);
         c0_ddr4_dqs_c              : inout std_logic_vector(7 downto 0);
         c0_ddr4_dqs_t              : inout std_logic_vector(7 downto 0);
         c0_ddr4_odt                : out   std_logic_vector(0 downto 0);
         c0_ddr4_bg                 : out   std_logic_vector(0 downto 0);
         c0_ddr4_reset_n            : out   std_logic;
         c0_ddr4_act_n              : out   std_logic;
         c0_ddr4_ck_c               : out   std_logic_vector(0 downto 0);
         c0_ddr4_ck_t               : out   std_logic_vector(0 downto 0);
         c0_ddr4_ui_clk             : out   std_logic;
         c0_ddr4_ui_clk_sync_rst    : out   std_logic;
         c0_ddr4_aresetn            : in    std_logic;
         c0_ddr4_s_axi_awid         : in    std_logic_vector(3 downto 0);
         c0_ddr4_s_axi_awaddr       : in    std_logic_vector(31 downto 0);
         c0_ddr4_s_axi_awlen        : in    std_logic_vector(7 downto 0);
         c0_ddr4_s_axi_awsize       : in    std_logic_vector(2 downto 0);
         c0_ddr4_s_axi_awburst      : in    std_logic_vector(1 downto 0);
         c0_ddr4_s_axi_awlock       : in    std_logic_vector(0 downto 0);
         c0_ddr4_s_axi_awcache      : in    std_logic_vector(3 downto 0);
         c0_ddr4_s_axi_awprot       : in    std_logic_vector(2 downto 0);
         c0_ddr4_s_axi_awqos        : in    std_logic_vector(3 downto 0);
         c0_ddr4_s_axi_awvalid      : in    std_logic;
         c0_ddr4_s_axi_awready      : out   std_logic;
         c0_ddr4_s_axi_wdata        : in    std_logic_vector(511 downto 0);
         c0_ddr4_s_axi_wstrb        : in    std_logic_vector(63 downto 0);
         c0_ddr4_s_axi_wlast        : in    std_logic;
         c0_ddr4_s_axi_wvalid       : in    std_logic;
         c0_ddr4_s_axi_wready       : out   std_logic;
         c0_ddr4_s_axi_bready       : in    std_logic;
         c0_ddr4_s_axi_bid          : out   std_logic_vector(3 downto 0);
         c0_ddr4_s_axi_bresp        : out   std_logic_vector(1 downto 0);
         c0_ddr4_s_axi_bvalid       : out   std_logic;
         c0_ddr4_s_axi_arid         : in    std_logic_vector(3 downto 0);
         c0_ddr4_s_axi_araddr       : in    std_logic_vector(31 downto 0);
         c0_ddr4_s_axi_arlen        : in    std_logic_vector(7 downto 0);
         c0_ddr4_s_axi_arsize       : in    std_logic_vector(2 downto 0);
         c0_ddr4_s_axi_arburst      : in    std_logic_vector(1 downto 0);
         c0_ddr4_s_axi_arlock       : in    std_logic_vector(0 downto 0);
         c0_ddr4_s_axi_arcache      : in    std_logic_vector(3 downto 0);
         c0_ddr4_s_axi_arprot       : in    std_logic_vector(2 downto 0);
         c0_ddr4_s_axi_arqos        : in    std_logic_vector(3 downto 0);
         c0_ddr4_s_axi_arvalid      : in    std_logic;
         c0_ddr4_s_axi_arready      : out   std_logic;
         c0_ddr4_s_axi_rready       : in    std_logic;
         c0_ddr4_s_axi_rlast        : out   std_logic;
         c0_ddr4_s_axi_rvalid       : out   std_logic;
         c0_ddr4_s_axi_rresp        : out   std_logic_vector(1 downto 0);
         c0_ddr4_s_axi_rid          : out   std_logic_vector(3 downto 0);
         c0_ddr4_s_axi_rdata        : out   std_logic_vector(511 downto 0);
         sys_rst                    : in    std_logic);
   end component;

   signal ddrWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal ddrWriteSlave  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal ddrReadMaster  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
   signal ddrReadSlave   : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;

   signal memWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
   signal memWriteSlave  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
   signal memReadMaster  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
   signal memReadSlave   : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;

   signal ddrClk     : sl;
   signal ddrRst     : sl;
   signal ddrCalDone : sl;
   signal coreReset  : sl;
   signal coreResetN : sl;
   signal coreAresetN : sl;
   signal sysRstL    : sl;

   constant AXI_CONFIG_C : AxiConfigType := axiConfig( 32, 64, 4, 8 );
   
begin

   sysRstL <= not(axiRst);

   U_axiReady : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axiClk,
         dataIn  => ddrCalDone,
         dataOut => axiReady);

   U_MIG : XilinxKcu1500Mig1Core
      port map (
         c0_init_calib_complete     => ddrCalDone,
         dbg_clk                    => open,
         c0_sys_clk_p               => ddrClkP,
         c0_sys_clk_n               => ddrClkN,
         dbg_bus                    => open,
         c0_ddr4_adr                => ddrOut.addr,
         c0_ddr4_ba                 => ddrOut.ba,
         c0_ddr4_cke                => ddrOut.cke,
         c0_ddr4_cs_n               => ddrOut.csL,
         c0_ddr4_dm_dbi_n           => ddrInOut.dm(7 downto 0),
         c0_ddr4_dq                 => ddrInOut.dq(63 downto 0),
         c0_ddr4_dqs_c              => ddrInOut.dqsC(7 downto 0),
         c0_ddr4_dqs_t              => ddrInOut.dqsT(7 downto 0),
         c0_ddr4_odt                => ddrOut.odt,
         c0_ddr4_bg                 => ddrOut.bg,
         c0_ddr4_reset_n            => ddrOut.rstL,
         c0_ddr4_act_n              => ddrOut.actL,
         c0_ddr4_ck_c               => ddrOut.ckC,
         c0_ddr4_ck_t               => ddrOut.ckT,
         c0_ddr4_ui_clk             => ddrClk,
         c0_ddr4_ui_clk_sync_rst    => coreReset,
         c0_ddr4_aresetn            => coreAresetN,
         c0_ddr4_s_axi_awid         => ddrWriteMaster.awid(3 downto 0),
         c0_ddr4_s_axi_awaddr       => ddrWriteMaster.awaddr(31 downto 0),
         c0_ddr4_s_axi_awlen        => ddrWriteMaster.awlen(7 downto 0),
         c0_ddr4_s_axi_awsize       => ddrWriteMaster.awsize(2 downto 0),
         c0_ddr4_s_axi_awburst      => ddrWriteMaster.awburst(1 downto 0),
         c0_ddr4_s_axi_awlock       => "0",
         c0_ddr4_s_axi_awcache      => ddrWriteMaster.awcache(3 downto 0),
         c0_ddr4_s_axi_awprot       => ddrWriteMaster.awprot(2 downto 0),
         c0_ddr4_s_axi_awqos        => x"0",
         c0_ddr4_s_axi_awvalid      => ddrWriteMaster.awvalid,
         c0_ddr4_s_axi_awready      => ddrWriteSlave.awready,
         c0_ddr4_s_axi_wdata        => ddrWriteMaster.wdata(511 downto 0),
         c0_ddr4_s_axi_wstrb        => ddrWriteMaster.wstrb(63 downto 0),
         c0_ddr4_s_axi_wlast        => ddrWriteMaster.wlast,
         c0_ddr4_s_axi_wvalid       => ddrWriteMaster.wvalid,
         c0_ddr4_s_axi_wready       => ddrWriteSlave.wready,
         c0_ddr4_s_axi_bready       => ddrWriteMaster.bready,
         c0_ddr4_s_axi_bid          => ddrWriteSlave.bid(3 downto 0),
         c0_ddr4_s_axi_bresp        => ddrWriteSlave.bresp(1 downto 0),
         c0_ddr4_s_axi_bvalid       => ddrWriteSlave.bvalid,
         c0_ddr4_s_axi_arid         => ddrReadMaster.arid(3 downto 0),
         c0_ddr4_s_axi_araddr       => ddrReadMaster.araddr(31 downto 0),
         c0_ddr4_s_axi_arlen        => ddrReadMaster.arlen(7 downto 0),
         c0_ddr4_s_axi_arsize       => ddrReadMaster.arsize(2 downto 0),
         c0_ddr4_s_axi_arburst      => ddrReadMaster.arburst(1 downto 0),
         c0_ddr4_s_axi_arlock       => "0",
         c0_ddr4_s_axi_arcache      => ddrReadMaster.arcache(3 downto 0),
         c0_ddr4_s_axi_arprot       => "000",
         c0_ddr4_s_axi_arqos        => x"0",
         c0_ddr4_s_axi_arvalid      => ddrReadMaster.arvalid,
         c0_ddr4_s_axi_arready      => ddrReadSlave.arready,
         c0_ddr4_s_axi_rready       => ddrReadMaster.rready,
         c0_ddr4_s_axi_rlast        => ddrReadSlave.rlast,
         c0_ddr4_s_axi_rvalid       => ddrReadSlave.rvalid,
         c0_ddr4_s_axi_rresp        => ddrReadSlave.rresp(1 downto 0),
         c0_ddr4_s_axi_rid          => ddrReadSlave.rid(3 downto 0),
         c0_ddr4_s_axi_rdata        => ddrReadSlave.rdata(511 downto 0),
         sys_rst                    => axiRst);

   coreResetN <= not coreReset;
   
   U_Rst : entity work.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => ddrClk,
         rstIn  => coreResetN,
         rstOut => coreAresetN);

   U_WriteFifo : entity work.AxiWritePathFifo
     generic map ( AXI_CONFIG_G => AXI_CONFIG_C )
     port map (
       -- Slave Interfaces
         sAxiClk          => axiClk,
         sAxiRst          => axiRst,
         sAxiWriteMaster  => axiWriteMaster,
         sAxiWriteSlave   => axiWriteSlave,
         -- Master Interface
         mAxiClk          => ddrClk,
         mAxiRst          => ddrRst,
         mAxiWriteMaster  => ddrWriteMaster,
         mAxiWriteSlave   => ddrWriteSlave );

   U_ReadFifo : entity work.AxiReadPathFifo
     generic map ( AXI_CONFIG_G => AXI_CONFIG_C )
     port map (
       -- Slave Interfaces
         sAxiClk          => axiClk,
         sAxiRst          => axiRst,
         sAxiReadMaster   => axiReadMaster,
         sAxiReadSlave    => axiReadSlave,
         -- Master Interface
         mAxiClk          => ddrClk,
         mAxiRst          => ddrRst,
         mAxiReadMaster   => ddrReadMaster,
         mAxiReadSlave    => ddrReadSlave );

end mapping;
