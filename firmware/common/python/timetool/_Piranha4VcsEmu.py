import rogue

# This class emulates the Piranha4 Test Pattern
class Piranha4VcsEmu(rogue.interfaces.stream.Master):
    # Init method must call the parent class init
    def __init__(self, host, port):
        super().__init__()
        self._maxSize = 2048
        self._basicFrame = bytearray((i%256 for i in range(self._maxSize)))

        self.count = 0

    def trigCb(self, opCode, remData):
        if opCode == 0:
            self._basicFrame[0] = self.count%256
            self.count += 1
            frame = self._reqFrame(self._maxSize, True)
            frame.write(self._basicFrame, 0)
            self._sendFrame(frame)

