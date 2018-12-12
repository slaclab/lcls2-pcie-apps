#!/usr/bin/env python3
import pyrogue.gui
import RateTestDev
import sys

import rogue

#rogue.Logging.setFilter('pyrogue.prbs.rx',rogue.Logging.Debug)
#rogue.Logging.setLevel(rogue.Logging.Debug)

cl = RateTestDev.RateTestDev()

# Create GUI
appTop = pyrogue.gui.application(sys.argv)
guiTop = pyrogue.gui.GuiTop(group='TimeToolDev')
guiTop.addTree(cl)

# Run gui
appTop.exec_()
cl.stop()

