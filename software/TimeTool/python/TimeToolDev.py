#!/usr/bin/env python3
import pyrogue as pr

import rogue.protocols

import XilinxKcu1500Pgp as kcu1500
import ClinkFeb         as feb
import TimeTool         as timeTool
import surf.axi         as axi

import numpy as np
import h5py

import rogue.interfaces.stream

class MyCustomMaster(rogue.interfaces.stream.Master):

    # Init method must call the parent class init
    def __init__(self):
        super().__init__()
        self._maxSize = 2048

    # Method for generating a frame
    def myFrameGen(self):
        # First request an empty from from the primary slave
        # The first arg is the size, the second arg is a boolean
        # indicating if we can allow zero copy buffers, usually set to true
        frame = self._reqFrame(self._maxSize, True) # Here we request a frame capable of holding 2048 bytes

        # Create a 2048 byte array with an incrementing value
        ba = bytearray([(i&0xFF) for i in range(self._maxSize)])

        # Write the data to the frame at offset 0
        frame.write(ba,0)
        
        # Send the frame to the currently attached slaves
        self._sendFrame(frame)

#One of the goals this code satisfies is to to facilitate communication between registers in Xilinx's kcu1500 FPGA and a host linux machine.
#See comment in TimeTool.py for how to make rogue aware of a FPGA register to communicate with.

class TimeToolRx(pr.Device,rogue.interfaces.stream.Slave):

    def __init__(self, name='TimeToolRx', **kwargs):
        rogue.interfaces.stream.Slave.__init__(self)
        pr.Device.__init__(self,name=name,**kwargs)

        self.add(pr.LocalVariable( name='frameCount',   value=0, mode='RO', pollInterval=1))
        self.add(pr.LocalVariable( name='lengthErrors', value=0, mode='RO', pollInterval=1))
        self.add(pr.LocalVariable( name='dataErrors',   value=0, mode='RO', pollInterval=1))

        self.my_h5_file = h5py.File("first_test.h5",'w')
        self.to_save_to_h5 = []

        for i in range(8):
            self.add(pr.LocalVariable( name='byteError{}'.format(i), disp='{:#x}', value=0, mode='RO', pollInterval=1))

    def _acceptFrame(self,frame):
        p = bytearray(frame.getPayload())
        frame.read(p,0)
        print(len(p))
        my_mask = np.arange(36)
        if(len(p)>100):
              my_mask = np.append(my_mask,np.arange(int(len(p)/2),int(len(p)/2)+36))
              my_mask = np.append(my_mask,np.arange(len(p)-36,len(p)))

        to_print = np.array(p)[-1:] 
        #print(np.array(p)[:96],to_print) #comment out for long term test
        print(np.array(p)[my_mask])
        print("____________________________________________________")
        self.frameCount.set(self.frameCount.value() + 1,False)

     
        '''berr = [0,0,0,0,0,0,0,0]

        #frameLength = 4100 # sn : medium mode, 12 bit
        frameLength = 2052 # sn : medium mode, 8 bit
        #if len(p) != 2048: 
        if len(p) != frameLength:
            #print('length:',len(p))
            self.lengthErrors.set(self.lengthErrors.value() + 1,False)
        else:
            for i in range(frameLength-4):
                exp = i & 0xFF
                if p[i] != exp:
                    #print("Error at pos {}. Got={:2x}, Exp={:2x}".format(i,p[i],exp))
                    d = p[i] ^ exp
                    c = i % 8
                    berr[c] = berr[c] | d
                    self.dataErrors.set(self.dataErrors.value() + 1,False)

        #print(len(p))
        to_print = np.array(p)[-16:]
        print(np.array(p)[:24],to_print) #comment out for long term test
        #self.to_save_to_h5.append(np.array(p))

        for i in range(8):
            self.node('byteError{}'.format(i)).set(berr[i],False)'''

    def close_h5_file(self):
        print("the thing that is not a destructor is working")
        self.my_h5_file['my_data'] = self.to_save_to_h5
        self.my_h5_file.close()
        print(self.to_save_to_h5)

class TimeToolDev(kcu1500.Core):

    def __init__(self,
            name        = 'TimeToolDev',
            description = 'Container for TimeTool Dev',
            dataDebug   = False,
            dev         = '/dev/datadev_0',# path to PCIe device
            version3    = False,           # true = PGPv3, false = PGP2b
            pollEn      = True,            # Enable automatic polling registers
            initRead    = True,            # Read all registers at start of the system
            numLane     = 1,               # Number of PGP lanes
            **kwargs
        ):
        super().__init__(
            name        = name, 
            description = description, 
            dev         = dev, 
            version3    = version3, 
            pollEn      = pollEn, 
            initRead    = initRead, 
            numLane     = numLane, 
            **kwargs
        )
            
        # Check if not doing simulation
        if (dev != 'sim'):            
            
            # Create arrays to be filled
            self._srp = [None for lane in range(numLane)]
            
            # Create the stream interface
            for lane in range(numLane):
                    
                # SRP
                self._srp[lane] = rogue.protocols.srp.SrpV3()
                pr.streamConnectBiDir(self._dma[lane][0],self._srp[lane])
                         
                # CameraLink Feb Board
                self.add(feb.ClinkFeb(      
                    name        = (f'ClinkFeb[{lane}]'), 
                    memBase     = self._srp[lane], 
                    serial      = [self._dma[lane][2],None],
                    camType     = ['Piranha4',        None],
                    version3    = version3,
                    enableDeps  = [self.Hardware.PgpMon[lane].RxRemLinkReady], # Only allow access if the PGP link is established
                    # expand      = False,
                ))

        # Else doing Rogue VCS simulation
        else:
        
            # Create arrays to be filled
            self._frameGen = [None for lane in range(numLane)]
            
            # Create the stream interface
            for lane in range(numLane):  
            
                # Create the frame generator
                self._frameGen[lane] = MyCustomMaster()
                
                # Connect the frame generator
                pr.streamConnect(self._frameGen[lane],self._pgp[lane][1]) 
                    
                # Create a command to execute the frame generator
                self.add(pr.BaseCommand(   
                    name         = f'GenFrame[{lane}]',
                    function     = lambda cmd: self._frameGen[lane].myFrameGen(),
                ))                
                
        # Create arrays to be filled
        self._dbg = [None for lane in range(numLane)]        
        
        # Create the stream interface
        for lane in range(numLane):        
            # Debug slave
            if dataDebug:
                self._dbg[lane] = TimeToolRx(expand=False)
                pr.streamTap(self._dma[lane][1],self._dbg[lane])
                self.add(self._dbg)
                
        # Time tool application
        self.add(timeTool.Application(
            memBase = self._memMap,
            offset  = 0x00C00000,
            numLane = numLane,
        ))

        # Start the system
        self.start(
            pollEn   = self._pollEn,
            initRead = self._initRead,
            timeout  = self._timeout,
        )
        
        # Check if not simulation
        if (dev != 'sim'):           
            # Read all the variables
            self.ReadAll()
            # Some initialization after starting root
            for lane in range(numLane):
                self.ClinkFeb[lane].ClinkTop.Ch[0].BaudRate.set(9600)
                self.ClinkFeb[lane].ClinkTop.Ch[0].SerThrottle.set(10000)
                self.ClinkFeb[lane].ClinkTop.Ch[0].LinkMode.setDisp('Full')
                self.ClinkFeb[lane].ClinkTop.Ch[0].DataMode.setDisp('8Bit')
                self.ClinkFeb[lane].ClinkTop.Ch[0].FrameMode.setDisp('Line')
                self.ClinkFeb[lane].ClinkTop.Ch[0].TapCount.set(8)                    
                self.ClinkFeb[lane].ClinkTop.Ch[0].UartPiranha4.SendEscape()
                self.ClinkFeb[lane].ClinkTop.Ch[0].UartPiranha4.SPF.setDisp('0')
                self.ClinkFeb[lane].ClinkTop.Ch[0].UartPiranha4.GCP()
        else:
            # Disable the PGP PHY device (speed up the simulation)
            self.Hardware.enable.set(False)
            self.Hardware.hidden = True
            # Bypass the time AXIS channel
            eventDev = self.find(typ=axi.AxiStreamBatcherEventBuilder)
            for dev in eventDev:
                dev.Bypass.set(0x1)            
                