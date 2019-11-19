------------------------------------------------------------------------------
-- File       : FrameSubtractor.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-04
-- Last update: 2019-11-18
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


library timetool;
use timetool.AppPkg.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- This file performs the accumulation for the background subtraction
-------------------------------------------------------------------------------

entity FrameSubtractor is
   generic (
      TPD_G   : time    := 1 ns;
      DEBUG_G : boolean := true);
   port (
      -- System Interface
      sysClk           : in  sl;
      sysRst           : in  sl;
      -- DMA Interfaces  (sysClk domain)
      dataInMaster     : in  AxiStreamMasterType;
      dataInSlave      : out AxiStreamSlaveType;
      dataOutMaster    : out AxiStreamMasterType;
      dataOutSlave     : in  AxiStreamSlaveType;
      -- Pedestal DMA Interfaces  (sysClk domain)
      pedestalInMaster : in  AxiStreamMasterType;
      pedestalInSlave  : out AxiStreamSlaveType;
      -- AXI-Lite Interface
      axilReadMaster   : in  AxiLiteReadMasterType;
      axilReadSlave    : out AxiLiteReadSlaveType;
      axilWriteMaster  : in  AxiLiteWriteMasterType;
      axilWriteSlave   : out AxiLiteWriteSlaveType);
end FrameSubtractor;

architecture mapping of FrameSubtractor is

   constant CAMERA_RESOLUTION_BITS : positive := 8;
   constant CAMERA_PIXEL_NUMBER    : positive := 2048;
   constant PIXELS_PER_TRANSFER    : positive := 16;

   type RegType is record
      master         : AxiStreamMasterType;
      slave          : AxiStreamSlaveType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      pedestalRdAddr : slv(6 downto 0);
      pedestalWrAddr : slv(6 downto 0);
      scratchPad     : slv(31 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      master         => axiStreamMasterInit(DSP_AXIS_CONFIG_C),
      slave          => AXI_STREAM_SLAVE_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      pedestalRdAddr => (others => '0'),
      pedestalWrAddr => (others => '0'),
      scratchPad     => (others => '0'));



   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal inMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal inSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
   signal outSlave : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal pedestalInMasterBuf : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal pedestalInSlaveBuf  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal pedestalRamData : slv(127 downto 0);

begin
   ---------------------------------
   -- No-Input FIFO. 
   ---------------------------------
   pedestalInMasterBuf <= pedestalInMaster;    --may migrate to buffered input fifo 
   pedestalInSlave     <= pedestalInSlaveBuf;  --may migrate to buffered input fifo 

   ---------------------------------
   -- Input Pipeline
   ---------------------------------
   ---------------------------------
   -- Input FIFO
   ---------------------------------
   U_AxiStreamPipeline_IN : entity surf.AxiStreamPipeline
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

   U_SimpleDualPortRam_1 : entity surf.SimpleDualPortRam
      generic map (
         TPD_G         => TPD_G,
         MEMORY_TYPE_G => "distributed",
         DOB_REG_G     => false,
         BYTE_WR_EN_G  => false,
         DATA_WIDTH_G  => 128,
         ADDR_WIDTH_G  => 7)
      port map (
         clka  => sysClk,                                -- [in]
         wea   => pedestalInMaster.tvalid,               -- [in]
         addra => r.pedestalWrAddr,                      -- [in]
         dina  => pedestalInMaster.tdata(127 downto 0),  -- [in]
         clkb  => sysClk,                                -- [in]
         rstb  => sysRst,                                -- [in]
         addrb => r.pedestalRdAddr,                      -- [in]
         doutb => pedestalRamData);                      -- [out]


   ---------------------------------
   -- Application
   ---------------------------------
   comb : process (axilReadMaster, axilWriteMaster, inMaster, inSlave, pedestalInMaster, pedestalRamData, r, sysRst) is
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

      axiSlaveRegister (axilEp, x"000", 0, v.scratchPad);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      ------------------------      
      -- Main Part of Code
      ------------------------ 

      -- Subtract incomming data against pedestals
      v.slave.tReady := '0';

      if (inSlave.tReady = '1') then
         v.master.tValid := '0';
      end if;


      if v.master.tValid = '0' and inMaster.tValid = '1' then
         v.master := inMaster;
         for i in 0 to DSP_AXIS_CONFIG_C.TDATA_BYTES_C-1 loop
            v.master.tData(i*8+7 downto i*8) := slv(signed(inMaster.tdata(i*8+7 downto i*8))-signed(pedestalRamData(i*8+7 downto i*8)));
         end loop;
         v.pedestalRdAddr := slv(unsigned(r.pedestalRdAddr) + 1);
         if (inMaster.tLast = '1') then
            v.pedestalRdAddr := (others => '0');
         end if;
      end if;


      -- Write pedestals into ram
      -- Pedastal txns are constantly accepted (tready=1)
      if (pedestalInMaster.tvalid = '1') then
         v.pedestalWrAddr := slv(unsigned(r.pedestalWrAddr) + 1);
         if (pedestalInMaster.tLast = '1') then
            v.pedestalWrAddr := (others => '0');
         end if;
      end if;


      -- Combinatoral outputs above the reset
      inSlave                   <= v.slave;
      pedestalInSlaveBuf.tready <= '1';

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
   -- Output Pipeline
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
