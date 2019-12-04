#-----------------------------------------------------------
# once the nogui phony target is made, this script can be run from the build directory using the command below
# vivado -mode batch -source $(path_to_this_file)/simulation.tcl
#-----------------------------------------------------------

open_project TimeToolKcu1500_project.xpr
set_property top TBPrescaledIIRSubtraction [get_filesets sim_1]
update_ip_catalog
update_compile_order -fileset sim_1
launch_simulation
run 100 us
#start_gui
#update_compile_order -fileset sources_1
#relaunch_sim
#restart
#run 100 us
