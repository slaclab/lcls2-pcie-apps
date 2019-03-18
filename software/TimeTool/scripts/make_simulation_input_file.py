import numpy as np
import matplotlib.pyplot as plt

my_file = "/u1/sioan/lcls2-pcie-apps/sim_input_data.dat"

n_frames                = 27
bits_per_pixel          = 8
pixels_per_transfer     = 16
pixels_per_frame        = 2048      #frame and packet are being used interchangeably

sigma                   = 800.0
jitter                  = 100.0
amplitude               = 64

my_file = open(my_file,'w')

to_file = []

#each line break will imply a tvalid. no special marker

def gaussian(x,u,s):
      return np.e**(-(x-u)**2/(2*s**2))

for i in range(n_frames):

      x = np.arange(pixels_per_frame)
      my_frame_array = amplitude*gaussian(x,pixels_per_frame/2.0,sigma)
      edge_position = int(pixels_per_frame/2+(jitter*np.random.rand()-0.5))
      my_frame_array[edge_position:] = my_frame_array[edge_position:] *0.2

      my_frame_list = []
      for j in range(0,pixels_per_frame,pixels_per_transfer):
            my_transfer_string = ""
            for k in range(pixels_per_transfer): my_transfer_string += '{0:08b}'.format(int(my_frame_array[j+k]))
            #print(j)
            if(j<(pixels_per_frame-pixels_per_transfer-1)):
                  my_transfer_string += " 0\n"            
                  my_file.writelines(my_transfer_string)
            else:
                  print(j)
                  my_transfer_string += " 1\n"            
                  my_file.writelines(my_transfer_string)


            #my_frame_list.append(my_transfer_string)            
      
            

      
