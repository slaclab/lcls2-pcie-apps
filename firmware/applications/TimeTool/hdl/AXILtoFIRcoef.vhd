------------------------------------------------------------------------------
-- File       : AXILtoFIRcoef.vhd
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

use work.AppPkg.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- This file performs the accumulation for the background subtraction
-------------------------------------------------------------------------------

entity AXILtoFIRcoef is
   generic (
      TPD_G   : time    := 1 ns;
      DEBUG_G : boolean := true);
   port (
      -- System Interface
      sysClk          : in  sl;
      sysRst          : in  sl;
      -- DMA Interfaces  (sysClk domain)
      dataOutMaster   : out AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      dataOutSlave    : in  AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
      configOutMaster : out AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      configOutSlave  : in  AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

      -- AXI-Lite Interface
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end AXILtoFIRcoef;

architecture mapping of AXILtoFIRcoef is

   constant CAMERA_RESOLUTION_BITS : positive := 8;
   constant CAMERA_PIXEL_NUMBER    : positive := 2048;
   constant FIR_COEFFICIENT_LENGTH : positive := 32;

   type StateType is (
      IDLE_S,
      WAIT_RELOAD_S);

   type RegType is record
      reloadMaster    : AxiStreamMasterType;
      configMaster    : AxiStreamMasterType;
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
      scratchPad      : slv(31 downto 0);
      newCoefficients : sl;
      state           : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      reloadMaster    => axiStreamMasterInit(DSP_AXIS_CONFIG_C),
      configMaster    => axiStreamMasterInit(DSP_AXIS_DOWNSIZED_CONFIG_C),
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C,
      scratchPad      => (others => '0'),
      newCoefficients => '0',
      state           => IDLE_S);


---------------------------------------
-------record intitial value-----------
---------------------------------------


   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal iDataOutMaster     : AxiStreamMasterType;
   signal reloadOutCtrl      : AxiStreamCtrlType;
   signal pipeConfigOutSlave : AxiStreamSlaveType;


begin



   ---------------------------------
   -- Application
   ---------------------------------
   comb : process (axilReadMaster, axilWriteMaster, dataOutSlave, iDataOutMaster, pipeConfigOutSlave, r, reloadOutCtrl, sysRst) is
      variable v      : RegType := REG_INIT_C;
      variable axilEp : AxiLiteEndpointType;
   begin

      -- Latch the current value
      v := r;

      ------------------------      
      -- AXI-Lite Transactions
      ------------------------      

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister (axilEp, x"000", 0, v.reloadMaster.tData(31 downto 0));
      axiSlaveRegister (axilEp, x"004", 0, v.reloadMaster.tData(63 downto 32));
      axiSlaveRegister (axilEp, x"008", 0, v.reloadMaster.tData(95 downto 64));
      axiSlaveRegister (axilEp, x"00C", 0, v.reloadMaster.tData(127 downto 96));
      axiSlaveRegister (axilEp, x"010", 0, v.reloadMaster.tData(159 downto 128));
      axiSlaveRegister (axilEp, x"014", 0, v.reloadMaster.tData(191 downto 160));
      axiSlaveRegister (axilEp, x"018", 0, v.reloadMaster.tData(223 downto 192));
      axiSlaveRegister (axilEp, x"01C", 0, v.reloadMaster.tData(255 downto 224));
      axiSlaveRegister (axilEp, x"020", 0, v.scratchpad);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      v.reloadMaster.tValid := '0';
      v.reloadMaster.tLast := '0';

      case r.state is

         when IDLE_S =>
            if reloadOutCtrl.pause = '0' and r.scratchpad(0) = '1' then
               -- Write the reload frame
               v.reloadMaster.tValid := '1';
               v.reloadMaster.tLast  := '1';
               -- Reset the load command
               v.scratchpad(0)       := '0';
               -- Wait for reload stream to complete
               v.state               := WAIT_RELOAD_S;
            end if;

         when WAIT_RELOAD_S =>
            if (iDataOutMaster.tValid = '1' and iDataOutMaster.tLast = '1' and dataOutSlave.tReady = '1') then
               -- Reload frame is done transmitting from FIFO when tlast seen comming out
               -- Send the config command to load the new coefficients
               v.configMaster.tValid := '1';
               v.configMaster.tLast  := '1';
               if (r.configMaster.tValid = '1' and pipeConfigOutSlave.tready = '1') then
                  -- When config command gets ack'd, clear tValid and go back to IDLE
                  v.configMaster.tValid := '0';
                  v.configMaster.tLast  := '0';
                  v.state               := IDLE_S;
               end if;

            end if;

      end case;

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
   -- Output FIFO
   ---------------------------------
   dataOutMaster <= iDataOutMaster;
   U_OutFifo : entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         GEN_SYNC_FIFO_G     => true,
         BRAM_EN_G           => false,
         FIFO_ADDR_WIDTH_G   => 4,
         FIFO_PAUSE_THRESH_G => 8,
         SLAVE_AXI_CONFIG_G  => DSP_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => DSP_AXIS_DOWNSIZED_CONFIG_C)
      port map (
         sAxisClk    => sysClk,
         sAxisRst    => sysRst,
         sAxisMaster => r.reloadMaster,
         sAxisCtrl   => reloadOutCtrl,
         mAxisClk    => sysClk,
         mAxisRst    => sysRst,
         mAxisMaster => iDataOutMaster,
         mAxisSlave  => dataOutSlave);

   ---------------------------------
   -- Config Output FIFO
   ---------------------------------
   U_AxiStreamPipeline_OUT : entity work.AxiStreamPipeline
      generic map (
         TPD_G         => TPD_G,
         PIPE_STAGES_G => 1)
      port map (
         axisClk     => sysClk,              -- [in]
         axisRst     => sysRst,              -- [in]
         sAxisMaster => r.configMaster,      -- [in]
         sAxisSlave  => pipeConfigOutSlave,  -- [out]
         mAxisMaster => configOutMaster,     -- [out]
         mAxisSlave  => configOutSlave);     -- [in]

end mapping;
