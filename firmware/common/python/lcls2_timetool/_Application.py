#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# This file is part of the 'Camera link gateway'. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the 'Camera link gateway', including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

import lcls2_timetool

        
class Application(pr.Device):
    def __init__(self, numLanes=1, **kwargs):
        super().__init__(**kwargs) 

        for i in range(numLanes):
            self.add(lcls2_timetool.AppLane(            
                name   = ('AppLane[%i]' % i), 
                offset = 0x00C00000 + (i*0x00100000), 
            ))       
