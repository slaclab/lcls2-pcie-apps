#!/usr/bin/env python3
import pyrogue as pr
import rogue.hardware.data
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
        self.frameCount.set(self.frameCount.value() + 1,False)
        berr = [0,0,0,0,0,0,0,0]

        if len(p) != 2048:
            self.lengthErrors.set(self.lengthErrors.value() + 1,False)
        else:

            for i in range(2048):
                exp = i & 0xFF
                if p[i] != exp:
                    #print("Error at pos {}. Got={:2x}, Exp={:2x}".format(i,p[i],exp))
                    d = p[i] ^ exp
                    c = i % 8
                    berr[c] = berr[c] | d
                    self.dataErrors.set(self.dataErrors.value() + 1,False)

        #print(len(p))
        to_print = np.array(p)[-16:]
        print(to_print)
        #self.to_save_to_h5.append(to_print)

        for i in range(8):
            self.node('byteError{}'.format(i)).set(berr[i],False)

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
        self.add(TimeTool.TimeToolCore(memBase=dataMap,offset=0x00800000))  #changed from 0x00C00000 by pcds group. this offset is propagated to
                                                                            #AddValue that is instantiated in TimeTool.py
                                                                            #the vhd file that has the firmware counterpart to this offset is firmware/
                                                                            #submodules/axi-pcie-core/hardware/XilinxKcu1500/core/rtl/XilinxKcu1500Core.vhd
                                                                            #the comment above is incorrect.  it's lcls2-pcie-apps/firmware/submodules/surf/protocols/
                                                                            #clink/hdl/ClinkTop.vhd and _ClinkTop.py

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

