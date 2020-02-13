import pyrogue as pr

import surf.protocols.batcher

import lcls2_timetool

class AppLane(pr.Device):
    def __init__(self, **kwargs):
        
        super().__init__(**kwargs) 

        self.add(surf.protocols.batcher.AxiStreamBatcherEventBuilder( 
            name         = 'EventBuilder', 
            offset       = 0x00000, 
            numberSlaves = 2,
            tickUnit     = '156.25MHz',            
        ))
        
        self.add(lcls2_timetool.Fex( 
            offset = 0x10000, 
        ))

        self.add(lcls2_timetool.Prescale( 
            offset = 0x20000, 
        ))

