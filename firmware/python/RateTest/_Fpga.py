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
import numpy as np

class FpgaBoard(pr.Device):

    def __init__(self,name='Fpga',**kwargs):
        pr.Device.__init__(self,name=name,**kwargs)

        self.add(axipcie.AxiPcieCore(useSpi=True))

        for i in range(4):
            self.add(surf.protocols.ssi.SsiPrbsTx(name=f'prbsTx[{i}]',memBase=self._dataMap,offset=0x00800000 + ((i+2)*0x100000)))

        for i in range(2):
            self.add(surf.protocols.ssi.SsiPrbsRx(name=f'prbsRx[{i}]',memBase=self._dataMap,offset=0x00800000 + ((i+6)*0x100000)))


