------------------------------------------------------------------------------
-- File       : FrameSubtractor.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-04
-- Last update: 2019-10-10
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
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPkg.all;
use work.SsiPkg.all;
use work.Pgp2bPkg.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- This file performs the accumulation for the background subtraction
-------------------------------------------------------------------------------

entity FrameSubtractor is
   generic (
      TPD_G             : time                := 1 ns;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);
      DEBUG_G           : boolean             := true);
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

   constant INT_CONFIG_C           : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 0);
   constant PGP2BTXIN_LEN          : integer             := 19;
   constant CAMERA_RESOLUTION_BITS : positive            := 8;
   constant CAMERA_PIXEL_NUMBER    : positive            := 2048;
   constant PIXELS_PER_TRANSFER    : positive            := 16;

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
      master         => AXI_STREAM_MASTER_INIT_C,
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
   signal outCtrl  : AxiStreamCtrlType   := AXI_STREAM_CTRL_INIT_C;

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
   -- Input FIFO
   ---------------------------------
   U_InFifo : entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 500,
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => INT_CONFIG_C)
      port map (
         sAxisClk    => sysClk,
         sAxisRst    => sysRst,
         sAxisMaster => dataInMaster,
         sAxisSlave  => dataInSlave,
         mAxisClk    => sysClk,
         mAxisRst    => sysRst,
         mAxisMaster => inMaster,
         mAxisSlave  => inSlave);

   U_SimpleDualPortRam_1 : entity work.SimpleDualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         DOB_REG_G    => false,
         BYTE_WR_EN_G => false,
         DATA_WIDTH_G => 128,
         ADDR_WIDTH_G => 7)
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
   comb : process (axilReadMaster, axilWriteMaster, inMaster, outCtrl, pedestalInMaster, pedestalRamData, r, sysRst) is
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
      v.slave.tReady  := not outCtrl.pause;
      v.master.tValid := '0';

      if v.slave.tReady = '1' and inMaster.tValid = '1' then
         v.master := inMaster;
         for i in 0 to INT_CONFIG_C.TDATA_BYTES_C-1 loop
            v.master.tData(i*8+7 downto i*8) := slv(signed(inMaster.tdata(i*8+7 downto i*8))-signed(pedestalRamData(i*8+7 downto i*8)));
         end loop;
         v.pedestalRdAddr := slv(unsigned(r.pedestalRdAddr) + 1);
         if (inMaster.tLast = '1') then
            v.pedestalRdAddr := (others => '0');
         end if;
      end if;


      -- Write pedestals into ram
      if (pedestalInMaster.tvalid = '1') then
         v.pedestalWrAddr := slv(unsigned(r.pedestalWrAddr) + 1);
         if (pedestalInMaster.tLast = '1') then
            v.pedestalWrAddr := (others => '0');
         end if;
      end if;


      -- Combinatoral outputs above the reset
      inSlave <= v.slave;
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
   -- Output FIFO
   ---------------------------------
   U_OutFifo : entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 500,
         SLAVE_AXI_CONFIG_G  => INT_CONFIG_C,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         sAxisClk    => sysClk,
         sAxisRst    => sysRst,
         sAxisMaster => r.Master,
         sAxisCtrl   => outCtrl,
         mAxisClk    => sysClk,
         mAxisRst    => sysRst,
         mAxisMaster => dataOutMaster,
         mAxisSlave  => dataOutSlave);

end mapping;
