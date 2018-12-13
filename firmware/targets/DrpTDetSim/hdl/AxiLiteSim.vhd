-------------------------------------------------------------------------------
-- File       : AxiLiteSim.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-10-27
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
use work.AxiLitePkg.all;

entity AxiLiteSim is
  port    (
    --  System view
    axilClk          : in  sl;
    axilRst          : in  sl;
    axilReadMaster   : in  AxiLiteReadMasterType;
    axilReadSlave    : out AxiLiteReadSlaveType;
    axilWriteMaster  : in  AxiLiteWriteMasterType;
    axilWriteSlave   : out AxiLiteWriteSlaveType;
    --  Application view
    appClk          : in  sl; 
    appRst          : in  sl;
    appReadMaster   : out AxiLiteReadMasterType;
    appReadSlave    : in  AxiLiteReadSlaveType;
    appWriteMaster  : out AxiLiteWriteMasterType;
    appWriteSlave   : in  AxiLiteWriteSlaveType );
end AxiLiteSim;

architecture mapping of AxiLiteSim is

   constant NUM_AXI_MASTERS_C : natural := 13;

   constant DMA_INDEX_C     : natural := 0;
   constant PHY_INDEX_C     : natural := 1;
   constant VERSION_INDEX_C : natural := 2;
   constant BPI_INDEX_C     : natural := 3;
   constant SPI0_INDEX_C    : natural := 4;
   constant SPI1_INDEX_C    : natural := 5;
   constant AXIS_MON_IB_C   : natural := 6;
   constant AXIS_MON_OB_C   : natural := 7;
   constant APP0_INDEX_C    : natural := 8;
   constant APP1_INDEX_C    : natural := 9;
   constant APP2_INDEX_C    : natural := 10;
   constant APP3_INDEX_C    : natural := 11;
   constant APP4_INDEX_C    : natural := 12;

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      DMA_INDEX_C     => (
         baseAddr     => x"0000_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      PHY_INDEX_C     => (
         baseAddr     => x"0001_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      VERSION_INDEX_C => (
         baseAddr     => x"0002_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      BPI_INDEX_C     => (
         baseAddr     => x"0003_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      SPI0_INDEX_C    => (
         baseAddr     => x"0004_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      SPI1_INDEX_C    => (
         baseAddr     => x"0005_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      AXIS_MON_IB_C   => (
         baseAddr     => x"0006_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      AXIS_MON_OB_C   => (
         baseAddr     => x"0007_0000",
         addrBits     => 16,
         connectivity => x"FFFF"),
      APP0_INDEX_C    => (
         baseAddr     => x"0008_0000",
         addrBits     => 19,
         connectivity => x"FFFF"),
      APP1_INDEX_C    => (
         baseAddr     => x"0010_0000",
         addrBits     => 20,
         connectivity => x"FFFF"),
      APP2_INDEX_C    => (
         baseAddr     => x"0020_0000",
         addrBits     => 21,
         connectivity => x"FFFF"),
      APP3_INDEX_C    => (
         baseAddr     => x"0040_0000",
         addrBits     => 22,
         connectivity => x"FFFF"),
      APP4_INDEX_C    => (
         baseAddr     => x"0080_0000",
         addrBits     => 23,
         connectivity => x"FFFF"));

   constant APP_CROSSBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(0 downto 0) := (
      0               => (
         baseAddr     => x"00000000",
         addrBits     => 24,
         connectivity => x"FFFF"));

   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal mAxilReadMaster  : AxiLiteReadMasterType;
   signal mAxilReadSlave   : AxiLiteReadSlaveType;
   signal mAxilWriteMaster : AxiLiteWriteMasterType;
   signal mAxilWriteSlave  : AxiLiteWriteSlaveType;

begin

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         DEC_ERROR_RESP_G   => AXI_RESP_OK_C,  -- Can't respond with error to a memory mapped bus
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
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

   --------------------------------------   
   -- Combine APP AXI-Lite buses together
   --------------------------------------   
   U_APP_XBAR : entity work.AxiLiteCrossbar
      generic map (
         DEC_ERROR_RESP_G   => AXI_RESP_OK_C,  -- Can't respond with error to a memory mapped bus
         NUM_SLAVE_SLOTS_G  => (APP4_INDEX_C-APP0_INDEX_C+1),
         NUM_MASTER_SLOTS_G => 1,
         MASTERS_CONFIG_G   => APP_CROSSBAR_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters    => axilWriteMasters(APP4_INDEX_C downto APP0_INDEX_C),
         sAxiWriteSlaves     => axilWriteSlaves(APP4_INDEX_C downto APP0_INDEX_C),
         sAxiReadMasters     => axilReadMasters(APP4_INDEX_C downto APP0_INDEX_C),
         sAxiReadSlaves      => axilReadSlaves(APP4_INDEX_C downto APP0_INDEX_C),
         mAxiWriteMasters(0) => mAxilWriteMaster,
         mAxiWriteSlaves(0)  => mAxilWriteSlave,
         mAxiReadMasters(0)  => mAxilReadMaster,
         mAxiReadSlaves(0)   => mAxilReadSlave);

   ----------------------------------
   -- Map the AXI-Lite to Application
   ----------------------------------               
   U_AxiLiteAsync : entity work.AxiLiteAsync
      generic map (
         COMMON_CLK_G    => false,
         NUM_ADDR_BITS_G => 24)
      port map (
         -- Slave Interface
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => mAxilReadMaster,
         sAxiReadSlave   => mAxilReadSlave,
         sAxiWriteMaster => mAxilWriteMaster,
         sAxiWriteSlave  => mAxilWriteSlave,
         -- Master Interface
         mAxiClk         => appClk,
         mAxiClkRst      => appRst,
         mAxiReadMaster  => appReadMaster,
         mAxiReadSlave   => appReadSlave,
         mAxiWriteMaster => appWriteMaster,
         mAxiWriteSlave  => appWriteSlave);

end mapping;
  
