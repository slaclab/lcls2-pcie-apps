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

for i in range(10):
	gen_frame_method()
