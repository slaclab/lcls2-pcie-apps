------------------------------------------------------------------------------
-- File       : TimeToolCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-12-04
-- Last update: 2017-12-04
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

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiPkg.all;
use work.SsiPkg.all;
use work.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;
---------------------------------
---- entity declaration----------
---------------------------------

entity TimeToolCore is
   generic (
      TPD_G            : time             := 1 ns;
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_DECERR_C);
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
      axilWriteSlave  : out   AxiLiteWriteSlaveType);
end TimeToolCore;


---------------------------------
--------- architecture-----------
---------------------------------

architecture mapping of TimeToolCore is

   constant INT_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes=>16,tDestBits=>0);

   type StateType is (IDLE_S,MOVE_RAW_S,MOVE_FEATURE_EXTRACTED_S, MOVE_TIMESTAMP_LCLS1_S, MOVE_TIMESTAMP_LCLS2_S); 

---------------------------------------
----record for two process method------
---------------------------------------

   type RegType is record
      --default template 
      master          : AxiStreamMasterType;                --see  AxiStreamPkg.vhd for record definition.
      slave           : AxiStreamSlaveType;
      addvalue        : slv(7 downto 0);                    --signal that holds axi lite values that comes in over pyrogue
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
      state           : StateType;

      --code to trigger off of 
      dialInOpCode           : slv(7 downto 0);    
      --dialInOpCode_natural   : natural range 0 to 255;      --is index for timingBus.stream.eventCodes. turning into variable

      --amount to delay
      dialInTriggerDelay     : slv(7 downto 0);             --latched value from pyrogue of how much to delay between receiving the correct opcode and sending trigger to camera
      delay_counter_start    : slv(10 downto 0);            --making variable

      --triggerReady           : sl;                          --camera trigger delay condition has been reached. ready to trigger camera. not needed anymore cause will be in one code block.
      startDelayCounter      : sl;                          --intuitively named. when the opcode (or timing signal) is reached
      dialInDelayCounter     : slv(10 downto 0);            --added by sn (size dep on delay). starts incrementing once start delay counter is true. signals to trigger camera when larger than dial in trigger delay

      --
      pulseId                : slv(31 downto 0);            --latched value of timingBus.stream.pulseId
      endOfFrame             : sl;                          --way for keeping track of when the image ends. signals that the time stamp can be appended
      counter                : slv(7 downto 0);             --added by sn
 
      prescalingRate         : slv(7 downto 0);             --latched value from pyrogue that indicates how often to save a full frame instead of Feature EXtracted data (FEX) data
      locTxIn_local_sysClk   : Pgp2bTxInType;               --contains opcode enable.  see TimingPkg.vhd for record definition
 

   end record RegType;

---------------------------------------
-------record intitial value-----------
---------------------------------------

   constant REG_INIT_C : RegType := (
      master                  => AXI_STREAM_MASTER_INIT_C,
      slave                   => AXI_STREAM_SLAVE_INIT_C,
      addValue                => (others=>'0'),
      axilReadSlave           => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave          => AXI_LITE_WRITE_SLAVE_INIT_C,
      state                   => IDLE_S,

      dialInOpCode            => x"2C",
      --dialInOpCode_natural    => 44,
      
      dialInTriggerDelay      => (others=>'0'),
      --delay_counter_start     => (others=>'0'),
      --triggerReady           => '0',
      startDelayCounter       => '0',
      dialInDelaycounter      => (others=>'0'),

      pulseId                 => (others=>'0'),
      endOfFrame              => '0',
      counter                 => (others=>'0'),

      prescalingRate          => (others=>'0'),
      locTxIn_local_sysClk => PGP2B_TX_IN_INIT_C);

---------------------------------------
-------useful signals------------------
---------------------------------------


   signal r                   : RegType := REG_INIT_C;
   signal rin                 : RegType;

   signal inMaster            : AxiStreamMasterType;
   signal inSlave             : AxiStreamSlaveType;
   signal outCtrl             : AxiStreamCtrlType;

   --locTxIn_buf is a buffer needed for the input fifo to dump its output into
   signal locTxIn_buf         : Pgp2bTxInArray(5 downto 0) := (others=>PGP2B_TX_IN_INIT_C);
   signal empty_placeholder   : slv(31 downto 0);

begin

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
   -- fex module
   ---------------------------------
   --place holder for fex module

   ---------------------------------
   -- locTxIn FIFO for crossing clock domains.
   ---------------------------------
   GEN_PGP_LANE : for i in 5 downto 0 generate
      locTxIn_SynchronizerFifo: entity work.SynchronizerFifo
            generic map (
               TPD_G        => TPD_G,
               DATA_WIDTH_G => PGP2BTXIN_LEN)
            port map (
               rst    => sysRst,
               wr_clk => sysClk,
               wr_en  => r.locTxIn_local_sysClk.opCodeEn,
               din    => r.locTxIn_local_sysClk.flush & r.locTxIn_local_sysClk.opCodeEn & r.locTxIn_local_sysClk.opCode & r.locTxIn_local_sysClk.locData & r.locTxIn_local_sysClk.flowCntlDis,
               rd_clk => pgpTxClk(i),

               dout(PGP2BTXIN_LEN-1)                            => locTxIn_buf(i).flush,
               --dout(PGP2BTXIN_LEN-2)                            => locTxIn_buf(i).opCodeEn,--driven by valid.
               --dout(PGP2BTXIN_LEN-1)                            => empty_placeholder(0),
               dout(PGP2BTXIN_LEN-2)                            => empty_placeholder(1),--driven by valid.
               dout(PGP2BTXIN_LEN-3  downto PGP2BTXIN_LEN-10)   => locTxIn_buf(i).opCode,
               dout(PGP2BTXIN_LEN-11 downto PGP2BTXIN_LEN-18)   => locTxIn_buf(i).locData,
               dout(PGP2BTXIN_LEN-19)                           => locTxIn_buf(i).flowCntlDis,
               valid                                            => locTxIn_buf(i).opCodeEn);
   end generate GEN_PGP_LANE;
   
   --------------------------------
   --lcls2 timing evr
   --------------------------------
  GEN_TP : for i in 0 to NCHAN_C-1 generate

    U_EventSel : entity work.EventHeaderCache
      generic map ( ADDR_WIDTH_G => ADDR_WIDTH_C,
                    DEBUG_G      => ite(i>0,false,true) )
--                    DEBUG_G      => false )
      port map ( rst            => evrRst,
                 wrclk          => evrClk,
                 enable         => configE.acqEnable,
                 cacheenable    => configE.enable(i),
                 partition      => configE.partition(2 downto 0),
                 timing_prompt  => timingHeader_prompt,
                 expt_prompt    => exptBus,
                 timing_aligned => timingHeader_aligned,
                 expt_aligned   => exptBus_aligned,
                 pdata          => trigData (i),
                 pdataV         => trigDataV(i),
                 cntWrFifo      => wrFifoCnt(i),
                 rstFifo        => rstFifo  (i),
                 msgDelay       => msgDelayGet(i),
                 cntL0          => cntL0    (i),
                 cntOflow       => cntOflow (i),
                 --
                 rdclk          => dmaClk,
                 advance        => eventHdrRd(i),
                 valid          => eventHdrV (i),
                 pmsg           => pmsg      (i),
                 phdr           => phdr      (i),
                 cntRdFifo      => rdFifoCnt (i),
                 hdrOut         => eventHdr  (i) );

    eventHdrD(i) <= toSlv(eventHdr(i));
  end generate;

   ---------------------------------
   -- Application
   ---------------------------------
   comb : process (r, sysRst, axilReadMaster, axilWriteMaster, inMaster, outCtrl) is
      variable v                          : RegType;
      variable axilEp                     : AxiLiteEndpointType;
      variable dialInOpCode_natural       : natural range 0 to 255;
      variable delay_counter_start        : slv(10 downto 0);
      

   begin
      ---------------------------------------------------------------------
      --pre state machine actions that always need to be done
      ---------------------------------------------------------------------

      -- Latch the current value
      v := r;

      ------------------------      
      -- AXI-Lite Transactions
      ------------------------      

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister (axilEp, x"000",    0, v.addValue);
      axiSlaveRegister (axilEp, x"00000",  8, v.dialInOpCode);         --endpoint type.  This is the bus from which the data is read (need to verify).
      axiSlaveRegister (axilEp, x"00000", 16, v.dialInTriggerDelay);   --the second field is the address. look for "dataen" in ClinkTop.vhd 
                                                                       --and_ClinkTop.py for an example the third field is the bit offset.  
      axiSlaveRegister (axilEp, x"00000", 24, v.prescalingRate);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      --naturalizing some of the signals
      dialInOpCode_natural                    :=     to_integer(unsigned(v.dialInOpCode));
      prescalingRate_natural                  :=     to_integer(unsigned(v.prescalingRate));


      --latching FIFO synchronized (b/c of crossing clock) value of dataInMaster. That's the camera image in this case.
      v.master                                :=     inMaster;



      if ((timingBus.strobe = '1') and (timingBus.stream.eventCodes(v.dialInOpCode_natural) = '1')) then
         v.pulseId := timingBus.stream.pulseId;
         v.locTxIn_local_sysClk.opCodeEn := '1';                       --falling edge triggers camera. but we're trigger herbst, not camera.           
      else
         v.locTxIn_local_sysClk.opCodeEn := '0';                       --this will happen one clock cycle later. is that long enough to trigger camera?
      end if;


      v.master.tLast          :=     '0';

           ---------------------------------------------------------------------
      -- State Machine
      --IDLE_S,MOVE_RAW_S,MOVE_FEATURE_EXTRACTED_S, MOVE_TIMESTAMP_LCLS1_S, MOVE_TIMESTAMP_LCLS2_S, 
      --how to send trigger to camera using state machine?

      case r.state is
      ----------------------------------------------------------------------
         when IDLE_S =>
            -- Check if ready to move data
            if inMaster.tValid = '1' then  -- should be "tFirst"
                  v.state := MOVE_RAW_S;
                  v.counter := v.counter + 1;
           end if
      ----------------------------------------------------------------------
         when MOVE_RAW_S => 


            --increment global counter


            if (counter(prescalingRate_natural downto 0 ) = 0 then 

                  if v.slave.tReady = '1' then                       --this selects every 2^prescalingRate_natural raw event for 
                  
                        for i in 0 to INT_CONFIG_C.TDATA_BYTES_C-1 loop
                              v.master.tData(i*8+7 downto i*8) := inMaster.tData(i*8+7 downto i*8) + r.addValue;        --leaving r.addValue in for future debugging purposes
                        end loop;

                  elsif v.slave.tReady = '0' then
                        --do something to fail elegantly
                        v.state := MOVE_RAW_S   --not necessary since two processes state is latched

                  end if

                  if inMaster.tLast = '1' then
                        
                        v.state := MOVE_FEATURE_EXTRACTED_S
                  else
            
                        v.state := MOVE_RAW_S   --not necessary since two processes state is latched
                        
                  end if
            else
                  v.state := MOVE_FEATURE_EXTRACTED_S

            end if
      ----------------------------------------------------------------------
         when MOVE_FEATURE_EXTRACTED_S => 
            v.master.tData(31 downto 0)   := x"DEAD";
            v.master.tKeep                := x"000F";
            v.master.tValid               := '1'; 
            v.state                       := MOVE_TIMESTAMP_LCLS1_S;
      ----------------------------------------------------------------------
         when MOVE_TIMESTAMP_LCLS1_S => 
            --some logic

            v.master.tData(31 downto 0)   := r.pulseId;
            v.master.tKeep                := x"000F";
            v.master.tValid               := '1';                  
            v.master.tLast                := '1';
            v.state                       := IDLE_S;
      ----------------------------------------------------------------------
      end case;
      -- Data Mover
      ------------------------------
      v.slave.tReady := not outCtrl.pause;

      if v.slave.tReady = '1' and inMaster.tValid = '1' then
         v.master := inMaster;

         for i in 0 to INT_CONFIG_C.TDATA_BYTES_C-1 loop
            v.master.tData(i*8+7 downto i*8) := inMaster.tData(i*8+7 downto i*8) + r.addValue;
         end loop;

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
