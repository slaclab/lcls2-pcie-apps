import numpy as np
import matplotlib as plt

my_file = "/u1/sioan/lcls2-pcie-apps/sim_input_data.txt"

n_frames        = 27
pixel_bit_width = 8
n_pixels        = 2048

sigma           = 800.0
jitter          = 100.0

my_file = open(my_file,'w')

to_file = []

for i in range(n_frames):


      edge_position = n_pixels/2+(jitter*np.random.rand()-0.5)
      for j in range(n_pixels):


            my_calculation = 128*np.e**(-(j-n_pixels/2)**2/(2*sigma**2))

            if j > edge_position:
                  my_calculation *= 0.2

            to_file = '{0:08b}'.format(int(my_calculation))

            if(i%12==1):
                  to_file = to_file+" 1"

            else:
                  to_file = to_file+" 0"



            if(j==n_pixels-1):
                  to_file = to_file+"1\n"

            else:
                  to_file = to_file+"0\n"

            

            #print(int(my_calculation))
            #print(to_file)

            my_file.writelines(to_file)

      
