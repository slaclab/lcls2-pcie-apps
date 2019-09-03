import numpy as np

class eventBuilderParser():
    def __init__(self):        
        return

    def frames_to_position(self,frame_bytearray,position):
        return int('0b'+'{0:08b}'.format(frame_bytearray[position+1])+'{0:08b}'.format(frame_bytearray[position]),2)
    
    def _checkForSubframes(self):
        self.sub_is_fullframe = [False]*len(self.frame_list)
        
        for i in range(len(self.frame_list)):
            
            if self.main_header[:2] == self.frame_list[i][:self.HEADER_WIDTH ][:2]:
                self.sub_is_fullframe[i] = True
        
        return
    
    def _resolveSubFrames(self):
        self._checkForSubframes()
        self.sub_frames = [False]*len(self.frame_list)
        for i in range(len(self.frame_list)):
            if self.sub_is_fullframe[i]:
                self.sub_frames[i] =  eventBuilderParser()
                #print("length = ",len(self.frame_list[i]))
                self.sub_frames[i].parseArray(self.frame_list[i])
                self.frame_list[i] = False
        return
    
    def print_info(self):
        for i in self.__dict__:
            if i != "frame_list":
                print(i," = ",self.__dict__[i])
                
        for i in range(len(self.sub_is_fullframe)):
            if(self.sub_is_fullframe[i]):
                print("\nsubframe = ",i)
                self.sub_frames[i].print_info()
                
        return
        
    def parseArray(self,frame_bytearray:bytearray):
        self.frame_bytes     = len(frame_bytearray)
        self.main_header     = frame_bytearray[0:16]

        self.version                = self.main_header[0] & int('00001111', 2)
        self.axi_stream_bit_width   = 8*2**((self.main_header[0] >> 4) + 1)
        self.HEADER_WIDTH           = int(self.axi_stream_bit_width/8)
        
        
        self.frame_sizes_reversed         = [self.frames_to_position(frame_bytearray,-16)]
        self.frame_positions_reversed     = [[self.frame_bytes-16-self.frame_sizes_reversed[0],self.frame_bytes-16]] #[start, and]
        self.frame_list                   = [frame_bytearray[self.frame_positions_reversed[-1][0]:self.frame_positions_reversed[-1][1]]]
        
        self.tdest                        = [frame_bytearray[-12]]
        
        
        parsed_frame_size = sum(self.frame_sizes_reversed) +(len(self.frame_sizes_reversed)+1)*self.HEADER_WIDTH
        #print("parsing")
        while(len(frame_bytearray)>parsed_frame_size):
            #print(len(frame_bytearray))
            self.frame_sizes_reversed.append(self.frames_to_position(frame_bytearray,self.frame_positions_reversed[-1][0]-16))
            
            self.frame_positions_reversed.append([self.frame_positions_reversed[-1][0]-16-self.frame_sizes_reversed[-1],self.frame_positions_reversed[-1][0]-16]) #[start, and]            
            
            self.frame_list.append(frame_bytearray[self.frame_positions_reversed[-1][0]:self.frame_positions_reversed[-1][1]])
            self.tdest.append(frame_bytearray[self.frame_positions_reversed[-1][1]+4])
            
            
          
            parsed_frame_size = sum(self.frame_sizes_reversed) +(len(self.frame_sizes_reversed)+1)*self.HEADER_WIDTH
        
        #self.sub_is_fullframe = [False]*len(self.frame_list)
        self._resolveSubFrames()
        
        return
    
class timeToolParser(eventBuilderParser):
    def parseData(self,frame_bytearray:bytearray):
        self.parseArray(frame_bytearray)
        
        self.timing_bus      = frame_bytearray[16:32]
        
        #self.fex_header      = frame_bytearray[80:96] #only when batcher isn't in bypass mode. should be dynamically determined
        #self.edge_position   = self.frames_to_position(frame_bytearray[96:98],0)
        
        #print(len(self.sub_is_fullframe))
        #print(len(self.sub_frames))
        
        for i in range(len(self.sub_is_fullframe)):
            
            if(self.sub_is_fullframe[i]):
                #self.edge_position   = self.sub_frames[i].frame_list[1][0]+ self.sub_frames[i].frame_list[1][1]*256
                for j in range(len(self.sub_frames[i].frame_list)):
                    if len(self.sub_frames[i].frame_list[j]) == 16:
                        self.edge_position   = self.sub_frames[i].frame_list[j][0]+ self.sub_frames[i].frame_list[j][1]*256


        
        
    
        return
