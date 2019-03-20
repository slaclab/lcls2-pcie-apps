#!/usr/bin/env python3
import pyrogue as pr

import rogue.hardware.axi
import rogue.protocols
import pyrogue.interfaces.simulation
import pyrogue.utilities.fileio

import XilinxKcu1500Pgp as kcu1500
import ClinkFeb         as feb
import TimeTool         as app

import numpy as np
import h5py

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

class TimeToolDev(pr.Root):

    def __init__(self,
            name        = 'TimeToolDev',
            description = 'Container for TimeTool Dev',
            dataDebug   = False,
            dev         = '/dev/datadev_0',# path to PCIe device
            version3    = False,           # true = PGPv3, false = PGP2b
            pollEn      = True,            # Enable automatic polling registers
            initRead    = True,            # Read all registers at start of the system
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        self._numLane = 1
        
        # Create PCIE memory mapped interface
        if (dev != 'sim'):
            # BAR0 access
            self.memMap = rogue.hardware.axi.AxiMemMap(dev)     
            # Set the timeout
            self._timeout = 1.0 # 1.0 default
        else:
            # FW/SW co-simulation
            self.memMap = rogue.interfaces.memory.TcpClient('localhost',8000)            
            # Set the timeout
            self._timeout = 100.0 # firmware simulation slow and timeout base on real time (not simulation time)        
                    
        # PGP Hardware on PCIe 
        self.add(kcu1500.Hardware(            
            memBase  = self.memMap,
            numLane  = self._numLane,
            version3 = version3,
            expand   = False,
        ))           

        # # File writer
        # self.dataWriter = pyrogue.utilities.fileio.StreamWriter(name='dataWriter',configEn=True)
        # self.add(self.dataWriter)        
        
        # Create arrays to be filled
        self._dma = [[None for vc in range(4)] for lane in range(self._numLane)] # self._dma[lane][vc]
        self._srp =  [None for lane in range(self._numLane)]        
        self._dbg =  [None for lane in range(self._numLane)]        
        
        # Create the stream interface
        for lane in range(self._numLane):
        
            # Map the virtual channels 
            if (dev != 'sim'):
                # PCIe DMA interface
                self._dma[lane][0] = rogue.hardware.axi.AxiStreamDma(dev,(0x100*lane)+0,True) # VC0 = Registers
                self._dma[lane][1] = rogue.hardware.axi.AxiStreamDma(dev,(0x100*lane)+1,True) # VC1 = Data
                self._dma[lane][2] = rogue.hardware.axi.AxiStreamDma(dev,(0x100*lane)+2,True) # VC2 = Serial
                self._dma[lane][3] = rogue.hardware.axi.AxiStreamDma(dev,(0x100*lane)+3,True) # VC3 = Serial
                # Disabling zero copy on the data stream (due to unknown max size)
                self._dma[lane][1].setZeroCopyEn(False)    
            else:
                # FW/SW co-simulation
                self._dma[lane][0] = rogue.interfaces.stream.TcpClient('localhost',8002+(512*lane)+2*0) # VC0 = Registers
                self._dma[lane][1] = rogue.interfaces.stream.TcpClient('localhost',8002+(512*lane)+2*1) # VC1 = Data
                self._dma[lane][2] = rogue.interfaces.stream.TcpClient('localhost',8002+(512*lane)+2*2) # VC2 = Serial
                self._dma[lane][3] = rogue.interfaces.stream.TcpClient('localhost',8002+(512*lane)+2*3) # VC3 = Serial
                
            # SRP
            self._srp[lane] = rogue.protocols.srp.SrpV3()
            pr.streamConnectBiDir(self._dma[lane][0],self._srp[lane])
                     
            # CameraLink Feb Board
            self.add(feb.ClinkFeb(      
                name        = (f'ClinkFeb[{lane}]'), 
                memBase     = self._srp[lane], 
                serialA     = self._dma[lane][2],
                serialB     = self._dma[lane][3],
                camTypeA    = 'Opal000', # Assuming OPA 1000 camera
                camTypeB    = 'Opal000', # Assuming OPA 1000 camera
                version3    = version3,
                enableDeps  = [self.Hardware.PgpMon[lane].RxRemLinkReady], # Only allow access if the PGP link is established
                expand      = False,
            ))
            
            # # Connect the file writer
            # pr.streamConnect(self.self._dma[lane][1],self.dataWriter.getChannel(2*lane+0))
            # pr.streamConnect(self,self.dataWriter.getChannel(2*lane+1))

            # Debug slave
            if dataDebug:
                self._dbg[lane] = TimeToolRx()
                pr.streamTap(self._dma[lane][1],self._dbg[lane])
                self.add(self._dbg)
                
        # Time tool application
        self.add(app.TimeToolCore(
            memBase = self.memMap,
            offset  = 0x00C00000,
        ))

        # Start the system
        self.start(
            pollEn   = pollEn,
            initRead = initRead,
            timeout  = self._timeout,
        )

