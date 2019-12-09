#!/usr/bin/env python3
import pyrogue as pr
import InterCardTestApp

class InterCardRoot(pr.Root):

    def __init__(self):
        pr.Root.__init__(self,name='InterCardRoot',description='Tester', pollEn=True)

        for i in range(1):
            self.add(InterCardTestApp.PcieControl(index=i))

    def start(self):
        super().start()

        #base0 = self.PcieControl[0].Fpga.AxiPcieCore.AxiPciePhy.BaseAddressBar[0].get()
        #base1 = self.PcieControl[1].Fpga.AxiPcieCore.AxiPciePhy.BaseAddressBar[0].get()

        #self.PcieControl[0].Fpga.AxiPipCore.REMOTE_BAR0_BASE_ADDRESS[0].set(base1)
        #self.PcieControl[1].Fpga.AxiPipCore.REMOTE_BAR0_BASE_ADDRESS[0].set(base0)

