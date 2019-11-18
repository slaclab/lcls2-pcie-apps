import pyrogue as pr

class TimeToolKcu1500(pr.Device):
    def __init__(self, numLanes=1, pgp3=False, **kwargs):
        super().__init__(**kwargs)

        self.add(pcie.AxiPcieCore(
            offset      = 0x00000000,
            numDmaLanes = numLanes,
            expand      = False,
        ))  
        
            
        # PGP Hardware on PCIe 
        self.add(lcls2_pgp_fw_lib.hardware.XilinxKcu1500.Kcu1500Hsio(            
            offset    = 0x0080_0000
            numLanes  = numLanes,
            pgp3      = pgp3,
            expand    = False,
        ))

        # The time tool application
        self.add(timetool.Application(
            offset = 0x008C_0000,
            numLanes = numLanes))
