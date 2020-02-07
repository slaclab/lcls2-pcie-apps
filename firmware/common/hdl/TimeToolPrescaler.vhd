------------------------------------------------------------------------------
-- File       : TimeToolCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-04
-- Last update: 2019-12-19
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;


library timetool;
use timetool.AppPkg.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- This file performs the the prescaling, or the amount of raw data which is stored
-------------------------------------------------------------------------------

entity TimeToolPrescaler is
   generic (
      TPD_G   : time    := 1 ns;
      DEBUG_G : boolean := true);
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
end TimeToolPrescaler;

architecture mapping of TimeToolPrescaler is

   type StateType is (
      IDLE_S,
      MOVE_S,
      SEND_NULL_S,
      BLOWOFF_S);

   type RegType is record
      master         : AxiStreamMasterType;
      slave          : AxiStreamSlaveType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      debug_counter  : slv(31 downto 0);
      counter        : slv(31 downto 0);
      prescalingRate : slv(31 downto 0);
      scratchPad     : slv(31 downto 0);
      state          : StateType;
      validate_state : slv(2 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      master         => axiStreamMasterInit(DSP_AXIS_CONFIG_C),
      slave          => AXI_STREAM_SLAVE_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      counter        => (others => '0'),
      debug_counter  => (others => '0'),
      prescalingRate => toSlv(9, 32),
      scratchPad     => (others => '0'),
      state          => IDLE_S,
      validate_state => (others => '0'));

---------------------------------------
-------record intitial value-----------
---------------------------------------


   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal inMaster : AxiStreamMasterType;
   signal inSlave  : AxiStreamSlaveType;
   signal outSlave : AxiStreamSlaveType;

begin

   ---------------------------------
   -- Input Pipeline
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

      ------------------------      
      -- AXI-Lite Transactions
      ------------------------      
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister (axilEp, x"000", 0, v.scratchPad);
      axiSlaveRegister (axilEp, x"004", 0, v.prescalingRate);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      --------------------------------------------
      -- Axi stream flow control
      --------------------------------------------
      v.slave.tReady := '0';
      if (outSlave.tReady = '1') then
         v.master.tvalid := '0';
         v.master.tlast  := '0';
      end if;

      case r.state is

         when IDLE_S =>
            v.validate_state := (others => '0');  --debugging signal
            -- Check in a new txn has arrived and can be forwarded
            -- Then decide whether to forward the data or send a NULL based
            -- on the prescaling rate.
            if v.master.tvalid = '0' and inMaster.tValid = '1' then
               -- Don't ack yet, will do this in later states
               v.counter := r.counter + 1;
               if r.counter = r.prescalingRate then
                  v.state   := MOVE_S;
                  v.counter := (others => '0');
               else
                  v.state := SEND_NULL_S;
               end if;
            end if;

         when MOVE_S =>
            ------------------------------
            -- send regular frame
            ------------------------------
            v.validate_state(0) := '1';     --debugging signal
            if v.master.tValid = '0' and inMaster.tValid = '1' then
               v.slave.tready := '1';   -- ack the txn
               v.master       := inMaster;  --copies one 'transfer' (trasnfer is the AXI jargon for one TVALID/TREADY transaction)
               if (inMaster.tLast = '1') then
                  v.state := IDLE_S;
               end if;
               v.validate_state(1) := '1';  --debugging signal
                                            --
               if v.master.tLast = '0' and v.master.tValid = '1' then
                  v.debug_counter := v.debug_counter + 1;
               elsif v.master.tLast = '1' and v.master.tValid = '1' then
                  v.debug_counter := (others => '0');
               end if;
            end if;

         when SEND_NULL_S =>
            ------------------------------
            -- send null frame
            ------------------------------
            if v.master.tValid = '0' and inMaster.tValid = '1' then
               v.master.tValid := '1';
               v.master.tLast  := '1';
               v.slave.tready  := '1';  -- ack the txn

               v.master.tkeep    := (others => '0');
               v.master.tKeep(0) := '1';
               ssiSetUserEofe(DSP_AXIS_CONFIG_C, v.master, '1');

               v.state := BLOWOFF_S;
            end if;

         when BLOWOFF_S =>
            if (inMaster.tValid = '1') then
               v.slave.tready := '1';   -- ack the txn
               if (inMaster.tLast = '1') then
                  v.state := IDLE_S;
               end if;
            end if;

      end case;

      -- Combinatoral outputs above reset
      inSlave <= v.slave;

      -- Reset
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
