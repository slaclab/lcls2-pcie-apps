# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/lcls-timing-core
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/l2si-core/xpm
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/l2si-core/base
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/axi-pcie-core/hardware/XilinxKcu1500
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/lcls2-pgp-fw-lib/pgp2b-only/hardware/XilinxKcu1500
loadRuckusTcl $::env(PROJ_DIR)/../../applications
#loadRuckusTcl $::env(PROJ_DIR)/../../submodules/l2si-core/xpm
#loadRuckusTcl $::env(PROJ_DIR)/../../submodules/l2si-core/base

# Load local source Code and constraints
loadSource -dir "$::DIR_PATH/hdl"

# Load Simulation
loadSource -sim_only -dir "$::DIR_PATH/tb"
