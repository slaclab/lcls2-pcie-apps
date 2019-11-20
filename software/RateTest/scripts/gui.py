#!/usr/bin/env python3

import pyrogue

pyrogue.addLibraryPath('../../../firmware/submodules/axi-pcie-core/python')
pyrogue.addLibraryPath('../../../firmware/submodules/clink-gateway-fw-lib/python')
pyrogue.addLibraryPath('../../../firmware/submodules/lcls-timing-core/python')
pyrogue.addLibraryPath('../../../firmware/submodules/lcls2-pgp-fw-lib/python')
pyrogue.addLibraryPath('../../../firmware/submodules/surf/python')
pyrogue.addLibraryPath('../../../firmware/python')

import pyrogue.pydm
import pyrogue.gui
import rogue

from RateTest import RateTestRoot

rogue.Logging.setFilter('pyrogue.prbs.rx',rogue.Logging.Debug)
#rogue.Logging.setLevel(rogue.Logging.Debug)

with RateTestRoot() as root:

    #pyrogue.pydm.runPyDM(root=root)
    pyrogue.gui.runGui(root=root)


