#!/usr/bin/env python3
import pyrogue.gui
import TimeToolDev
import sys
import time
 
#this script attempts to write to "add_value" implemented in the TimeTool firmware and software.  Currently not working as of 6/26/2018
#from a python shell type 
#exec(open("./pyrogue_axi_example.py").read())
#

cl = TimeToolDev.TimeToolDev(True)
cl.TimeTool.AddValue.set(4)  #this command is currently failing. it's located in 
#File "/u1/sioan/rogue/python/pyrogue/_Variable.py", line 183, in set
#it fails when the _checkTransaction method reads the memory location.
#AddValue is instantiated in lcls2-pcie-apps/firmware/applications/TimeTool/TimeTool.py




#trouble shooting to do list
#1) where is AddValue instantiated?
#2) where is the memory located? (exception indicates it's 0xc00000)
#3) 
 
#cl.stop()	#need to be run before exiting the python session.  If not run, /dev/datadev may still be open and computer reboot and insmod the driver again.
		#unless there is some way to close /dev/datadev with loggin out
