#!/usr/bin/env python3
import pyrogue as pr
import rogue.protocols
import surf.axi
import surf.protocols.clink
import time
import TimeTool
import pyrogue.utilities.fileio
from XilinxKcu1500Pgp2b import *
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
        """my_mask = np.arange(36)
        my_mask = np.append(my_mask,np.arange(1024,1024+36))
        my_mask = np.append(my_mask,np.arange(2096-36,2096))
        to_print = np.array(p)[-1:]
        #print(np.array(p)[:96],to_print) #comment out for long term test
        print(np.array(p)[my_mask])
        print("____________________________________________________")
        self.frameCount.set(self.frameCount.value() + 1,False)"""

     
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

class ClinkTest(pr.Device):

    def __init__(self, regStream, serialStreamA, serialStreamB=None, name="ClinkTest", **kwargs):
        super().__init__(name=name,**kwargs)

        # SRP
        self._srp = rogue.protocols.srp.SrpV3()
        pr.streamConnectBiDir(regStream,self._srp)

        # Version registers
        self.add(surf.axi.AxiVersion(memBase=self._srp,offset=0))
        self.add(surf.protocols.clink.ClinkTop(memBase=self._srp,offset=0x10000,serialA=serialStreamA,serialB=serialStreamB))

class TimeToolDev(pr.Root):

    def __init__(self, dataDebug=False):

        pr.Root.__init__(self,name='TimeToolDev',description='CameraLink Dev')

        # Create the stream interface
        self._pgpVc0 = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',0,True) # Registers
        self._pgpVc1 = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',1,True) # Data
        self._pgpVc2 = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',2,True) # Serial

        # Local map
        dataMap = rogue.hardware.axi.AxiMemMap('/dev/datadev_0')

        # Cameralink
        self.add(ClinkTest(regStream=self._pgpVc0,serialStreamA=self._pgpVc2))

        # Time tool application
        self.add(TimeTool.TimeToolCore(memBase=dataMap,offset=0x00C00000))

        # PGP Card registers
        self.add(XilinxKcu1500Pgp2b(name='HW',memBase=dataMap))

        # File writer
        dataWriter = pyrogue.utilities.fileio.StreamWriter(name='dataWriter',configEn=True)
        self.add(dataWriter)
        pr.streamConnect(self._pgpVc1,dataWriter.getChannel(0))
        pr.streamConnect(self,dataWriter.getChannel(1))

        # Debug slave
        if dataDebug:
            self._dbg = TimeToolRx()
            pr.streamTap(self._pgpVc1,self._dbg)
            self.add(self._dbg)

        # Start the system
        self.start(pollEn=True)

