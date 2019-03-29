import TimeToolDev
import sys
import time
import gc

cl = TimeToolDev.TimeToolDev(
    dev       = "sim",
    dataDebug = True,
    version3  = False,
    pollEn    = False,
    initRead  = False,
)
cl.ReadConfig("config/sim_lcls-pc823236.yml")

cl.GenFrame[0]

gen_frame_method = cl.GenFrame[0]

cl.Application.AppLane[0].Prescale.DialInPreScaling.set(2)
for i in range(10):
	#gen_frame_method()
	cl.GenFrame[0]()


#cl.ClinkFeb[0].UartPiranha4[0]._tx.sendString('ssf 7000')
#cl.ClinkFeb[0].UartPiranha4[0]._tx.sendString('ssf 6000')
#cl.ClinkFeb[0].ClinkTop.Channel[0].DropCount.get()
#cl.Application.AppLane[0].Prescale.DialInPreScaling.set(254)
#cl.Application.AppLane[0].Prescale.DialInPreScaling.set(124)
#cl.Application.AppLane[0].Prescale.DialInPreScaling.set(125)
#cl.ClinkFeb[0].ClinkTop.Channel[0].DropCount.get()
