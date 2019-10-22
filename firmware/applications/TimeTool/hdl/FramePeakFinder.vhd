------------------------------------------------------------------------------
-- File       : FramePeakFinder.vhd
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
use ieee.numeric_std.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

use work.AppPkg.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- This file performs the accumulation for the background subtraction
-------------------------------------------------------------------------------

entity FramePeakFinder is
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
end FramePeakFinder;

architecture mapping of FramePeakFinder is

   constant CAMERA_RESOLUTION_BITS   : positive := 8;
   constant CAMERA_PIXEL_NUMBER_BITS : positive := 11;
   constant CAMERA_PIXEL_NUMBER      : positive := 2**CAMERA_PIXEL_NUMBER_BITS;  --2048 pixels

   --type CameraFrameBuffer is array (natural range<>) of slv(CAMERA_RESOLUTION_BITS-1 downto 0);
   type CameraFrameBuffer is array (natural range<>) of signed((CAMERA_RESOLUTION_BITS-1) downto 0);

   type StateType is (
      FIND_MAX_S,
      SEND_S);

   type RegType is record
      master         : AxiStreamMasterType;
      slave          : AxiStreamSlaveType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      max            : slv(7 downto 0);
      max_pixel      : slv(CAMERA_PIXEL_NUMBER_BITS-1 downto 0);
      counter        : natural range 0 to (CAMERA_PIXEL_NUMBER-1);
      scratchPad     : slv(31 downto 0);
      state          : StateType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      master         => axiStreamMasterInit(DSP_AXIS_CONFIG_C),
      slave          => AXI_STREAM_SLAVE_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      max            => (others => '1'),
      max_pixel      => (others => '0'),
      counter        => 0,
      scratchPad     => (others => '0'),
      state          => FIND_MAX_S);

---------------------------------------
-------record intitial value-----------
---------------------------------------


   signal r   : RegType := REG_INIT_C;
   signal rin : RegType := REG_INIT_C;

   signal inMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal inSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
   signal outCtrl  : AxiStreamCtrlType   := AXI_STREAM_CTRL_INIT_C;

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
   comb : process (axilReadMaster, axilWriteMaster, inMaster, outCtrl, r, sysRst) is
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

      axiSlaveRegister (axilEp, x"0000", 0, v.scratchPad);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      ------------------------      
      -- Main Part of Code
      ------------------------ 

      v.slave.tReady  := '0';
      v.master.tValid := '0';

      case r.state is

         when FIND_MAX_S =>
            -- New data arriving and we have downstream buffer space for the result
            if (inMaster.tValid = '1' and outCtrl.pause = '0') then
               v.slave.tReady := '1';   -- ack the incomming data

               for i in 0 to DSP_AXIS_CONFIG_C.TDATA_BYTES_C-1 loop
                  if(signed(r.master.tData(i*8+7 downto i*8)) >= signed(v.max)) then
                     v.max       := r.master.tData(i*8+7 downto i*8);
                     v.max_pixel := std_logic_vector(to_unsigned(r.counter, CAMERA_PIXEL_NUMBER_BITS)+to_unsigned(i, CAMERA_PIXEL_NUMBER_BITS));
                  end if;
               end loop;
               v.counter := r.counter + DSP_AXIS_CONFIG_C.TDATA_BYTES_C;

               if v.master.tLast = '1' then
                  v.state := SEND_S;
               end if;
            end if;

         when SEND_S =>
            v.master.tValid                                      := '1';
            v.master.tLast                                       := '1';
            v.master.tData                                       := (others => '0');
            v.master.tData(CAMERA_PIXEL_NUMBER_BITS -1 downto 0) := r.max_pixel;
            v.counter                                            := 0;
            v.max                                                := (others => '1');
            v.state                                              := FIND_MAX_S;

      end case;

      inSlave <= v.slave;

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
   U_OutFifo : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         GEN_SYNC_FIFO_G     => true,
         BRAM_EN_G           => false,
         FIFO_ADDR_WIDTH_G   => 4,
         FIFO_PAUSE_THRESH_G => 4,
         SLAVE_AXI_CONFIG_G  => DSP_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => DSP_AXIS_CONFIG_C)
      port map (
         sAxisClk    => sysClk,
         sAxisRst    => sysRst,
         sAxisMaster => r.master,
         sAxisCtrl   => outCtrl,
         mAxisClk    => sysClk,
         mAxisRst    => sysRst,
         mAxisMaster => dataOutMaster,
         mAxisSlave  => dataOutSlave);

end mapping;
