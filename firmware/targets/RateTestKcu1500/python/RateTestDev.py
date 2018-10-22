#!/usr/bin/env python3
import pyrogue as pr
import rogue.protocols
import surf.axi
import axipcie
import surf.protocols.clink
import surf.protocols.ssi
import time
import TimeTool
import pyrogue.utilities.fileio
import pyrogue.utilities.prbs
from XilinxKcu1500Pgp2b import *
import numpy as np

class RateTestDev(pr.Root):

    def __init__(self):

        pr.Root.__init__(self,name='RateTestDev',description='Rate Tester')

        # Local map
        dataMap = rogue.hardware.axi.AxiMemMap('/dev/datadev_0')

        # Time tool application
        self.add(surf.protocols.ssi.SsiPrbsTx(name="prbsTx0",memBase=dataMap,offset=0x00800000))
        self.add(surf.protocols.ssi.SsiPrbsTx(name="prbsTx1",memBase=dataMap,offset=0x00900000))
        self.add(surf.protocols.ssi.SsiPrbsTx(name="prbsTx2",memBase=dataMap,offset=0x00A00000))
        self.add(surf.protocols.ssi.SsiPrbsTx(name="prbsTx3",memBase=dataMap,offset=0x00B00000))

        self.add(axipcie.AxiPcieCore(memBase=dataMap,useSpi=True))

        # PGP Card registers
        #self.add(XilinxKcu1500Pgp2b(name='HW',memBase=dataMap))

        #self._pgpVc0 = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',0,True) # Registers
        #self._prbsRx = pyrogue.utilities.prbs.PrbsRx(name="prbsRx", width=128)
        #self.add(self._prbsRx)

        #pyrogue.streamConnect(self._pgpVc0,self._prbsRx)

        # Start the system
        self.start(pollEn=True)

