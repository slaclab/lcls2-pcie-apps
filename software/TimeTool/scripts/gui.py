#!/usr/bin/env python3
import pyrogue.gui
import PyQt4.QtGui
import ClinkDev
import sys

cl = ClinkDev.ClinkDev()

# Create GUI
appTop = PyQt4.QtGui.QApplication(sys.argv)
guiTop = pyrogue.gui.GuiTop(group='ClinkDev')
guiTop.addTree(cl)

# Run gui
appTop.exec_()
cl.stop()

