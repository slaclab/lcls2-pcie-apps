#!/usr/bin/env python3
import setupLibPaths
import TimeToolDev
import sys
import time
import gc
import IPython

cl = TimeToolDev.TimeToolDev(
    dev       = "sim",
    dataDebug = True,
    #version3  = False,
    pollEn    = False,
    initRead  = False,
)
cl.LoadConfig("config/TimeToolVcsSimTest_lcls-pc823236.yml")

cl.Application.AppLane[0].ByPass.ByPass.set(0x1)

cl.Application.AppLane[0].EventBuilder.Bypass.set(0x1)

cl.StartRun()

gen_frame_method = cl.GenFrame[0]

cl.Application.AppLane[0].Prescale.DialInPreScaling.set(2)


start_count = 0

#IPython.embed()

for i in range(10):
      print("counter = "+str(start_count))
	#gen_frame_method()
      cl.GenFrame[0]()

      too_many_counter  = 0
      while(cl.TimeToolRx.frameCount.get()<start_count+1):
            too_many_counter = too_many_counter +1
            time.sleep(1)
            if(too_many_counter>20): break

      start_count = cl.TimeToolRx.frameCount.get()

      #cl._frameGen[0].make_byte_array()

 
      print("data_out = "+str(cl.TimeToolRx.parsed_data))

cl.stop()

#cl.ClinkFeb[0].UartPiranha4[0]._tx.sendString('ssf 7000')
#cl.ClinkFeb[0].UartPiranha4[0]._tx.sendString('ssf 6000')
#cl.ClinkFeb[0].ClinkTop.Channel[0].DropCount.get()
#cl.Application.AppLane[0].Prescale.DialInPreScaling.set(254)
#cl.Application.AppLane[0].Prescale.DialInPreScaling.set(124)
#cl.Application.AppLane[0].Prescale.DialInPreScaling.set(125)
#cl.ClinkFeb[0].ClinkTop.Channel[0].DropCount.get()
