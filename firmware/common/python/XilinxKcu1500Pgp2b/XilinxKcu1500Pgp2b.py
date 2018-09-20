#!/usr/bin/env python
##############################################################################
## This file is part of 'camera-link-gen1'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'camera-link-gen1', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

import pyrogue as pr
import pyrogue.interfaces.simulation

import axipcie
from surf.xilinx import *
from XilinxKcu1500.TimingCore import *
from XilinxKcu1500Pgp2b.PgpLane import *

class XilinxKcu1500Pgp2b(pr.Device):
    def __init__(   self,       
            name        = "XilinxKcu1500Pgp2b",
            description = "Container for application registers",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
        
        # Add axi-pcie-core 
        self.add(axipcie.AxiPcieCore(            
            offset       = 0x00000000, 
            useSpi       = True,
            expand       = False,
        ))  

        # Add PGP Core 
        for i in range(6):
            self.add(PgpLane(            
                name         = ('Lane[%i]' % i), 
                offset       = (0x00800000 + i*0x00010000), 
                expand       = False,
            ))  
        
        # Add Timing Core
        self.add(TimingCore(
            offset    = 0x00900000,
            expand    = False,
        ))
        
