#!/usr/bin/env python3
import pyrogue as pr
import rogue.hardware.data
import rogue.protocols
import surf.axi
import surf.protocols.clink
import time
import TimeTool
from XilinxKcu1500Pgp2b import *

class TimeToolRx(pr.Device,rogue.interfaces.stream.Slave):

    def __init__(self, name='TimeToolRx', **kwargs):
        rogue.interfaces.stream.Slave.__init__(self)
        pr.Device.__init__(self,name=name,**kwargs)

        self.add(pr.LocalVariable( name='frameCount',   value=0, mode='RO', pollInterval=1))
        self.add(pr.LocalVariable( name='lengthErrors', value=0, mode='RO', pollInterval=1))
        self.add(pr.LocalVariable( name='dataErrors',   value=0, mode='RO', pollInterval=1))

        for i in range(8):
            self.add(pr.LocalVariable( name='byteError{}'.format(i), value=0, mode='RO', pollInterval=1))

    def _acceptFrame(self,frame):
        p = bytearray(frame.getPayload())
        frame.read(p,0)
        self._count += 1
        berr = [0,0,0,0,0,0,0,0]

        if len(p) != 2048:
            self.lengthErrors.set(self.lengthErrors.value() + 1)

        for i in range(len(p)):
            exp = i & 0xFF
            if p[i] != exp:
                d = p[i] ^ exp
                c = i % 8
                berr[c] = berr[c] | d
                self.dataErrors.set(self.dataErrors.value() + 1)

        for i in range(8):
            self.node('byteError{}'.format(i)).set(berr[i])

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

    def __init__(self):

        pr.Root.__init__(self,name='TimeToolDev',description='CameraLink Dev')

        # Create the stream interface
        self._pgpVc0 = rogue.hardware.data.DataCard('/dev/datadev_0',0) # Registers
        self._pgpVc1 = rogue.hardware.data.DataCard('/dev/datadev_0',1) # Data
        self._pgpVc2 = rogue.hardware.data.DataCard('/dev/datadev_0',2) # Serial

        # Local map
        dataMap = rogue.hardware.data.DataMap('/dev/datadev_0')

        # Cameralink
        self.add(Clink(regStream=self._pgpVc0,serialStreamA=self._pgpVc2))

        # Time tool application
        self.add(TimeTool.TimeToolCore(memBase=dataMap,offset=0x00400000))

        # PGP Card registers
        self.add(XilinxKcu1500Pgp2b(name='HW',memBase=dataMap))

        # Debug slave
        self._dbg = TimeToolRx()
        pr.streamConnect(self._pgpVc1,self._dbg)
        self.add(self._dbg)

        # Start the system
        self.start(pollEn=True)

