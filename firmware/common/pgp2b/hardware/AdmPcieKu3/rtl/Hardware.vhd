-------------------------------------------------------------------------------
-- File       : Hardware.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2017-11-27
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

use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity Hardware is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := x"0000_0000");
   port (
      ------------------------      
      --  Top Level Interfaces
      ------------------------    
      -- Clock and Reset
      sysClk          : in  sl;
      sysRst          : in  sl;
      -- AXI-Lite Interface (sysClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- DMA Interface (sysClk domain)
      dmaObMasters    : in  AxiStreamMasterArray(7 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray(7 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray(7 downto 0);
      ---------------------
      --  Application Ports
      ---------------------    
      -- QSFP[0] Ports
      qsfp0RefClkP    : in  sl;
      qsfp0RefClkN    : in  sl;
      qsfp0RxP        : in  slv(3 downto 0);
      qsfp0RxN        : in  slv(3 downto 0);
      qsfp0TxP        : out slv(3 downto 0);
      qsfp0TxN        : out slv(3 downto 0);
      -- QSFP[1] Ports
      qsfp1RefClkP    : in  sl;
      qsfp1RefClkN    : in  sl;
      qsfp1RxP        : in  slv(3 downto 0);
      qsfp1RxN        : in  slv(3 downto 0);
      qsfp1TxP        : out slv(3 downto 0);
      qsfp1TxN        : out slv(3 downto 0));
end Hardware;

architecture mapping of Hardware is


   constant LANE_SIZE_G      : natural          := 8;
   
   constant NUM_AXI_MASTERS_C : natural := 1;

   constant PGP_INDEX_C : natural := 0;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 21, 20);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

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
         LANE_SIZE_G      => LANE_SIZE_G,
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
         -- Clock and Reset
         sysClk          => sysClk,
         sysRst          => sysRst,
         drpClk          => drpClk,
         drpRst          => drpRst,
         -- DMA Interfaces (sysClk domain)
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMasters(PGP_INDEX_C),
         axilReadSlave   => axilReadSlaves(PGP_INDEX_C),
         axilWriteMaster => axilWriteMasters(PGP_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PGP_INDEX_C));

end mapping;
