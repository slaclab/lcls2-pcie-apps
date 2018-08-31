#!/usr/bin/env python3
#import pyrogue.gui
import TimeToolDev
import sys
import time
import gc
 
cl = TimeToolDev.TimeToolDev()
time.sleep(0.4)
cl.HW.TimingCore.GtLoopback.set(2)			#use evg timing
time.sleep(0.4)
cl.HW.TimingCore.ConfigLclsTimingV1() 			#Doesn't work yet
time.sleep(0.4)

#working pyrogue script with no gui.(GUI still needed for initial setup).  Will print the last 16 elements from the byte-array p (see TimeToolDev.py) to the screen
#that were collected by the camera. Last printed 4 elements are the time stamp.
time.sleep(0.2)

cl.ClinkTest.ClinkTop.ChannelA.SendEscape()
time.sleep(0.2)
cl.ClinkTest.ClinkTop.ChannelA.SendString("gcp")
time.sleep(0.2)
cl.ClinkTest.ClinkTop.ChannelA.BaudRate.set(9600)
time.sleep(5.0)
cl.ClinkTest.ClinkTop.ChannelA.LinkMode.set(1)		#base mode
time.sleep(0.2)
cl.ClinkTest.ClinkTop.ChannelA.DataMode.set(1)		#8 bit
time.sleep(0.2)
cl.ClinkTest.ClinkTop.ChannelA.FrameMode.set(1)		#linemode
time.sleep(0.2)
cl.ClinkTest.ClinkTop.ChannelA.TapCount.set(4)
time.sleep(0.2)

my_commands_to_pirana_camera = ['clm 0','svm 0', 'sem 0', 'set 5000', 'stm 1', 'spf 0']

for i in my_commands_to_pirana_camera:
	time.sleep(0.2)
	cl.ClinkTest.ClinkTop.ChannelA.SendString(i)






#cl.ClinkTest.ClinkTop.ChannelA.SendString("gcp")

 
cl.ClinkTest.ClinkTop.ChannelA.DataEn.get()
cl.ClinkTest.ClinkTop.ChannelA.DataEn.set(True)	#this start the data collection
time.sleep(10)
cl.ClinkTest.ClinkTop.ChannelA.DataEn.set(False)#this stops the data collection
cl.stop()	#does this need cl.start() counter part? don't see it in gui.py
time.sleep(1)
cl._dbg.close_h5_file()
