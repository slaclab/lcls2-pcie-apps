#!/usr/bin/env python3
import pyrogue as pr
import rogue.hardware.data
import rogue.protocols
import surf.axi
import surf.protocols.clink
import time

class ClTestRx(rogue.interfaces.stream.Slave):

    def __init__(self):
        rogue.interfaces.stream.Slave.__init__(self)
        self._count = 0
        self._lerr = 0
        self._derr = 0
        self._ltm = int(time.time())

    def _acceptFrame(self,frame):
        p = bytearray(frame.getPayload())
        frame.read(p,0)
        self._count += 1
        berr = [0,0,0,0,0,0,0,0]

        if len(p) != 2048:
            self._lerr += 1

        for i in range(len(p)):
            exp = i & 0xFF
            if p[i] != exp:
                d = p[i] ^ exp
                c = i % 8
                berr[c] = berr[c] | d
                self._derr += 1
                #print("Mismatch in frame {} position {}. Got = {:#x}, Exp = {:#x}".format(self._count,i,p[i],exp))

        ctm = int(time.time())
        if ctm != self._ltm:
            self._ltm = ctm
            es = "Frame count: {}, Length errors: {}, Data Errors: {}".format(self._count,self._lerr,self._derr)
            for i in range(8):
                es = es + ' {}={:#x}'.format(i,berr[i])
            print(es)

class TimeToolDev(pr.Root):

    def __init__(self):

        pr.Root.__init__(self,name='TimeToolDev',description='CameraLink Dev')

        # Create the stream interface
        self._pgpVc0 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',0,0) # Registers
        self._pgpVc1 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',0,1) # Data
        self._pgpVc2 = rogue.hardware.pgp.PgpCard('/dev/pgpcard_0',0,2) # Serial

        # SRP
        self._srp = rogue.protocols.srp.SrpV3()
        pr.streamConnectBiDir(self._pgpVc0,self._srp)

        # Version registers
        self.add(surf.axi.AxiVersion(memBase=self._srp,offset=0))
        self.add(surf.protocols.clink.ClinkTop(memBase=self._srp,offset=0x10000,serialA=self._pgpVc2))

        # Debug slave
        self._dbg = ClTestRx()
        pr.streamConnect(self._pgpVc1,self._dbg)

        # Start the system
        self.start(pollEn=False)

