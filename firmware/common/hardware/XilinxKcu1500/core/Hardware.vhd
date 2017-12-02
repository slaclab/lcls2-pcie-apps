-------------------------------------------------------------------------------
-- File       : Hardware.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-22
-- Last update: 2017-10-24
-------------------------------------------------------------------------------
-- Description: Hardware File
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
use work.BuildInfoPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPciePkg.all;
use work.TimingPkg.all;

library unisim;
use unisim.vcomponents.all;

entity Hardware is
   port (
      ------------------------      
      --  Top Level Interfaces
      ------------------------    
      -- System Clock and Reset
      sysClk          : in  sl;
      sysRst          : in  sl;
      userClk156      : in  sl;
      userClk100      : in  sl;
      -- AXI-Lite Interface
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- DMA Interface
      dmaObMasters     : in  AxiStreamMasterArray(7 downto 0);
      dmaObSlaves      : out AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters     : out AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves      : in  AxiStreamSlaveArray(7 downto 0);
      ---------------------
      --  Hardware Ports
      ---------------------    
      -- QSFP[0] Ports
      qsfp0RefClkP    : in  slv(1 downto 0);
      qsfp0RefClkN    : in  slv(1 downto 0);
      qsfp0RxP        : in  slv(3 downto 0);
      qsfp0RxN        : in  slv(3 downto 0);
      qsfp0TxP        : out slv(3 downto 0);
      qsfp0TxN        : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP    : in  slv(1 downto 0);
      qsfp1RefClkN    : in  slv(1 downto 0);
      qsfp1RxP        : in  slv(3 downto 0);
      qsfp1RxN        : in  slv(3 downto 0);
      qsfp1TxP        : out slv(3 downto 0);
      qsfp1TxN        : out slv(3 downto 0));
end Hardware;

architecture mapping of Hardware is

   -- Defined module generics as constants (in case partial reconfiguration build)
   constant TPD_G            : time             := 1 ns;
   constant AXI_ERROR_RESP_G : slv(1 downto 0)  := BAR0_ERROR_RESP_C;
   constant AXI_BASE_ADDR_G  : slv(31 downto 0) := BAR0_BASE_ADDR_G;

   constant NUM_AXI_MASTERS_C : natural := 2;

   constant PGP_INDEX_C     : natural := 0;
   constant EVR_INDEX_C     : natural := 1;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 23, 20);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal evrClk       : sl;
   signal evrRst       : sl;
   signal evrTimingBus : TimingBusType;

   signal evrRxP : slv(1 downto 0);
   signal evrRxN : slv(1 downto 0);
   signal evrTxP : slv(1 downto 0);
   signal evrTxN : slv(1 downto 0);

   signal drpClk   : sl;
   signal drpReset : sl;
   signal drpRst   : sl;

begin

   U_DRP_CLK : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => 8)
      port map (
         I   => sysClk,
         CE  => '1',
         CLR => '0',
         O   => drpClk);

   U_RstSync : entity work.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => drpClk,
         asyncRst => sysRst,
         syncRst  => drpReset);

   U_RstPipe : entity work.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => drpClk,
         rstIn  => drpReset,
         rstOut => drpRst);

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
         axiClk              => sysClk,
         axiClkRst           => sysRst,
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
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(PGP_INDEX_C).baseAddr)
      port map (
         -- QSFP[0] Ports
         qsfp0RefClkP    => qsfp0RefClkP,
         qsfp0RefClkN    => qsfp0RefClkN,
         qsfp0RxP        => qsfp0RxP,
         qsfp0RxN        => qsfp0RxN,
         qsfp0TxP        => qsfp0TxP,
         qsfp0TxN        => qsfp0TxN,
         -- QSFP[1] Ports
         qsfp1RefClkP    => qsfp1RefClkP,
         qsfp1RefClkN    => qsfp1RefClkN,
         qsfp1RxP        => qsfp1RxP,
         qsfp1RxN        => qsfp1RxN,
         qsfp1TxP        => qsfp1TxP,
         qsfp1TxN        => qsfp1TxN,
         -- EVR GT Serial Ports
         evrRxP          => evrRxP,
         evrRxN          => evrRxN,
         evrTxP          => evrTxP,
         evrTxN          => evrTxN,
         -- DRP Clock and Reset
         drpClk          => drpClk,
         drpRst          => drpRst,         
         -- DMA Interfaces (sysClk domain)
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- Timing Interface (evrClk domain)
         evrClk          => evrClk,
         evrRst          => evrRst,
         evrTimingBus    => evrTimingBus,
         -- AXI-Lite Interface (sysClk domain)
         sysClk          => sysClk,
         sysRst          => sysRst,
         axilReadMaster  => axilReadMasters(PGP_INDEX_C),
         axilReadSlave   => axilReadSlaves(PGP_INDEX_C),
         axilWriteMaster => axilWriteMasters(PGP_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PGP_INDEX_C));         

   ------------------
   -- Timing Receiver
   ------------------
   U_Evr : entity work.EvrFrontEnd
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(EVR_INDEX_C).baseAddr)
      port map (
         -- Timing Interface (evrClk domain)
         evrClk          => evrClk,
         evrRst          => evrRst,
         evrTimingBus    => evrTimingBus,
         -- DRP Clock and Reset
         drpClk          => drpClk,
         drpRst          => drpRst,
         -- AXI-Lite Interface (sysClk domain)
         sysClk          => sysClk,
         sysRst          => sysRst,
         axilReadMaster  => axilReadMasters(EVR_INDEX_C),
         axilReadSlave   => axilReadSlaves(EVR_INDEX_C),
         axilWriteMaster => axilWriteMasters(EVR_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(EVR_INDEX_C),
         -- GT Serial Ports
         userClk156      => userClk156,
         userClk100      => userClk100,
         evrRxP          => evrRxP,
         evrRxN          => evrRxN,
         evrTxP          => evrTxP,
         evrTxN          => evrTxN);

end mapping;
