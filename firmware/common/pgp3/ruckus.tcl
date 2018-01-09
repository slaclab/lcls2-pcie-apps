# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and Constraints
loadRuckusTcl "$::DIR_PATH/hardware"
loadSource -dir "$::DIR_PATH/core"
