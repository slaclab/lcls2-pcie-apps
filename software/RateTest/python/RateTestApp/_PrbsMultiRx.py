#!/usr/bin/env python3
import pyrogue as pr

class PrbsMultiRx(pr.Device):

    def __init__(self,name='PrbsMultiRx',fwTx=None, swRx=None):
        pr.Device.__init__(self,name=name)

        self._prbsSizeDep  = [v.PacketLength for v in fwTx]
        self._prbsEnDep    = [v.TxEn         for v in fwTx]
        self._prbsCheckDep = [v.checkPayload for v in swRx]
        self._prbsCountDep = [v.rxCount      for v in swRx]
        self._prbsErrorDep = [v.rxErrors     for v in swRx]
        self._prbsRateDep  = [v.rxRate       for v in swRx]
        self._prbsBwDep    = [v.rxBw         for v in swRx]

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

