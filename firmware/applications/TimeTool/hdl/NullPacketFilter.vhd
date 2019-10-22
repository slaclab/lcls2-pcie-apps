------------------------------------------------------------------------------
-- File       : NullPacketFilter.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-04
-- Last update: 2019-10-15
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
use ieee.std_logic_unsigned.all;

--surf

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

use work.AppPkg.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- This file performs the the prescaling, or the amount of raw data which is stored
-------------------------------------------------------------------------------

entity NullPacketFilter is
   generic (
      TPD_G             : time                := 1 ns;
      DEBUG_G           : boolean             := true);
   port (
      -- System Interface
      sysClk          : in  sl;
      sysRst          : in  sl;
      -- DMA Interfaces  (sysClk domain)
      dataInMaster    : in  AxiStreamMasterType;
      dataInSlave     : out AxiStreamSlaveType;
      dataOutMaster   : out AxiStreamMasterType;
      dataOutSlave    : in  AxiStreamSlaveType;
      -- AXI-Lite Interface
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end NullPacketFilter;

architecture mapping of NullPacketFilter is


   type RegType is record
      master         : AxiStreamMasterType;
      slave          : AxiStreamSlaveType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      counter        : slv(31 downto 0);
      prescalingRate : slv(31 downto 0);
      scratchPad     : slv(31 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      master         => AXI_STREAM_MASTER_INIT_C,
      slave          => AXI_STREAM_SLAVE_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      counter        => (others => '0'),
      prescalingRate => (others => '0'),
      scratchPad     => (others => '0'));

---------------------------------------
-------record intitial value-----------
---------------------------------------


   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal inMaster : AxiStreamMasterType;
   signal inSlave  : AxiStreamSlaveType;
   signal outSlave  : AxiStreamSlaveType;

begin

   ---------------------------------
   -- Input pipeline
   ---------------------------------
   U_AxiStreamPipeline_In : entity surf.AxiStreamPipeline
      generic map (
         TPD_G         => TPD_G,
         PIPE_STAGES_G => 1)
      port map (
         axisClk     => sysClk,         -- [in]
         axisRst     => sysRst,         -- [in]
         sAxisMaster => dataInMaster,   -- [in]
         sAxisSlave  => dataInSlave,    -- [out]
         mAxisMaster => inMaster,       -- [out]
         mAxisSlave  => inSlave);       -- [in]
   
   ---------------------------------
   -- Application
   ---------------------------------
   comb : process (axilReadMaster, axilWriteMaster, inMaster, outSlave, r, sysRst) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin

      -- Latch the current value
      v := r;
      v.scratchPad(0) := ssiGetUserEofe(DSP_AXIS_CONFIG_C, inMaster);

      ------------------------      
      -- AXI-Lite Transactions
      ------------------------      
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister (axilEp, x"0000", 0, v.scratchPad);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      --------------------------------------------
      -- Axi stream logic
      --------------------------------------------
      v.slave.tReady  := '0';

      -- Clear tvalid when acked
      if (outSlave.tready = '1') then
         v.master.tvalid := '0';
         v.master.tlast := '0';
      end if;

      if (inMaster.tValid = '1' and v.master.tValid = '0') then
         v.slave.tready := '1';
         if (ssiGetUserEofe(DSP_AXIS_CONFIG_C, inMaster) = '0') then
            -- Send data through if input isn't a null packet
            -- Really should do a better null packet check but this is probably fine
            v.master := inMaster;
         end if;
      end if;

      -- Combinatoral output above reset
      inSlave        <= v.slave;      

      -------------
      -- Reset
      -------------
      if (sysRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs 
      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;


   end process comb;

   seq : process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

     ---------------------------------
   -- Output pipeline
   ---------------------------------
   U_AxiStreamPipeline_OUT : entity surf.AxiStreamPipeline
      generic map (
         TPD_G         => TPD_G,
         PIPE_STAGES_G => 1)
      port map (
         axisClk     => sysClk,         -- [in]
         axisRst     => sysRst,         -- [in]
         sAxisMaster => r.master,       -- [in]
         sAxisSlave  => outSlave,       -- [out]
         mAxisMaster => dataOutMaster,  -- [out]
         mAxisSlave  => dataOutSlave);  -- [in]


end mapping;
