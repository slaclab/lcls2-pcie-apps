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
      -- DMA Interfaces  (sysClk domain)
      dataInMaster    : in    AxiStreamMasterType;
      dataInSlave     : out   AxiStreamSlaveType;
      dataOutMaster   : out   AxiStreamMasterType;
      dataOutSlave    : in    AxiStreamSlaveType;
      -- AXI-Lite Interface
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- Timing information
      timingBus       : in    TimingBusType;
      -- op-code for controlling of timetool cc1 (<- pin id) trigger
      locTxIn         : out    Pgp2bTxInType;
      pgpTxClk        : in     sl);
end TimeToolCore;

architecture mapping of TimeToolCore is

   constant INT_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes=>16,tDestBits=>0);
   constant PGP2BTXIN_LEN  : integer := 19;
   --constant DEFAULT_OPCODE : integer := 44;  -- added by sn

   type RegType is record
      master                : AxiStreamMasterType;
      slave                 : AxiStreamSlaveType;
      addvalue              : slv(7 downto 0);
      dialInOpCode          : slv(7 downto 0);    --added by sn
      dialInOpCode_natural  : natural;            --added by sz
      dialInTriggerDelay    : slv(7 downto 0);    --added by sz   
      pulseId               : slv(31 downto 0);   --added by cpo
      endOfFrame            : sl;                 --added sz and cpo
      triggerReady          : sl;                 --added by sn
      runCounter            : sl;                 --added by sn
      --counter               : slv(31 downto 0); --added by sn
      counter               : slv(10 downto 0);   --added by sn (size dep on delay)
      axilReadSlave         : AxiLiteReadSlaveType;
      axilWriteSlave        : AxiLiteWriteSlaveType;
      locTxIn_local_sysClk  : Pgp2bTxInType;

   end record RegType;

   constant REG_INIT_C : RegType := (
      master               => AXI_STREAM_MASTER_INIT_C,
      slave                => AXI_STREAM_SLAVE_INIT_C,
      addValue             => (others=>'0'),
      dialInOpCode         => x"2C",            --added by sn
      dialInOpCode_natural => 44,               --added by sz
      dialInTriggerDelay   => (others=>'0'),    --added by sz
      pulseId              => (others=>'0'),    --added by cpo
      endOfFrame           => '0',              --added sz and cpo
      triggerReady         => '0',              --added by sn
      runCounter           => '0',              --added by sn
      counter              => (others=>'0'),    --added by sn
      axilReadSlave        => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave       => AXI_LITE_WRITE_SLAVE_INIT_C,
      locTxIn_local_sysClk => PGP2B_TX_IN_INIT_C);    --come back to

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal inMaster            : AxiStreamMasterType;
   signal inSlave             : AxiStreamSlaveType;
   signal outCtrl             : AxiStreamCtrlType;
   signal locTxIn_buf         : Pgp2bTxInType;
   signal empty_placeholder   :slv(31 downto 0);

   component ila_0
     port ( clk    : sl;
            probe0 : slv(255 downto 0) );
   end component;

begin

   locTxIn <= locTxIn_buf;
   ---------------------------------
   -- Input FIFO
   ---------------------------------
   U_InFifo: entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 500,
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_C,
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

   ---------------------------------
   -- locTxIn FIFO for crossing clock domains.
   ---------------------------------

   locTxIn_SynchronizerFifo: entity work.SynchronizerFifo
         generic map (
            TPD_G        => TPD_G,
            DATA_WIDTH_G => PGP2BTXIN_LEN)
         port map (
            rst    => sysRst,
            wr_clk => sysClk,
            wr_en  => r.locTxIn_local_sysClk.opCodeEn,
            din    => r.locTxIn_local_sysClk.flush & r.locTxIn_local_sysClk.opCodeEn & r.locTxIn_local_sysClk.opCode & r.locTxIn_local_sysClk.locData & r.locTxIn_local_sysClk.flowCntlDis,
            rd_clk => pgpTxClk,

            dout(PGP2BTXIN_LEN-1)                            => locTxIn_buf.flush,
            --dout(PGP2BTXIN_LEN-2)                            => locTxIn_buf.opCodeEn,--driven by valid.
            --dout(PGP2BTXIN_LEN-1)                            => empty_placeholder(0),
            dout(PGP2BTXIN_LEN-2)                            => empty_placeholder(1),--driven by valid.
            dout(PGP2BTXIN_LEN-3  downto PGP2BTXIN_LEN-10)   => locTxIn_buf.opCode,
            dout(PGP2BTXIN_LEN-11 downto PGP2BTXIN_LEN-18)   => locTxIn_buf.locData,
            dout(PGP2BTXIN_LEN-19)                           => locTxIn_buf.flowCntlDis,
            valid                                            => locTxIn_buf.opCodeEn);

   ---------------------------------
   -- Xilinx debug integrated logic analyzer.
   ---------------------------------

   GEN_DEBUG : if DEBUG_G generate
     U_ILA : ila_0
       port map ( clk   => sysClk,
                  probe0(0)                   => timingBus.strobe,
                  probe0(1)                   => timingBus.valid,
                  probe0(2)                   => r.locTxIn_local_sysClk.opCodeEn,
                  probe0(34 downto 3)         => timingBus.stream.pulseId,
                  probe0(42 downto 35)        => r.locTxIn_local_sysClk.opCode,
		  probe0(255 downto 43)       => (others=>'0') );
   end generate;
     
   ---------------------------------
   -- Application
   ---------------------------------
   comb : process (r, sysRst, axilReadMaster, axilWriteMaster, inMaster, outCtrl, timingBus) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin

      -- Latch the current value
      v := r;

      ------------------------      
      -- AXI-Lite Transactions
      ------------------------      

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister (axilEp, x"00000",  0, v.addValue);	       --field is updated from info over axi bus. only for addvalue. The first field is the axi lite
      axiSlaveRegister (axilEp, x"00000",  8, v.dialInOpCode);         --endpoint type.  This is the bus from which the data is read (need to verify).
      axiSlaveRegister (axilEp, x"00000", 16, v.dialInTriggerDelay);   --the second field is the address. look for "dataen" in ClinkTop.vhd and_ClinkTop.py
                                                                       --for an example the third field is the bit offset.  

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      ------------------------------
      -- Event Code            --cpo
      ------------------------------
      -- will need to change r.pulseId to go into a fifo when data rates increase (camera readout over laps with next trigger being received)
      v.dialInOpCode_natural := to_integer(unsigned(v.dialInOpCode));
      if timingBus.strobe = '1' and timingBus.stream.eventCodes(v.dialInOpCode_natural) = '1' then
         v.pulseId := timingBus.stream.pulseId;
         --start counter for trigger delay, 
         v.runCounter := '1';
      end if;

      ------------------------------
      -- Delay Counter            --snelson
      ------------------------------
      if v.runCounter = '1' then
        if v.counter < v.dialInTriggerDelay then
          v.counter := v.counter + 1;
        else
          v.triggerReady := '1'; 
          v.counter := (others => '0');  --reset the counter
          v.runCounter := '0';           --stop counter loop
        end if;
      end if;  

      ------------------------------
      -- Sending Trigger            --snelson
      ------------------------------
      --drive locTxIn and it will send op code to drive front end board.
      if v.triggerReady = '1' then
         v.locTxIn_local_sysClk.opCodeEn := '1';  --falling edge triggers camera. but we're trigger herbst, not camera.           
         v.triggerReady := '0';                    --reset triggerReady 
      else
         v.locTxIn_local_sysClk.opCodeEn := '0';  --this will happen one clock cycle later. is that long enough to trigger camera?
      end if;
      ------------------------------
      -- Data Mover
      ------------------------------
      v.slave.tReady := not outCtrl.pause;

      if v.slave.tReady = '1' and r.endOfFrame = '1' then
         -- could also use sAxisSlave instead of sAxisCtrl
         -- ctrl has pause, slave has ready
         v.master.tData(31 downto 0)   := r.pulseId;
         v.master.tKeep := x"000F";
         v.endOfFrame := '0';	  --sz and cpo
         v.master.tValid := '1';  --sz and cpo
         v.master.tLast := '1';   --sz and cpo
    
      elsif v.slave.tReady = '1' and inMaster.tValid = '1' and r.endOfFrame = '0' then
         v.master := inMaster;

         for i in 0 to INT_CONFIG_C.TDATA_BYTES_C-1 loop
            v.master.tData(i*8+7 downto i*8) := inMaster.tData(i*8+7 downto i*8) + r.addValue;
         end loop;


         if inMaster.tLast = '1' then      --cpo
           v.endOfFrame := '1';            --cpo
           v.master.tLast := '0';          --cpo
         end if;                           --cpo


      else
         v.master.tValid := '0';
      end if;

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
      inSlave        <= v.slave;

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
   U_OutFifo: entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 500,
         SLAVE_AXI_CONFIG_G  => INT_CONFIG_C,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_C)
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
