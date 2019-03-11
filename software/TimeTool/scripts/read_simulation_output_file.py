import numpy as np
import matplotlib.pyplot as plt


my_output_file = "/u1/sioan/build/TimeToolKcu1500/TimeToolKcu1500_project.sim/sim_1/behav/xsim/output_results.txt"
my_input_file = "/u1/sioan/build/TimeToolKcu1500/TimeToolKcu1500_project.sim/sim_1/behav/xsim/sim_input_data.txt"


for i in range(10000): 
      try: 
            loaded_output_data = np.loadtxt(my_output_file,skiprows=i)
            break 
      except: 
            pass 

loaded_input_data  = np.loadtxt(my_input_file,skiprows=1,delimiter =' ')

my_output_data = np.array([int(i[:-2],2) for i in loaded_output_data.astype(str)])
my_input_data = np.array([int(i[:-2],2) for i in loaded_input_data[:,0].astype(str)])

plt.figure(0)
plt.plot(my_input_data)

plt.figure(1)
plt.plot(my_output_data)

plt.show()
