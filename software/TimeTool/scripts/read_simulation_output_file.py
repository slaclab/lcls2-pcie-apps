import numpy as np
import matplotlib.pyplot as plt


my_output_file = "/u1/sioan/lcls2-pcie-apps/output_results.dat"
my_input_file = "/u1/sioan/lcls2-pcie-apps/sim_input_data.dat"


for i in range(10000): 
      try: 
            loaded_output_data = np.loadtxt(my_output_file,skiprows=i)
            my_output_data = np.array([int(i[:-2],2) for i in loaded_output_data.astype(str)])

            break 
      except: 
            pass 


my_input_data = []
loaded_input_data = open(my_input_file)
for i in loaded_input_data:
      #print(i)
      my_input_data.append([int(i[j:j+8],2) for j in range(0,128,8)]) 

loaded_input_data.close()

my_input_data = np.array(my_input_data).flatten()

#loaded_input_data  = np.loadtxt(my_input_file,skiprows=1,delimiter =' ')
#my_input_data = np.array([int(i[:-2],2) for i in loaded_input_data[:,0].astype(str)])

plt.figure(0)
plt.plot(my_input_data)

#plt.figure(1)
#plt.plot(my_output_data)

plt.show()
