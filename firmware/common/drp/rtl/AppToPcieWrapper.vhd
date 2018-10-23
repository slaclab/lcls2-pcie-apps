-------------------------------------------------------------------------------
-- File       : AppToMigWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-10-16
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
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiDescPkg.all;

entity AppToPcieWrapper is
  port ( -- AxiStream interface
         sAxisClk        : in  slv                 (3 downto 0);
         sAxisRst        : in  slv                 (3 downto 0);
         sAxisMaster     : in  AxiStreamMasterArray(3 downto 0);
         sAxisSlave      : out AxiStreamSlaveArray (3 downto 0);
         sAlmostFull     : out slv                 (3 downto 0);
         sFull           : out slv                 (3 downto 0);
         sAlmostFull     : out slv                 (3 downto 0);
         mAxisClk        : in  sl;
         mAxisRst        : in  sl;
         mAxisMaster     : out AxiStreamMasterArray(3 downto 0);
         mAxisSlave      : in  AxiStreamSlaveArray (3 downto 0);
         --  MIG interface
         mAxiClk         : in  sl;
         mAxiRst         : in  sl;
         memReady        : in  sl;
         mAxiWriteMaster : out AxiWriteMasterArray (3 downto 0);
         mAxiWriteSlave  : in  AxiWriteSlaveArray  (3 downto 0);
         mAxiReadMaster  : out AxiWriteMasterArray (3 downto 0);
         mAxiReadSlave   : in  AxiWriteSlaveArray  (3 downto 0);
         --  Register interface
         axilClk         : in  sl;
         axilRst         : in  sl;
         axilWriteMaster : in  AxiLiteWriteMasterType;
         axilWriteSlave  : out AxiLiteWriteSlaveType;
         axilReadMaster  : in  AxiLiteReadMasterType;
         axilReadSlave   : out AxiLiteReadSlaveType );
end entity; 
