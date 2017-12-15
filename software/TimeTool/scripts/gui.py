#!/usr/bin/env python3
import pyrogue.gui
import PyQt4.QtGui
import TimeToolDev
import sys

cl = TimeToolDev.TimeToolDev(True)

# Create GUI
appTop = PyQt4.QtGui.QApplication(sys.argv)
guiTop = pyrogue.gui.GuiTop(group='TimeToolDev')
guiTop.addTree(cl)

# Run gui
appTop.exec_()
cl.stop()

