#!/usr/bin/env python3
import pyrogue as pr
import axipcie
import surf.protocols.ssi

class Fpga(pr.Device):

    def __init__(self,name='Fpga',**kwargs):
        pr.Device.__init__(self,name=name,**kwargs)

        self.add(axipcie.AxiPcieCore(useSpi=True))

        self.add(surf.protocols.ssi.SsiPrbsTx(name=f'PrbsTx',offset=0x00800000))
        self.add(surf.protocols.ssi.SsiPrbsRx(name=f'PrbsRx',offset=0x00900000))
        self.add(axipcie.AxiPipCore(offset=0x00A00000))

