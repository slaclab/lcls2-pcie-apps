# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load base sub-modules
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/lcls-timing-core
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/axi-pcie-core/hardware/XilinxKcu1500
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/lcls2-pgp-fw-lib/hardware/XilinxKcu1500
loadRuckusTcl $::env(PROJ_DIR)/../../common

# Load the l2si-core source code
loadSource -lib l2si_core -dir "$::env(PROJ_DIR)/../../submodules/l2si-core/xpm/rtl"
loadSource -lib l2si_core -dir "$::env(PROJ_DIR)/../../submodules/l2si-core/base/rtl"

# Load local source Code and constraints
loadSource -lib timetool -dir "$::DIR_PATH/hdl"

# Load Simulation
loadSource -lib timetool -sim_only -dir "$::DIR_PATH/tb"
set_property top {TimeToolKcu1500VcsTb} [get_filesets sim_1]

# Updating impl_1 strategy
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
