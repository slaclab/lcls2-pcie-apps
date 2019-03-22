#!/usr/bin/env python3
#import pyrogue.gui
import TimeToolDev
import sys
import time
import gc
 
cl = TimeToolDev.TimeToolDev(True)
#time.sleep(0.4)
#cl.HW.TimingCore.GtLoopback.set(2)			#use evg timing
#time.sleep(0.4)
#cl.HW.TimingCore.ConfigLclsTimingV1() 			#Doesn't work yet
#time.sleep(0.4)

#working pyrogue script with no gui.(GUI still needed for initial setup).  Will print the last 16 elements from the byte-array p (see TimeToolDev.py) to the screen
#that were collected by the camera. Last printed 4 elements are the time stamp.
#time.sleep(0.2)

cl.ClinkFeb[0].UartPiranha4[0]._tx.SendEscape()
#time.sleep(0.2)
cl.ClinkFeb[0].UartPiranha4[0]._tx.SendString("gcp")
#time.sleep(0.2)
cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.BaudRate.set(9600)
#time.sleep(5.0)
cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.LinkMode.set(1)		#base mode
#time.sleep(0.2)
cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.DataMode.set(1)		#8 bit
#time.sleep(0.2)
cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.FrameMode.set(1)		#linemode
#time.sleep(0.2)
cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.TapCount.set(4)
#time.sleep(0.2)


#these commands are sent over serial to the camera unit
#clm: Camera Mink Mode. 0 = base, 1 = medium, 2 = full, 3 = deca
#svm: test pattern mode
#sem: Set Exposure Mode
#set: Set Exposure Time
#stm: External Trigger Mode

my_commands_to_pirana_camera = ['clm 0','svm 0', 'sem 0', 'set 5000', 'stm 1', 'spf 0']

for i in my_commands_to_pirana_camera:
	print("sent command: "+i)
	cl.ClinkFeb[0].UartPiranha4[0]._tx.SendString(i)
	time.sleep(0.1)			 			#commands sent too quickly we see serial data 
                                                                #corruption. e.g. "svm" turns into "jvm".  
                                                                #Could be done more by setting a semaphore in
                                                                # _acceptframe in ClinkSerialRx





time.sleep(3)
#cl.ClinkFeb[0].UartPiranha4[0]._tx.SendString("gcp")

 
cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.DataEn.get()
cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.DataEn.set(True)	#this start the data collection
time.sleep(1)
cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.DataEn.set(False)#this stops the data collection


#validating prescalling

cl.ClinkFeb[0].UartPiranha4[0]._tx.SendString('svm 0')    #test pattern. 1 is Ramp, 0 is sensor video
cl.ClinkFeb[0].UartPiranha4[0]._tx.SendString('stm 1')    #1 is internal trigger, 2 is External pulse width. Manual description is off by one

def frame_rate(sec):
    start_time  = time.time()
    start_count = cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.FrameCount.get()

    time.sleep(sec)

    stop_time  = time.time()
    stop_count = cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.FrameCount.get()

    return (stop_count-start_count)*1.0/(stop_time-start_time)

#cl.stop()	#does this need cl.start() counter part? don't see it in gui.py
#time.sleep(1)
#cl._dbg.close_h5_file()



cl.ClinkFeb[0].UartPiranha4[0]._tx.SendString('ssf 7000')
cl.ClinkFeb[0].UartPiranha4[0]._tx.SendString('ssf 6000')
cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.DropCount.get()
cl.TimeTool.dialInPreScaling.set(254)
cl.TimeTool.dialInPreScaling.set(124)
cl.TimeTool.DialInOpCode.set(40)
cl.TimeTool.dialInPreScaling.set(125)
cl.ClinkFeb[0].ClinkTop.ChannelA.BaudRate.DropCount.get()
frame_rate(2)

