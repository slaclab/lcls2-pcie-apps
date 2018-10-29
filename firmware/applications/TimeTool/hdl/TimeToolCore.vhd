-------------------------------------------------------------------------------
-- File       : TimeToolCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-04
-- Last update: 2018-07-11
-------------------------------------------------------------------------------
-- Description:
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
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.ALL;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPkg.all;
use work.SsiPkg.all;
use work.AxiPciePkg.all;
use work.TimingPkg.all;
use work.Pgp2bPkg.all;

library unisim;
use unisim.vcomponents.all;


entity TimeToolCore is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      DEBUG_G             : boolean       := true );
   port (
      -- System Interface
      sysClk          : in    sl;
      sysRst          : in    sl;
      -- DMA Interfaces (sysClk domain)
      dataInMaster    : in    AxiStreamMasterType;
      dataInSlave     : out   AxiStreamSlaveType;
      dataOutMaster   : out   AxiStreamMasterType;
      dataOutSlave    : in    AxiStreamSlaveType;
      -- AXI-Lite Interface (sysClk domain)
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- Timing information (sysClk domain)
      timingBus       : in TimingBusType;
      -- PGP TX OP-codes (pgpTxClk domains)
      pgpTxClk        : in slv(5 downto 0);
      pgpTxIn         : out Pgp2bTxInArray(5 downto 0));
end TimeToolCore;

architecture mapping of TimeToolCore is

   --FEX stands for feature extracted
   signal masterRepeaterToFEXorPrescaler  : AxiStreamMasterArray(NUM_MASTERS_G-1 downto 0);
   signal slaveRepeaterToFEXorPrescaler  : AxiStreamSlaveArray(NUM_MASTERS_G-1 downto 0);

   signal masterFEXorPrescalerToCombiner  : AxiStreamMasterArray(NUM_MASTERS_G-1 downto 0);
   signal slaveFEXorPrescalerToCombiner   : AxiStreamSlaveArray(NUM_MASTERS_G-1 downto 0);

begin


      --------------------------------------------
      --breaking out the data from detector
      --------------------------------------------

      U_TimeStamper : entity work.AxiStreamRepeater
      generic map (
         NUM_MASTERS_G =>'2',
         TPD_G => TPD_G)
      port map (
         -- System Clock and Reset
         sysClk          => sysClk,
         sysRst          => sysRst,
         -- DMA Interface (sysClk domain)
         sAxisMaster     => dataInMaster,
         sAxisSlave      => dataInSlave,
         mAxisMasters    => masterRepeaterToFEXorPrescaler,
         mAxisSlaves     => slaveRepeaterToFEXorPrescaler);

      --------------------------------------------
      --sending one of the repeated signals from module above to FEX or prescaling
      --------------------------------------------


      U_TimeStamper : entity work.TimeToolPrescaler
      generic map (
         TPD_G => TPD_G)
      port map (
         -- System Clock and Reset
         sysClk          => sysClk,
         sysRst          => sysRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => masterRepeaterToFEXorPrescaler(0),
         dataInSlave     => slaveRepeaterToFEXorPrescaler(0),
         dataOutMaster   => masterFEXorPrescalerToCombiner(0),
         dataOutSlave    => slaveFEXorPrescalerToCombiner(0),
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

      --------------------------------------------
      --AxiStreamBatcherEventBuilder Combines them back together
      --------------------------------------------

      U_TimeStamper : entity work.AxiStreamBatcherEventBuilder
      generic map (
         NUM_MASTERS_G =>'2',
         TPD_G => TPD_G)
      port map (
         -- System Clock and Reset
         sysClk          => sysClk,
         sysRst          => sysRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => dataInMaster,
         dataInSlave     => dataInSlave,
         dataOutMaster   => dataOutMaster,
         dataOutSlave    => dataOutSlave);

end mapping;
