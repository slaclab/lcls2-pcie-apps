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

def status():
    print("LinkWidth={}".format(cl.AxiPcieCore.AxiPciePhy.LinkWidth.get()))
    print("LinkWidth16={}".format(cl.AxiPcieCore.AxiPciePhy.LinkWidth16.get()))
    print("LinkRateGen2={}".format(cl.AxiPcieCore.AxiPciePhy.LinkRateGen2.get()))
    print("LinkRateGen3={}".format(cl.AxiPcieCore.AxiPciePhy.LinkRateGen3.get()))
    print("BuildStamp={}".format(cl.AxiPcieCore.AxiVersion.BuildStamp.get()))
    print("FrameRate0={}".format(cl.AxiPcieCore.DmaIbAxisMon.FrameRate[0].get()))
    print("FrameRate1={}".format(cl.AxiPcieCore.DmaIbAxisMon.FrameRate[0].get()))
    print("FrameRate2={}".format(cl.AxiPcieCore.DmaIbAxisMon.FrameRate[0].get()))
    print("FrameRate3={}".format(cl.AxiPcieCore.DmaIbAxisMon.FrameRate[0].get()))
    print("")

    total  = cl.AxiPcieCore.DmaIbAxisMon.FrameRate[0].get() 
    total += cl.AxiPcieCore.DmaIbAxisMon.FrameRate[1].get()
    total += cl.AxiPcieCore.DmaIbAxisMon.FrameRate[2].get()
    total += cl.AxiPcieCore.DmaIbAxisMon.FrameRate[3].get()

    size = ((cl.prbsTx0.PacketLength.get() + 1) * 16)
    bw = total * size * 8

    print("      Size: {:,} Bytes".format(size))
    print("Total Rate: {:,}".format(total))
    print("  Total Bw: {:,} Gbps".format(bw))


print("enableTx, disableTx, setSize, status")
