------------------------------------------------------------------------------
-- File       : FrameIIR.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-04
-- Last update: 2019-10-11
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
use work.SsiPkg.all;

library unisim;
use unisim.vcomponents.all;

-------------------------------------------------------------------------------
-- This file performs the accumulation for the background subtraction
-------------------------------------------------------------------------------

entity FrameIIR is
   generic (
      TPD_G             : time                := 1 ns;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType := ssiAxiStreamConfig(16, TKEEP_COMP_C, TUSER_FIRST_LAST_C, 8, 2);
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

   constant INT_CONFIG_C           : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 0);
   constant PGP2BTXIN_LEN          : integer             := 19;
   constant CAMERA_RESOLUTION_BITS : positive            := 8;
   constant CAMERA_PIXEL_NUMBER    : positive            := 2048;
   constant PIXEL_PER_TRANSFER     : positive            := 16;
   constant ONE_SIGNED             : signed(7 downto 0)  := (0                           => '1', others => '0');


   type RegType is record
      master         : AxiStreamMasterType;
      slave          : AxiStreamSlaveType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      ramRdAddr      : slv(6 downto 0);
      ramWrEn        : sl;
      ramWrAddr      : slv(6 downto 0);
      ramWrData      : slv(127 downto 0);
      scratchPad     : slv(31 downto 0);
      timeConstant   : slv(7 downto 0);
      tConst_natural : natural range 0 to 7;
      tConst_signed  : signed(7 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      master         => AXI_STREAM_MASTER_INIT_C,
      slave          => AXI_STREAM_SLAVE_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      ramRdAddr      => (others => '0'),
      ramWrEn        => '0',
      ramWrAddr      => (others => '0'),
      ramWrData      => (others => '0'),
      scratchPad     => (others => '0'),
      timeConstant   => (0 => '1', others => '0'),
      tConst_signed  => (others => '0'),
      tConst_natural => 1);

---------------------------------------
-------record intitial value-----------
---------------------------------------


   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal inMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal inSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
   signal outCtrl  : AxiStreamCtrlType   := AXI_STREAM_CTRL_INIT_C;

   signal ramRdData : slv(127 downto 0);

begin

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


   U_SimpleDualPortRam_1 : entity work.DualPortRam
      generic map (
         TPD_G        => TPD_G,
         BRAM_EN_G    => false,
         REG_EN_G     => false,
         BYTE_WR_EN_G => false,
         DATA_WIDTH_G => 128,
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
   comb : process (axilReadMaster, axilWriteMaster, inMaster, outCtrl, r, ramRdData, sysRst) is
      variable v      : RegType := REG_INIT_C;
      variable axilEp : AxiLiteEndpointType;
      variable stage1 : signed(7 downto 0);
      variable stage2 : signed(15 downto 0);
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
      -- updating time constant
      ------------------------       
      v.tConst_natural := to_integer(unsigned(r.timeConstant)+1);
      v.tConst_signed  := shift_left(ONE_SIGNED, r.tConst_natural);
      ------------------------      
      -- Main Part of Code
      ------------------------ 

      v.slave.tReady  := not outCtrl.pause;
      v.master.tLast  := '0';
      v.master.tValid := '0';
      v.ramWrEn       := '0';

      if v.slave.tReady = '1' and inMaster.tValid = '1' then
         v.master := inMaster;

         for i in 0 to INT_CONFIG_C.TDATA_BYTES_C-1 loop
            stage1 := signed(inMaster.tdata(i*8+7 downto i*8));
            stage2 := signed(ramRdData(i*8+7 downto i*8)) * (signed(r.timeConstant)-1);

            v.ramWrData(i*8+7 downto i*8)    := resize(slv(shift_right(stage2 + stage1, r.tConst_natural)), 8);
            v.master.tdata(i*8+7 downto i*8) := v.ramWrData(i*8+7 downto i*8);
         end loop;

         v.ramWrEn   := '1';
         v.ramWrAddr := r.ramRdAddr;
         v.ramRdAddr := slv(unsigned(r.ramRdAddr) + 1);

         if (inMaster.tLast = '1') then
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
