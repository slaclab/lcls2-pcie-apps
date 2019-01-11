#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : Timetool package
#-----------------------------------------------------------------------------
# File       : TimeTool.py
# Created    : 2017-11-21
#-----------------------------------------------------------------------------
# Description:
# Timetool application
#-----------------------------------------------------------------------------
# This file is part of the rogue software platform. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the rogue software platform, including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

class TimeToolCore(pr.Device):
    def __init__(   self,       
            name        = "TimeTool",
            **kwargs):
        super().__init__(name=name, **kwargs) 

        #to allow pyrogue to see a new register duplicate the code below using a differen "offset" and "name"
        #see timetooldev.py and ClinkTop.vhd and _ClinkTop.py for examples how to make python send data to firmware.
        self.add(pr.RemoteVariable(    
            name         = "AddValue",
            offset       =  0x00,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(    
            name         = "dialInPreScaling",
            #offset       =  0x00,
            offset       =  0x10000,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))

        self.add(pr.RemoteVariable(    
            name         = "axi_test",
            #offset       =  0x00,
            offset       =  0x20000,
            bitSize      =  8,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))
