#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AMC Carrier Cryo Demo Board Application
#-----------------------------------------------------------------------------
# File       : AppCore.py
# Created    : 2017-04-03
#-----------------------------------------------------------------------------
# Description:
# PyRogue AMC Carrier Cryo Demo Board Application
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
import pyrogue.simulation
import rogue.hardware.data

from DataLib.DataDev import *
from surf.xilinx import *
from PgpCardG3Pgp2b.TimingCore import *
from PgpCardG3Pgp2b.PgpLane import *

class PgpCardG3Pgp2b(pr.Device):
    def __init__(   self,       
            name        = "PgpCardG3Pgp2b",
            description = "Container for application registers",
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)
        
        # Add axi-pcie-core 
        self.add(DataDev(            
            offset       = 0x00000000, 
            useBpi       = True,
            expand       = False,
        ))  

        # Add PGP Core 
        for i in range(8):
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