#!/usr/bin/env python3
import pyrogue as pr

import rogue

import timetool
import timetool.streams

import ClinkFeb

import lcls2_pgp_fw_lib.hardware.XilinxKcu1500

import surf.protocols.batcher

import LclsTimingCore
import l2si_core

import axipcie


class DataDebug(rogue.interfaces.stream.Slave):
    def __init__(self, name):
        rogue.interfaces.stream.Slave.__init__(self)

        self.channelData = [[] for _ in range(8)]
        self.name = name

    def _acceptFrame(self, frame):
        channel = frame.getChannel()

        if channel == 0 or channel == 1:
            print('-------------------------')            
            d = l2si_core.parseEventHeaderFrame(frame)
            print(d)
            if channel == 1:
                print('-------------------------')
                print()

        if channel == 2:
            frameSize = frame.getPayload()
            ba = bytearray(frameSize)
            frame.read(ba, 0)            
            print("Raw camera data channel")
            print(frame.getNumpy(0, frameSize))
            print('-------------------------')
        print()



class TimeToolKcu1500Root(lcls2_pgp_fw_lib.hardware.shared.Root):

    def __init__(self,
                 dataDebug   = False,
                 dev  = '/dev/datadev_0',# path to PCIe device
                 pgp3        = False,           # true = PGPv3, false = PGP2b
                 pollEn      = True,            # Enable automatic polling registers
                 initRead    = True,            # Read all registers at start of the system
                 numLanes    = 1,
                 **kwargs):

        if dev == 'sim':
            kwargs['timeout'] = 100000000
        
        super().__init__(
            dev  = dev, 
            pgp3        = pgp3, 
            pollEn      = pollEn, 
            initRead    = initRead, 
            numLanes    = numLanes, 
            **kwargs)

        # Create memory interface
        self.memMap = axipcie.createAxiPcieMemMap(dev, 'localhost', 8000)

        # Instantiate the top level Device and pass it the memeory map
        self.add(timetool.TimeToolKcu1500(
            memBase = self.memMap,
            pgp3    = pgp3,
            expand = True))

        # Create DMA streams
        self.dmaStreams = axipcie.createAxiPcieDmaStreams(dev, {lane:{dest for dest in range(4)} for lane in range(numLanes)}, 'localhost', 8000)

                        
        # Map dma streams to SRP, CLinkFebs
        if (dev!='sim'):            
            
            # Create arrays to be filled
            self._srp = [None for lane in range(numLanes)]
            
            # Create the stream interface
            for lane in range(numLanes):
                    
                # SRP
                self._srp[lane] = rogue.protocols.srp.SrpV3()
                self.dmaStreams[lane][0] == self._srp[lane]
                #pr.streamConnectBiDir(self.dmaStreams[lane][0], self._srp[lane])

                # CameraLink Feb Board
                self.add(CLinkFeb.ClinkFeb(      
                    name        = (f'ClinkFeb[{lane}]'), 
                    memBase     = self._srp[lane], 
                    serial      = [self.dmaStreams[lane][2],None],
                    camType     = ['Piranha4',        None],
                    version3    = pgp3,
                    enableDeps  = [self.TimeToolKcu1500.Kcu1500Hsio.PgpMon[lane].RxRemLinkReady], # Only allow access if the PGP link is established
                    expand      = False))

        # Else doing Rogue VCS simulation
        else:
            self.roguePgp = lcls2_pgp_fw_lib.hardware.shared.RogueStreams(numLanes=numLanes, pgp3=pgp3)
        
            # Create arrays to be filled
            self._frameGen = [None for lane in range(numLanes)]
            
            # Create the stream interface
            for lane in range(numLanes):  
            
                # Create the frame generator
                self._frameGen[lane] = timetool.Piranha4VcsEmu('localhost', 7000)

                # When a trigger is received, the fake frame generator will be called
                self.roguePgp.pgpTriggers[lane].setRecvCb( self._frameGen[lane].trigCb )

                # Resulting frame will be pushed at pgp VC1
                self._frameGen[lane] >> self.roguePgp.pgpStreams[lane][1]
                    
                
        # Create arrays to be filled
        self._dbg = [DataDebug("DataDebug") for lane in range(numLanes)]
        self.unbatchers = [rogue.protocols.batcher.SplitterV1() for lane in range(numLanes)]
        
        # Create the stream interface
        for lane in range(numLanes):        
            # Debug slave
            if dataDebug:

                
                # Check if VCS or not
#                if (dev!='sim'): 
                    #print("using TimeToolRx")
#                    self._dbg[lane] = timetool.streams.TimeToolRx(expand=True)
#                else:
                    #print("using TimeToolRxVcs")
#                    self._dbg[lane] = timetool.streams.TimeToolRxVcs(expand=True)
                
                # Connect the streams
                self.dmaStreams[lane][1] >> self.unbatchers[lane] >> self._dbg[lane]
                
                # Add stream device to root class
                #self.add(self._dbg[lane])
                
        
        self.add(pr.LocalVariable(
            name        = 'RunState', 
            description = 'Run state status, which is controlled by the StopRun() and StartRun() commands',
            mode        = 'RO', 
            value       = False,
        ))        
        
        @self.command(description  = 'Stops the triggers and blows off data in the pipeline')        
        def StopRun():
            print ('TimeToolDev.StopRun() executed')
            
            # Get devices
            trigChDev = self.find(typ=LclsTimingCore.EvrV2ChannelReg)
            eventDev  = self.find(typ=surf.protocols.batcher.AxiStreamBatcherEventBuilder)
            
            # Turn off the triggering
            for devPtr in trigChDev:
                devPtr.EnableReg.set(False)
                
            # Turn on the blowoff to clear out the pipeline
            for devPtr in eventDev:
                devPtr.Blowoff.set(True) 

            # Update the run state status variable
            self.RunState.set(False)
                
        @self.command(description  = 'starts the triggers and allow steams to flow to DMA engine')        
        def StartRun():
            print ('TimeToolDev.StartRun() executed')
            
            # Get devices
            trigChDev = self.find(typ=LclsTimingCore.EvrV2ChannelReg)
            eventDev  = self.find(typ=surf.protocols.batcher.AxiStreamBatcherEventBuilder)    
            
            # Turn off the blowoff to allow steams to flow to DMA engine
            for devPtr in eventDev:
                devPtr.Blowoff.set(False)                  
            
            # Turn on the triggering
            for devPtr in trigChDev:
                devPtr.EnableReg.set(True)  
                
            # Reset all counters
            self.CountReset()
                
            # Update the run state status variable
            self.RunState.set(True)        

#         # Start the system
#         self.start(
#             pollEn   = self._pollEn,
#             initRead = self._initRead,
#             timeout  = self._timeout,
#         )
        
        # Check if not simulation
        if (dev!='sim'):           
            # Read all the variables
            self.ReadAll()
            # Some initialization after starting root
            for lane in range(numLanes):
                self.ClinkFeb[lane].ClinkTop.Ch[0].BaudRate.set(9600)
                self.ClinkFeb[lane].ClinkTop.Ch[0].SerThrottle.set(10000)
                #self.ClinkFeb[lane].ClinkTop.Ch[0].UartPiranha4.GCP()
                self.ClinkFeb[lane].ClinkTop.Ch[0].LinkMode.setDisp('Full')
                self.ClinkFeb[lane].ClinkTop.Ch[0].DataMode.setDisp('8Bit')
                self.ClinkFeb[lane].ClinkTop.Ch[0].FrameMode.setDisp('Line')
                self.ClinkFeb[lane].ClinkTop.Ch[0].TapCount.set(8)                    
                self.ClinkFeb[lane].ClinkTop.Ch[0].UartPiranha4.SendEscape()
                self.ClinkFeb[lane].ClinkTop.Ch[0].UartPiranha4.SPF.setDisp('0')
                #self.ClinkFeb[lane].ClinkTop.Ch[0].UartPiranha4.GCP()
        else:
            # Disable the PGP PHY device (speed up the simulation)
#            self.TimeToolKcu1500.Kcu1500Hsio.enable.set(False)
#            self.TimeToolKcu1500.Kcu1500Hsio.hidden = True
            # Bypass the time AXIS channel
            eventDev = self.find(typ=surf.protocols.batcher.AxiStreamBatcherEventBuilder)
            for d in eventDev:
                d.Bypass.set(0x1)            
                
    def initialize(self):
        self.StopRun()
        
