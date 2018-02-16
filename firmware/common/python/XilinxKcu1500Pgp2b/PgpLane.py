#!/usr/bin/env python
#-----------------------------------------------------------------------------
# Title      : PyRogue AMC Carrier Cryo Demo Board Application
#-----------------------------------------------------------------------------
# File       : PgpLane.py
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

from surf.xilinx import *
from surf.protocols.pgp import *

class PgpLane(pr.Device):
    def __init__(   self,       
            name        = "PgpLane",
            description = "PgpLane",
            basicMode   = True,            
            useEvr      = True,            
            **kwargs):
        super().__init__(name=name, description=description, **kwargs)

        # Add GT interface
        self.add(Gthe3Channel(            
            name         = 'GTH', 
            offset       = 0x0000, 
            expand       = False,
            hidden       = basicMode,
        ))  

        # Add Lane Monitor
        self.add(Pgp2bAxi(            
            name         = 'Monitor', 
            offset       = 0x1000, 
            expand       = False,
        ))          
        
        regOffset = 0x2000            
        
        if (useEvr):            
            self.addRemoteVariables(  
                name         = "LutDropCnt",
                description  = "",
                offset       = (regOffset | 0x00),
                bitSize      = 32,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RO",
                number       = 4,            
                stride       = 4,            
                pollInterval = 1
            )

            self.addRemoteVariables(  
                name         = "FifoErrorCnt",
                description  = "",
                offset       = (regOffset | 0x10),
                bitSize      = 32,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RO",
                number       = 4,            
                stride       = 4,            
                pollInterval = 1
            )

            self.addRemoteVariables(  
                name         = "VcPauseCnt",
                description  = "",
                offset       = (regOffset | 0x20),
                bitSize      = 32,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RO",
                number       = 4,            
                stride       = 4,            
                pollInterval = 1
            )

            self.addRemoteVariables(  
                name         = "VcOverflowCnt",
                description  = "",
                offset       = (regOffset | 0x30),
                bitSize      = 32,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RO",
                number       = 4,            
                stride       = 4,            
                pollInterval = 1
            )  
            
            self.add(pr.RemoteVariable( 
                name         = "RunCode",
                description  = "Run OP-Code for triggering",
                offset       = (regOffset | 0x40),
                bitSize      = 8,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RW",
            ))  

            self.add(pr.RemoteVariable( 
                name         = "AcceptCode",
                description  = "Accept OP-Code for triggering",
                offset       = (regOffset | 0x44),
                bitSize      = 8,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RW",
            ))  

            self.add(pr.RemoteVariable( 
                name         = "EnHdrTrig",
                description  = "Enable Header Trigger Checking/filtering",
                offset       = (regOffset | 0x48),
                bitSize      = 4,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RW",
            ))

            self.add(pr.RemoteVariable( 
                name         = "RunDelay",
                description  = "Delay for the RUN trigger",
                offset       = (regOffset | 0x4C),
                bitSize      = 32,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RW",
            ))  

            self.add(pr.RemoteVariable( 
                name         = "AcceptDelay",
                description  = "Delay for the ACCEPT trigger",
                offset       = (regOffset | 0x50),
                bitSize      = 32,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RW",
            ))          

            self.add(pr.RemoteCommand(  
                name         = "AcceptCntRst",
                description  = "Reset for the AcceptCnt",
                offset       = (regOffset | 0x54),
                bitSize      = 1,
                bitOffset    = 0,
                base         = pr.UInt,
                function     = pr.BaseCommand.createTouch(0x1)
            ))            
            
            self.add(pr.RemoteVariable( 
                name         = "EvrOpCodeMask",
                description  = "Mask off the EVR OP-Code triggering",
                offset       = (regOffset | 0x58),
                bitSize      = 1,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RW",
            )) 

            self.add(pr.RemoteVariable( 
                name         = "EvrSyncSel",
                description  = "0x0 = ASYNC start/stop, 0x1 = SYNC start/stop with respect to evrSyncWord",
                offset       = (regOffset | 0x5C),
                bitSize      = 1,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RW",
            ))  

            self.add(pr.RemoteVariable( 
                name         = "EvrSyncEn",
                description  = "EVR SYNC Enable",
                offset       = (regOffset | 0x60),
                bitSize      = 1,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RW",
            ))   

            self.add(pr.RemoteVariable( 
                name         = "EvrSyncWord",
                description  = "EVR SYNC Word",
                offset       = (regOffset | 0x64),
                bitSize      = 32,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RW",
            )) 
                  
            self.add(pr.RemoteVariable( 
                name         = "EnableTrig",
                description  = "Enable OP-Code Trigger",
                offset       = (regOffset | 0x88),
                bitSize      = 1,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RW",
            ))         
            
            self.add(pr.RemoteVariable( 
                name         = "EvrSyncStatus",
                description  = "EVR SYNC Status",
                offset       = (regOffset | 0x90),
                bitSize      = 1,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RO",
            ))       

            self.add(pr.RemoteVariable( 
                name         = "AcceptCnt",
                description  = "AcceptCnt",
                offset       = (regOffset | 0x94),
                bitSize      = 32,
                bitOffset    = 0,
                base         = pr.UInt,
                mode         = "RO",
            ))               
        
        @self.command(description="Configures the TX for 1.25 Gbps",)
        def CofigTx1p250Gbps():
            print ( 'CofigTx1p250Gbps(): TBD' )                
            
        @self.command(description="Configures the RX for 1.25 Gbps",)
        def ConfigRx1p250Gbps():
            print ( 'ConfigRx1p250Gbps(): TBD' )      

        @self.command(description="Configures the TX for 2.5 Gbps",)
        def CofigTx2p500Gbps():
            print ( 'CofigTx2p500Gbps(): TBD' )              
            
        @self.command(description="Configures the RX for 2.5 Gbps",)
        def CofigRx2p500Gbps():
            print ( 'CofigRx2p500Gbps(): TBD' )      
            
        @self.command(description="Configures the TX for 3.125 Gbps",)
        def CofigTx3p125Gbps():
            print ( 'CofigTx3p125Gbps(): TBD' )          
            
        @self.command(description="Configures the RX for 3.125 Gbps",)
        def CofigRx3p125Gbps():
            print ( 'CofigRx3p125Gbps(): TBD' )
            
        @self.command(description="Configures the TX for 5.0 Gbps",)
        def CofigTx5p000Gbps():
            print ( 'CofigTx5p000Gbps(): TBD' )          
            
        @self.command(description="Configures the RX for 5.0 Gbps",)
        def CofigRx5p000Gbps():
            print ( 'CofigRx5p000Gbps(): TBD' )
            