# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load ruckus files
loadSource -dir "$::DIR_PATH/core"
loadRuckusTcl "$::DIR_PATH/hardware"
