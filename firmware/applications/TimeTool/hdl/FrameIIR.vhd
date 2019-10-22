------------------------------------------------------------------------------
-- File       : FrameIIR.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-04
-- Last update: 2019-10-16
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

entity FrameIIR is
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
end FrameIIR;

architecture mapping of FrameIIR is

   constant CAMERA_RESOLUTION_BITS : positive            := 8;
   constant CAMERA_PIXEL_NUMBER    : positive            := 2048;
   constant PIXEL_PER_TRANSFER     : positive            := 16;

   type RegType is record
      master         : AxiStreamMasterType;
      slave          : AxiStreamSlaveType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      ramRdAddr      : slv(6 downto 0);
      ramWrEn        : sl;
      ramWrAddr      : slv(6 downto 0);
      ramWrData      : slv(255 downto 0);
      scratchPad     : slv(31 downto 0);
      timeConstant   : slv(8 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      master         => axiStreamMasterInit(DSP_AXIS_CONFIG_C),
      slave          => AXI_STREAM_SLAVE_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      ramRdAddr      => (others => '0'),
      ramWrEn        => '0',
      ramWrAddr      => (others => '0'),
      ramWrData      => (others => '0'),
      scratchPad     => (others => '0'),
      timeConstant   => toSlv(8, 9));
---------------------------------------
-------record intitial value-----------
---------------------------------------


   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal inMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal inSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal outMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal outSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   signal ramRdData : slv(255 downto 0);

begin

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


   U_SimpleDualPortRam_1 : entity surf.DualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         BYTE_WR_EN_G => false,
         DATA_WIDTH_G => 256,
         ADDR_WIDTH_G => 7)
      port map (
         clka  => sysClk,               -- [in]
         wea   => r.ramWrEn,            -- [in]
         rsta  => sysRst,               -- [in]
         addra => r.ramWrAddr,          -- [in]
         dina  => r.ramWrData,          -- [in]
         clkb  => sysClk,               -- [in]
         rstb  => sysRst,               -- [in]
         addrb => r.ramRdAddr,          -- [in]
         doutb => ramRdData);           -- [out]   


   ---------------------------------
   -- Application
   ---------------------------------
   comb : process (axilReadMaster, axilWriteMaster, inMaster, outSlave, r, ramRdData, sysRst) is
      variable v      : RegType := REG_INIT_C;
      variable axilEp : AxiLiteEndpointType;
      variable tc : integer range 0 to 8;
   begin

      -- Latch the current value
      v := r;

      ------------------------      
      -- AXI-Lite Transactions
      ------------------------      

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister (axilEp, x"000", 0, v.scratchPad);
      axiSlaveRegister (axilEp, x"004", 0, v.timeConstant);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      ------------------------      
      -- Main Part of Code
      ------------------------
      tc := 0;
      for i in 0 to 8 loop
         if (r.timeConstant(i) = '1') then
            tc := i;
         end if;
      end loop;
      

      v.slave.tReady  := '0';
      v.ramWrEn       := '0';

      -- Clear tvalid when ack'd by tready
      if outSlave.tready = '1' then
         v.master.tValid := '0';
         v.master.tLast := '0';
      end if;

      if v.master.tvalid = '0' and inMaster.tValid = '1' then
         -- A new transaction has arrived and can be processed

         -- Ack the input
         v.slave.tready := '1';

         -- Copy to output bus
         v.master := inMaster;

         -- Override output tdata with IIR calculations
         for i in 0 to DSP_AXIS_CONFIG_C.TDATA_BYTES_C-1 loop
            v.ramWrData(i*16+15 downto i*16) := slv(signed(ramRdData(i*16+15 downto i*16)) -
                                                 shift_right(signed(ramRdData(i*16+15 downto i*16)), tc) +
                                                 shift_left(signed(inMaster.tData(i*8+7 downto i*8)), 8-tc));

            v.master.tdata(i*8+7 downto i*8) := v.ramWrData(i*16+15 downto i*16+8);
         end loop;

         -- Write updated IIR calculations to ram
         v.ramWrEn   := '1';
         v.ramWrAddr := r.ramRdAddr;

         -- Advance rdAddr to read next 8 values from ram
         v.ramRdAddr := slv(unsigned(r.ramRdAddr) + 1);

         if (inMaster.tLast = '1') then
            -- Reset to 0 for start of each frame
            v.ramRdAddr := (others => '0');
         end if;
      end if;


      -- Combinatoral outputs above the reset
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
      outMaster      <= r.master;


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
         sAxisMaster => outMaster,      -- [in]
         sAxisSlave  => outSlave,       -- [out]
         mAxisMaster => dataOutMaster,  -- [out]
         mAxisSlave  => dataOutSlave);  -- [in]

end mapping;
