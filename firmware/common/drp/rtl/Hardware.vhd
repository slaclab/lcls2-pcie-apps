-------------------------------------------------------------------------------
-- File       : Hardware.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-26
-- Last update: 2018-06-12
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
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -- DMA Interface
      dmaClks         : out slv                 (7 downto 0);
      dmaRsts         : out slv                 (7 downto 0);
      dmaObMasters    : in  AxiStreamMasterArray(7 downto 0);
      dmaObSlaves     : out AxiStreamSlaveArray (7 downto 0);
      dmaIbMasters    : out AxiStreamMasterArray(7 downto 0);
      dmaIbSlaves     : in  AxiStreamSlaveArray (7 downto 0);
      dmaIbAlmostFull : in  slv                 (7 downto 0);
      dmaIbFull       : in  slv                 (7 downto 0);
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

   constant NUM_LANES_C       : natural := 8;
   constant NUM_AXI_MASTERS_C : natural := 3;

   constant PGPA_INDEX_C     : natural := 0;
   constant PGPB_INDEX_C     : natural := 1;
   constant SIM_INDEX_C      : natural := 2;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 20, 18);

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

begin

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
   U_PgpA : entity work.PgpLaneWrapper
      generic map (
         TPD_G            => TPD_G,
         REFCLK_WIDTH_G   => 1,
         NUM_VC_G         => 1,        
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(PGPA_INDEX_C).baseAddr )
      port map (
         -- QSFP[0] Ports
         qsfp0RefClkP    => qsfp0RefClkP(0),
         qsfp0RefClkN    => qsfp0RefClkN(0),
         qsfp0RxP        => qsfp0RxP,
         qsfp0RxN        => qsfp0RxN,
         qsfp0TxP        => qsfp0TxP,
         qsfp0TxN        => qsfp0TxN,
         -- DMA Interfaces (dmaClk domain)
         dmaClks         => idmaClks    (3 downto 0),
         dmaRsts         => idmaRsts    (3 downto 0),
         dmaObMasters    => intObMasters(3 downto 0),
         dmaObSlaves     => intObSlaves (3 downto 0),
         dmaIbMasters    => dmaIbMasters(3 downto 0),
         dmaIbSlaves     => dmaIbSlaves (3 downto 0),
         dmaIbFull       => dmaIbFull   (3 downto 0),
         -- OOB Signals
         txOpCodeEn      => txOpCodeEn  (3 downto 0),
         txOpCode        => txOpCode    (3 downto 0),
         rxOpCodeEn      => rxOpCodeEn  (3 downto 0),
         rxOpCode        => rxOpCode    (3 downto 0),
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters (PGPA_INDEX_C),
         axilReadSlave   => axilReadSlaves  (PGPA_INDEX_C),
         axilWriteMaster => axilWriteMasters(PGPA_INDEX_C),
         axilWriteSlave  => axilWriteSlaves (PGPA_INDEX_C) );

   U_PgpB : entity work.PgpLaneWrapper
      generic map (
         TPD_G            => TPD_G,
         REFCLK_WIDTH_G   => 1,
         NUM_VC_G         => 1,        
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(PGPB_INDEX_C).baseAddr )
      port map (
         -- QSFP[0] Ports
         qsfp0RefClkP    => qsfp1RefClkP(0),
         qsfp0RefClkN    => qsfp1RefClkN(0),
         qsfp0RxP        => qsfp1RxP,
         qsfp0RxN        => qsfp1RxN,
         qsfp0TxP        => qsfp1TxP,
         qsfp0TxN        => qsfp1TxN,
         -- DMA Interfaces (dmaClk domain)
         dmaClks         => idmaClks    (7 downto 4),
         dmaRsts         => idmaRsts    (7 downto 4),
         dmaObMasters    => intObMasters(7 downto 4),
         dmaObSlaves     => intObSlaves (7 downto 4),
         dmaIbMasters    => dmaIbMasters(7 downto 4),
         dmaIbSlaves     => dmaIbSlaves (7 downto 4),
         dmaIbFull       => dmaIbFull   (7 downto 4),
         -- OOB Signals
         txOpCodeEn      => txOpCodeEn  (7 downto 4),
         txOpCode        => txOpCode    (7 downto 4),
         rxOpCodeEn      => rxOpCodeEn  (7 downto 4),
         rxOpCode        => rxOpCode    (7 downto 4),
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters (PGPB_INDEX_C),
         axilReadSlave   => axilReadSlaves  (PGPB_INDEX_C),
         axilWriteMaster => axilWriteMasters(PGPB_INDEX_C),
         axilWriteSlave  => axilWriteSlaves (PGPB_INDEX_C) );
   
   GEN_LANE : for i in 0 to NUM_LANES_C-1 generate
     U_TxOpCode : entity work.AppTxOpCode
       port map ( clk          => idmaClks       (i),
                  rst          => idmaRsts       (i),
                  rxFull       => dmaIbAlmostFull(i),
                  txFull       => dmaObAlmostFull(i),
                  txOpCodeEn   => txOpCodeEn     (i),
                  txOpCode     => txOpCode       (i) );
   end generate;

   U_TxSim : entity work.AppTxSim
     generic map ( DMA_AXIS_CONFIG_C => DMA_AXIS_CONFIG_C,
                   NUM_LANES_G       => 8 )
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
