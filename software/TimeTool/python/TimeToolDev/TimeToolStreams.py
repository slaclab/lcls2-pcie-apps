#!/usr/bin/env python3
import pyrogue as pr

import rogue.interfaces.stream

import numpy as np

import IPython
# import h5py

#####################################################################        
#####################################################################        
##################################################################### 

# This class emulates the Piranha4 Test Pattern
class TimeToolTxEmulation(rogue.interfaces.stream.Master):

    # Init method must call the parent class init
    def __init__(self):
        super().__init__()
        self._maxSize = 2048

    # Method for generating a frame
    def myFrameGen(self,*args):
        # First request an empty from from the primary slave
        # The first arg is the size, the second arg is a boolean
        # indicating if we can allow zero copy buffers, usually set to true
        frame = self._reqFrame(self._maxSize, True) # Here we request a frame capable of holding 2048 bytes

        # Create a 2048 byte array with an incrementing value
        #ba = bytearray([(i&0xFF) for i in range(self._maxSize)])
        #IPython.embed()
        if(0==len(args)):
              ba = self.make_byte_array()
        else:
              ba=args[0]
        #print(self.make_byte_array())

        # Write the data to the frame at offset 0
        frame.write(ba,0)
        
        # Send the frame to the currently attached slaves
        self._sendFrame(frame)

    def make_byte_array(self):
        return bytearray([(i&0xFF) for i in range(self._maxSize)])

#####################################################################        
#####################################################################        
#####################################################################        
        
#One of the goals this code satisfies is to to facilitate communication between registers in Xilinx's kcu1500 FPGA and a host linux machine.
#See comment in TimeTool.py for how to make rogue aware of a FPGA register to communicate with.
class TimeToolRx(pr.Device,rogue.interfaces.stream.Slave):

    def __init__(self, name='TimeToolRx', **kwargs):
        print("Initializing TimeToolRx")
        rogue.interfaces.stream.Slave.__init__(self)
        pr.Device.__init__(self,name=name,**kwargs)

        self.add(pr.LocalVariable(
            name        = 'frameCount',   
            value       = 0, 
            mode        = 'RO', 
            pollInterval= 1,
        ))
        
        self.add(pr.LocalVariable(
            name        = 'lengthErrors', 
            value       = 0, 
            mode        = 'RO', 
            pollInterval= 1,
        ))
        
        self.add(pr.LocalVariable( 
            name        = 'dataErrors',   
            value       = 0, 
            mode        = 'RO', 
            pollInterval= 1,
        ))
        
        self.add(pr.LocalVariable( 
            name        = 'frameLength',   
            description = 'frameLength = 2052 # sn : medium mode, 8 bit, frameLength = 4100 # sn : medium mode, 12 bit',
            value       = 2052, 
            mode        = 'RW', 
        )) 

        self.to_save_to_h5 = []

        for i in range(8):
            self.add(pr.LocalVariable( name='byteError{}'.format(i), disp='{:#x}', value=0, mode='RO', pollInterval=1))

    def _acceptFrame(self,frame):
        print("TimeToolRx accepting frame ")
        p = bytearray(frame.getPayload())
        frame.read(p,0)
        print(len(p))
        my_mask = np.arange(36)
        if(len(p)>100):
              my_mask = np.append(my_mask,np.arange(int(len(p)/2),int(len(p)/2)+36))
              my_mask = np.append(my_mask,np.arange(len(p)-36,len(p)))

        to_print = np.array(p)[-1:] 
        #print(np.array(p)[:96],to_print) #comment out for long term test
        print(np.array(p)[my_mask])
        print("____________________________________________________")
        self.frameCount.set(self.frameCount.value() + 1,False)

     
        berr = [0,0,0,0,0,0,0,0]
        frameLength = self.frameLength.get()
        if len(p) != frameLength:
            #print('length:',len(p))
            self.lengthErrors.set(self.lengthErrors.value() + 1,False)
        else:
            for i in range(frameLength-4):
                exp = i & 0xFF
                if p[i] != exp:
                    #print("Error at pos {}. Got={:2x}, Exp={:2x}".format(i,p[i],exp))
                    d = p[i] ^ exp
                    c = i % 8
                    berr[c] = berr[c] | d
                    self.dataErrors.set(self.dataErrors.value() + 1,False)
        #print(len(p))
        # to_print = np.array(p)[-16:]
        # print(np.array(p)[:24],to_print) #comment out for long term test
        #self.to_save_to_h5.append(np.array(p))
        for i in range(8):
            self.node('byteError{}'.format(i)).set(berr[i],False)

    def close_h5_file(self):
        print("the thing that is not a destructor is working")
        self.my_h5_file['my_data'] = self.to_save_to_h5
        self.my_h5_file.close()
        print(self.to_save_to_h5)
        
    def countReset(self):
        self.frameCount.set(0,False)
        self.lengthErrors.set(0,False)
        self.dataErrors.set(0,False)
        
#####################################################################        
#####################################################################        
#####################################################################         

# sub-classing the TimeToolRx class
class TimeToolRxVcs(TimeToolRx):

    def __init__(self, name='TimeToolRx', **kwargs):
        print("Initializing TimeToolRxVcs")
        super().__init__(name=name,**kwargs)
       

    def _acceptFrame(self,frame):
        print("TimeToolRxVcs accepting frame ")
        p = bytearray(frame.getPayload())
        frame.read(p,0)
        self.unparsed_data = p
        print(len(p))
        my_mask = np.arange(36)
        if(len(p)>100):
              my_mask = np.append(my_mask,np.arange(int(len(p)/2),int(len(p)/2)+36))
              my_mask = np.append(my_mask,np.arange(len(p)-36,len(p)))

        to_print = np.array(p)[-1:] 
        #print(np.array(p)[:96],to_print) #comment out for long term test
        #print(np.array(p)[my_mask])
        self.parsed_data = np.array(p)[my_mask]
        print("____________________________________________________")
        self.frameCount.set(self.frameCount.value() + 1,False)
     
        '''berr = [0,0,0,0,0,0,0,0]
        #frameLength = 4100 # sn : medium mode, 12 bit
        frameLength = 2052 # sn : medium mode, 8 bit
        #if len(p) != 2048: 
        if len(p) != frameLength:
            #print('length:',len(p))
            self.lengthErrors.set(self.lengthErrors.value() + 1,False)
        else:
            for i in range(frameLength-4):
                exp = i & 0xFF
                if p[i] != exp:
                    #print("Error at pos {}. Got={:2x}, Exp={:2x}".format(i,p[i],exp))
                    d = p[i] ^ exp
                    c = i % 8
                    berr[c] = berr[c] | d
                    self.dataErrors.set(self.dataErrors.value() + 1,False)
        #print(len(p))
        to_print = np.array(p)[-16:]
        print(np.array(p)[:24],to_print) #comment out for long term test
        #self.to_save_to_h5.append(np.array(p))
        for i in range(8):
            self.node('byteError{}'.format(i)).set(berr[i],False)'''
        
#####################################################################        
#####################################################################        
#####################################################################          
        
