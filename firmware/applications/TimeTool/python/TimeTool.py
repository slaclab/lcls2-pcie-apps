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

        self.add(pr.RemoteVariable(    
            name         = "Test",
            offset       =  0x00,
            bitSize      =  32,
            bitOffset    =  0,
            base         = pr.UInt,
            mode         = "RW",
        ))


