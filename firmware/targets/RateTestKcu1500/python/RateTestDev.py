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


class PrbsSummary(pr.Device):

    def __init__(self,tx,rx):
        pr.Device.__init__(self,name='PrbsSummary')

        self._prbsSizeDep  = [v.PacketLength for k,v in tx.items()]
        self._prbsEnDep    = [v.TxEn       for k,v in tx.items()]
        self._prbsCountDep = [v.rxCount    for k,v in rx.items()]
        self._prbsErrorDep = [v.rxErrors   for k,v in rx.items()]
        self._prbsRateDep  = [v.rxRate     for k,v in rx.items()]
        self._prbsBwDep    = [v.rxBw       for k,v in rx.items()]

        self.add(pr.LinkVariable(name='PrbsSize',disp='{:#x}',dependencies=self._prbsSizeDep,linkedSet=self._setPrbsSize,linkedGet=self._getPrbsSize))
        self.add(pr.LinkVariable(name='PrbsEn',disp=[True,False],dependencies=self._prbsEnDep,linkedSet=self._setPrbsEn,linkedGet=self._getPrbsEn))
        self.add(pr.LinkVariable(name='PrbsCount',dependencies=self._prbsCountDep,linkedGet=self._getPrbsCount,mode='RO',disp='{:0.1f}'))
        self.add(pr.LinkVariable(name='PrbsErrors',dependencies=self._prbsErrorDep,linkedGet=self._getPrbsErrors,mode='RO',disp='{:0.1f}'))
        self.add(pr.LinkVariable(name='PrbsRate',dependencies=self._prbsRateDep,linkedGet=self._getPrbsRate,units='Frames/s',mode='RO',disp='{:0.1f}'))
        self.add(pr.LinkVariable(name='PrbsBw',dependencies=self._prbsBwDep,linkedGet=self._getPrbsBw,units='Bytes/s',mode='RO',disp='{:0.1f}'))

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


class RateTestDev(pr.Root):

    def __init__(self,dataEn=True):

        pr.Root.__init__(self,name='RateTestDev',description='Rate Tester')

        # Local map
        self._dataMap = rogue.hardware.axi.AxiMemMap('/dev/datadev_0')

        self.add(axipcie.AxiPcieCore(memBase=self._dataMap,useSpi=True))

        # PGP Card registers
        #self.add(XilinxKcu1500Pgp2b(name='HW',memBase=dataMap))

        self._pgpVc  = {}
        self._prbsRx = {}
        self._prbsTx = {}

        for i in range(4):
            self._prbsTx[i] = surf.protocols.ssi.SsiPrbsTx(name="prbsTx[{}]".format(i),memBase=self._dataMap,offset=0x00800000 + (i*0x100000)) 
            self.add(self._prbsTx[i])

            self._pgpVc[i] = rogue.hardware.axi.AxiStreamDma('/dev/datadev_0',i*256,True)

            self._prbsRx[i] = pyrogue.utilities.prbs.PrbsRx(name="prbsRx[{}]".format(i), width=256)
            self.add(self._prbsRx[i])

            pyrogue.streamConnect(self._pgpVc[i],self._prbsRx[i])

        self.add(PrbsSummary(tx=self._prbsTx,rx=self._prbsRx))

        # Start the system
        self.start(pollEn=True)

