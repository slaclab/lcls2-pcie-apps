-------------------------------------------------------------------------------
-- File       : HardwareSemi.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2018-11-11
-------------------------------------------------------------------------------
-- Description: HardwareSemi File
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
use work.AxiPciePkg.all;
use work.Pgp3Pkg.all;

library unisim;
use unisim.vcomponents.all;

entity HardwareSemi is
   generic (
      TPD_G            : time             := 1 ns;
      AXIL_CLK_FREQ_G  : real             := 125.0E6;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := x"0000_0000");
   port (
      ------------------------      
      --  Top Level Interfaces
      ------------------------    
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- DMA Interface
      dmaClks         : out slv                 (3 downto 0);
      dmaRsts         : out slv                 (3 downto 0);
      dmaObMasters    : in  AxiStreamMasterArray(3 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray (3 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(3 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray (3 downto 0);
      dmaIbAlmostFull : in  slv                 (3 downto 0);
      dmaIbFull       : in  slv                 (3 downto 0);
      axiCtrl         : in  AxiCtrlType := AXI_CTRL_UNUSED_C;
      ---------------------
      --  HardwareSemi Ports
      ---------------------    
      -- QSFP[0] Ports
      qsfp0RefClkP    : in  slv(1 downto 0);
      qsfp0RefClkN    : in  slv(1 downto 0);
      qsfp0RxP        : in  slv(3 downto 0);
      qsfp0RxN        : in  slv(3 downto 0);
      qsfp0TxP        : out slv(3 downto 0);
      qsfp0TxN        : out slv(3 downto 0) );
end HardwareSemi;

architecture mapping of HardwareSemi is

   constant NUM_LANES_C       : natural := 4;
   constant NUM_AXI_MASTERS_C : natural := 2;

   constant PGP_INDEX_C     : natural := 0;
   constant SIM_INDEX_C     : natural := 1;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 22, 20);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal intObMasters     : AxiStreamMasterArray(NUM_LANES_C-1 downto 0);
   signal intObSlaves      : AxiStreamSlaveArray (NUM_LANES_C-1 downto 0);
   signal dmaObAlmostFull  : slv                 (NUM_LANES_C-1 downto 0) := (others=>'0');

   signal txOpCodeEn       : slv                 (NUM_LANES_C-1 downto 0);
   signal txOpCode         : Slv8Array           (NUM_LANES_C-1 downto 0);
   signal rxOpCodeEn       : slv                 (NUM_LANES_C-1 downto 0);
   signal rxOpCode         : Slv8Array           (NUM_LANES_C-1 downto 0);

   signal idmaClks         : slv                 (NUM_LANES_C-1 downto 0);
   signal idmaRsts         : slv                 (NUM_LANES_C-1 downto 0);

   signal sAxisCtrl : AxiStreamCtrlArray(NUM_LANES_C-1 downto 0) := (others=>AXI_STREAM_CTRL_UNUSED_C);
   
   constant DEBUG_C : boolean := false;

   component ila_0
     port ( clk     : in sl;
            probe0  : in slv(255 downto 0) );
   end component;

   signal sAxiCtrl : AxiCtrlType;
begin

   dmaClks <= idmaClks;
   dmaRsts <= idmaRsts;

  GEN_DEBUG : if DEBUG_C generate
    U_SPAUSE : entity work.Synchronizer
      port map ( clk      => idmaClks(0),
                 dataIn   => axiCtrl .pause,
                 dataOut  => sAxiCtrl.pause );
    U_SOFLOW : entity work.Synchronizer
      port map ( clk      => idmaClks(0),
                 dataIn   => axiCtrl .overflow,
                 dataOut  => sAxiCtrl.overflow );
    U_ILA : ila_0
      port map ( clk                  => idmaClks(0),
                 probe0(           0) => sAxisCtrl(0).idle,
                 probe0(           1) => sAxisCtrl(0).pause,
                 probe0(           2) => sAxisCtrl(0).overflow,
                 probe0(           3) => dmaIbAlmostFull(0),
                 probe0(           4) => txOpCodeEn(0),
                 probe0(12 downto  5) => txOpCode(0),
                 probe0(          13) => sAxiCtrl.pause,
                 probe0(          14) => sAxiCtrl.overflow,
                 probe0(          15) => dmaIbFull(0),
                 probe0(255 downto 16) => (others=>'0') );
  end generate;
   
   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   --------------
   -- PGP Modules
   --------------
   U_Pgp : entity work.PgpLaneWrapper
      generic map (
         TPD_G            => TPD_G,
         REFCLK_WIDTH_G   => 1,
         NUM_VC_G         => 1,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
         AXI_BASE_ADDR_G  => AXI_BASE_ADDR_G)
      port map (
         -- QSFP[0] Ports
         qsfp0RefClkP    => qsfp0RefClkP(0)  ,
         qsfp0RefClkN    => qsfp0RefClkN(0)  ,
         qsfp0RxP        => qsfp0RxP    ,
         qsfp0RxN        => qsfp0RxN    ,
         qsfp0TxP        => qsfp0TxP    ,
         qsfp0TxN        => qsfp0TxN    ,
         -- DMA Interfaces (dmaClk domain)
         dmaClks         => idmaClks    ,
         dmaRsts         => idmaRsts    ,
         dmaObMasters    => intObMasters,
         dmaObSlaves     => intObSlaves ,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves ,
         dmaIbFull       => dmaIbFull   ,
         -- OOB Signals
         txOpCodeEn      => txOpCodeEn,
         txOpCode        => txOpCode,
         rxOpCodeEn      => rxOpCodeEn,
         rxOpCode        => rxOpCode,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters (PGP_INDEX_C),
         axilReadSlave   => axilReadSlaves  (PGP_INDEX_C),
         axilWriteMaster => axilWriteMasters(PGP_INDEX_C),
         axilWriteSlave  => axilWriteSlaves (PGP_INDEX_C) );

   GEN_LANE : for i in 0 to NUM_LANES_C-1 generate
     U_TxOpCode : entity work.AppTxOpCode
       port map ( clk          => idmaClks       (i),
                  rst          => idmaRsts       (i),
--                  rxFull       => dmaIbAlmostFull(i),
                  rxFull       => sAxisCtrl(i).pause,
                  txFull       => dmaObAlmostFull(i),
                  txOpCodeEn   => txOpCodeEn     (i),
                  txOpCode     => txOpCode       (i) );
   end generate;
   
   U_TxSim : entity work.AppTxSim
     generic map ( DMA_AXIS_CONFIG_C => PGP3_AXIS_CONFIG_C )
     port map ( axilClk         => axilClk,
                axilRst         => axilRst,
                axilReadMaster  => axilReadMasters (SIM_INDEX_C),
                axilReadSlave   => axilReadSlaves  (SIM_INDEX_C),
                axilWriteMaster => axilWriteMasters(SIM_INDEX_C),
                axilWriteSlave  => axilWriteSlaves (SIM_INDEX_C),
                --
                clk             => idmaClks,
                rst             => idmaRsts,
                saxisMasters    => dmaObMasters,
                saxisSlaves     => dmaObSlaves,
                maxisMasters    => intObMasters,
                maxisSlaves     => intObSlaves,
                rxOpCodeEn      => rxOpCodeEn,
                rxOpCode        => rxOpCode,
                txFull          => dmaObAlmostFull );

end mapping;
