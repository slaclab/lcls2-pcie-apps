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


begin


      U_TimeStamper : entity work.TimeStamper
      generic map (
         TPD_G => TPD_G)
      port map (
         -- System Clock and Reset
         sysClk          => sysClk,
         sysRst          => sysRst,
         -- DMA Interface (sysClk domain)
         dataInMaster    => dataInMaster,
         dataInSlave     => dataInSlave,
         dataOutMaster   => dataOutMaster,
         dataOutSlave    => dataOutSlave,
         -- AXI-Lite Interface (sysClk domain)
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,
         -- Timing information (sysClk domain)
         timingBus       => timingBus,
         -- PGP TX OP-codes (pgpTxClk domains)
         pgpTxClk        => pgpTxClk,
         pgpTxIn         => pgpTxIn);

end mapping;
