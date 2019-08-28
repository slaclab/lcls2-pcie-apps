import numpy as np

class eventBuilderParser():
    def __init__(self):
        self.parsed_data  = []

        return

    def frames_to_position(self,frame_bytearray,position):
        return int('0b'+'{0:08b}'.format(frame_bytearray[position+1])+'{0:08b}'.format(frame_bytearray[position]),2)
    
    def calibrate():

        return

    def parseArray(self,frame_bytearray:bytearray):
        self.frame_bytes     = len(frame_bytearray)
        self.main_header     = frame_bytearray[0:16]
        self.timing_bus      = frame_bytearray[16:32]
        self.fex_header      = frame_bytearray[80:96] #only when batcher isn't in bypass mode. should be dynamically determined
        self.edge_position   = self.frames_to_position(frame_bytearray[96:98],0)
        #fex_


        self.version                = self.main_header[0] & int('00001111', 2)
        self.axi_stream_width       = self.main_header[0] >> 4
        #self.sequence               = main_header

        self.frame_sizes_reversed         = [self.frames_to_position(frame_bytearray,-16)]
        self.frame_positions_reversed     = [[self.frame_bytes-16-self.frame_sizes_reversed[0],self.frame_bytes-16]] #[start, and]

        self.frame_sizes_reversed.append(self.frames_to_position(frame_bytearray,self.frame_positions_reversed[-1][0]-16))
        self.frame_positions_reversed.append([self.frame_positions_reversed[-1][0]-16-self.frame_sizes_reversed[-1],self.frame_positions_reversed[-1][0]-16]) #[start, and]
        
        self.frame_sizes_reversed.append(self.frames_to_position(frame_bytearray,self.frame_positions_reversed[-1][0]-16))
        self.frame_positions_reversed.append([self.frame_positions_reversed[-1][0]-16-self.frame_sizes_reversed[-1],self.frame_positions_reversed[-1][0]-16]) #[start, and]

        
        #self.frame_reversed = frame_bytearray[-self.frame_sizes_reversed[0]-16:-16]
