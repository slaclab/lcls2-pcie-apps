import numpy as np
import matplotlib.pyplot as plt
import IPython


my_output_file = "/u1/sioan//slaclab/lcls2-pcie-apps/output_results.dat"
my_input_file = "/u1/sioan//slaclab/lcls2-pcie-apps/sim_input_data.dat"


def read_sim_file(my_input_file,ncols,unsigned):

      my_input_data = []
      loaded_input_data = open(my_input_file)
      for i in loaded_input_data:
            #print(i)
            try:
                  if(unsigned):
                        my_input_data.append([int(i[j:j+8],2) for j in range(0,128,8)]) #unsigned reading
                  else:
                        my_input_data.append([((-1)**int(i[j]))*int(i[j+1:j+8],2) for j in range(0,128,8)]) #signed reading
            except:
                  my_input_data.append([0 for i in range(0,128,8)])
                  

      loaded_input_data.close()

      my_input_data = np.array(my_input_data).flatten()

      return my_input_data

my_input_data = read_sim_file(my_input_file,2,True)
my_output_data = read_sim_file(my_output_file,2,False)

plt.figure(0)
plt.plot(my_input_data)

plt.figure(1)
plt.plot(my_output_data)

plt.show()
