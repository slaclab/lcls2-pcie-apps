import pyrogue as pr

import time

class RunControl(pr.RunControl):
    def __init__(self, **kwargs):
        super().__init__(rates = {0: 'Auto'}, **kwargs)


    def __startRun(self):
        print('Starting TimeTool Run')

        print('Reading current State')
        self.root.ReadAll()

        eventBuilder = self.root.TimeToolKcu1500.Application.AppLane[0].EventBuilder
        trigger = self.root.TimeToolKcu1500.Kcu1500Hsio.TimingRx.TriggerEventManager.TriggerEventBuffer[0]

        print('Blowing off stale pipeline data')
        eventBuilder.Blowoff.set(True)
        time.sleep(1.0)        
        eventBuilder.Blowoff.set(False)

        # Reset counters
        print('Resetting Counters')
        trigger.ResetCounters()
        self.root.CountReset()

        # Enable triggers
        print('Enabling Triggers')
        trigger.EventBufferEnable.set(True)
        trigger.MasterEnable.set(True)

    def __endRun(self):
        print('Stopping TimeTool Run')
        
        eventBuilder = self.root.TimeToolKcu1500.Application.AppLane[0].EventBuilder
        trigger = self.root.TimeToolKcu1500.Kcu1500Hsio.TimingRx.TriggerEventManager.TriggerEventBuffer[0]

        trigger.MasterEnable.set(False)
        trigger.EventBufferEnable.set(False)

        
        
    def _run(self):
        
        self.__startRun()

        while self.runState.valueDisp() == 'Running':
            self.root.DataWriter.getChannel(1).waitFrameCount(self.runCount.value()+1, 1000000000)
            self.runCount.set(self.root.DataWriter.getChannel(1).getFrameCount())

        self.__endRun()
