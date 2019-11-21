#!/usr/bin/env python3
import pyrogue as pr
import rogue.hardware.axi
import pyrogue.utilities.prbs
import InterCardTest

class PcieControl(pr.Device):

    def __init__(self,index=0):
        pr.Device.__init__(self,name=f'PcieControl[{index}]')

        self._dataMap = rogue.hardware.axi.AxiMemMap(f'/dev/datadev_{index}')

        self.add(InterCardTest.Fpga(memBase=self._dataMap))

