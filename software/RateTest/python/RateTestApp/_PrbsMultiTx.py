#!/usr/bin/env python3
import pyrogue as pr

class PrbsMultiTx(pr.Device):

    def __init__(self,name='PrbsMultiTx',swTx=None, fwRx=None):
        pr.Device.__init__(self,name=name)

        self._prbsSizeDep  = [v.txSize          for v in swTx]
        self._prbsEnDep    = [v.txEnable        for v in swTx]
        self._prbsErrorDep = [v.MissedPacketCnt for v in fwRx]
        self._prbsRateDep  = [v.PacketRate      for v in fwRx]
        self._prbsBwDep    = [v.BitRate         for v in fwRx]

        self.add(pr.LinkVariable(name='PrbsSize',disp='{:#x}',dependencies=self._prbsSizeDep,linkedSet=self._setPrbsSize,linkedGet=self._getPrbsSize))
        self.add(pr.LinkVariable(name='PrbsEn',disp=[True,False],dependencies=self._prbsEnDep,linkedSet=self._setPrbsEn,linkedGet=self._getPrbsEn))
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

