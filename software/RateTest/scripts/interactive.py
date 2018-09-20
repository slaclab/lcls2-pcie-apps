#!/usr/bin/env python3
import pyrogue.gui
import RateTestDev
import sys

cl = RateTestDev.RateTestDev()

def enableTx():
    cl.prbsTx0.TxEn.set(True)
    cl.prbsTx1.TxEn.set(True)
    cl.prbsTx2.TxEn.set(True)
    cl.prbsTx3.TxEn.set(True)

def disableTx():
    cl.prbsTx0.TxEn.set(False)
    cl.prbsTx1.TxEn.set(False)
    cl.prbsTx2.TxEn.set(False)
    cl.prbsTx3.TxEn.set(False)

def setSize(size):
    cl.prbsTx0.PacketLength.set(size)
    cl.prbsTx1.PacketLength.set(size)
    cl.prbsTx2.PacketLength.set(size)
    cl.prbsTx3.PacketLength.set(size)

print("enableTx, disableTx, setSize")
