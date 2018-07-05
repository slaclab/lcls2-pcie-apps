#!/usr/bin/env python3
#import pyrogue.gui
import TimeToolDev
import sys
import time
import gc
 
#working pyrogue script with no gui.(GUI still needed for initial setup).  Will print the last 16 elements from the byte-array p (see TimeToolDev.py) to the screen
#that were collected by the camera. Last printed 4 elements are the time stamp.


cl = TimeToolDev.TimeToolDev(True)
 
 
cl.ClinkTest.ClinkTop.ChannelA.DataEn.get()
cl.ClinkTest.ClinkTop.ChannelA.DataEn.set(True)	#this start the data collection
time.sleep(3)
cl.ClinkTest.ClinkTop.ChannelA.DataEn.set(False)#this stops the data collection
cl.stop()	#does this need cl.start() counter part? don't see it in gui.py
time.sleep(1)
cl._dbg.close_h5_file()
