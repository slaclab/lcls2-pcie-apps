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


class PrbsSummary(pr.Device):

    def __init__(self,tx,rx,name='PrbsSummary'):
        pr.Device.__init__(self,name=name)

        self._prbsSizeDep  = [v.PacketLength for v in tx]
        self._prbsEnDep    = [v.TxEn         for v in tx]
        self._prbsCheckDep = [v.checkPayload for v in rx]
        self._prbsCountDep = [v.rxCount      for v in rx]
        self._prbsErrorDep = [v.rxErrors     for v in rx]
        self._prbsRateDep  = [v.rxRate       for v in rx]
        self._prbsBwDep    = [v.rxBw         for v in rx]

        self.add(pr.LinkVariable(name='PrbsSize',disp='{:#x}',dependencies=self._prbsSizeDep,linkedSet=self._setPrbsSize,linkedGet=self._getPrbsSize))
        self.add(pr.LinkVariable(name='PrbsEn',disp=[True,False],dependencies=self._prbsEnDep,linkedSet=self._setPrbsEn,linkedGet=self._getPrbsEn))
        self.add(pr.LinkVariable(name='PrbsCheck',dependencies=self._prbsCheckDep,linkedGet=self._getPrbsCheck,linkedSet=self._setPrbsCheck,disp=[True,False]))
        self.add(pr.LinkVariable(name='PrbsCount',dependencies=self._prbsCountDep,linkedGet=self._getPrbsCount,mode='RO',disp='{}'))
        self.add(pr.LinkVariable(name='PrbsErrors',dependencies=self._prbsErrorDep,linkedGet=self._getPrbsErrors,mode='RO',disp='{}'))
        self.add(pr.LinkVariable(name='PrbsRate',dependencies=self._prbsRateDep,linkedGet=self._getPrbsRate,units='Frames/s',mode='RO',disp='{:0.2e}'))
        self.add(pr.LinkVariable(name='PrbsBw',dependencies=self._prbsBwDep,linkedGet=self._getPrbsBw,units='Bytes/s',mode='RO',disp='{:0.2e}'))

    def _setPrbsSize(self,value):
        for i in self._prbsSizeDep:
            i.set(value)

    def _getPrbsSize(self,read):
        return self._prbsSizeDep[0].get(read)

    def _setPrbsEn(self,value):
        for i in self._prbsEnDep:
            i.set(value)

    def _getPrbsEn(self,read):
        return self._prbsEnDep[0].get(read)

    def _getPrbsCount(self,read):
        cnt = 0
        for i in self._prbsCountDep:
            cnt += i.get(read)
        return cnt

    def _getPrbsErrors(self,read):
        cnt = 0
        for i in self._prbsErrorDep:
            cnt += i.get(read)
        return cnt

    def _getPrbsRate(self,read):
        cnt = 0.0
        for i in self._prbsRateDep:
            cnt += i.get(read)
        return cnt

    def _getPrbsBw(self,read):
        cnt = 0.0
        for i in self._prbsBwDep:
            cnt += i.get(read)
        return cnt

    def _setPrbsCheck(self,value):
        for i in self._prbsCheckDep:
            i.set(value)

    def _getPrbsCheck(self,read):
        return self._prbsCheckDep[0].get(read)


class FpgaBoard(pr.Device):

    def __init__(self,index=0):
        pr.Device.__init__(self,name=f'Fpga[{index}]')

        self._dataMap = rogue.hardware.axi.AxiMemMap(f'/dev/datadev_{index}')

        self.add(axipcie.AxiPcieCore(memBase=self._dataMap,useSpi=True))

        self._prbsTx = [None] * 4
        self._prbsRx = [None] * 4
        self._data   = [None] * 4

        for i in range(4):
            self._prbsTx[i] = surf.protocols.ssi.SsiPrbsTx(name=f'prbsTx[{i}]',memBase=self._dataMap,offset=0x00800000 + ((i+2)*0x100000)) 
            self.add(self._prbsTx[i])

            self._data[i]   = rogue.hardware.axi.AxiStreamDma(f'/dev/datadev_{index}',(i+4)*256,True)
            self._prbsRx[i] = pyrogue.utilities.prbs.PrbsRx(name=f'prbsRx[{i}]', width=256)
            self.add(self._prbsRx[i])

            pyrogue.streamConnect(self._data[i],self._prbsRx[i])


class RateTestRoot(pr.Root):

    def __init__(self):
        pr.Root.__init__(self,name='RateTestRoot',description='Rate Tester', pollEn=True)
        self._fpga = [None] * 2

        for i in range(2):
            self._fpga[i] = FpgaBoard(index=i)

            self.add(self._fpga[i])

            self.add(PrbsSummary(rx=self._fpga[i]._prbsRx,tx=self._fpga[i]._prbsTx,name=f'PrbsSummary[{i}]'))

