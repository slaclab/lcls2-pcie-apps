#!/usr/bin/env python3
import pyrogue as pr
import RateTestApp

class RateTestRoot(pr.Root):

    def __init__(self):
        pr.Root.__init__(self,name='RateTestRoot',description='Rate Tester', pollEn=True)

        for i in range(1):
            self.add(RateTestApp.PcieControl(index=i))

            self.add(RateTestApp.PrbsMultiRx(name=f'PrbsMultiRx[{i}]',
                                             fwTx=self.PcieControl[i].Fpga.nodeMatch('PrbsTx[*]'),
                                             swRx=self.PcieControl[i].nodeMatch('PrbsRx[*]')))
        
            self.add(RateTestApp.PrbsMultiTx(name=f'PrbsMultiTx[{i}]',
                                             fwRx=self.PcieControl[i].Fpga.nodeMatch('PrbsRx[*]'),
                                             swTx=self.PcieControl[i].nodeMatch('PrbsTx[*]')))

