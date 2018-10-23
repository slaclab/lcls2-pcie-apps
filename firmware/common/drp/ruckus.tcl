# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
loadSource -dir "$::DIR_PATH/rtl"
loadRuckusTcl "$::DIR_PATH/mig"
#loadRuckusTcl "$::DIR_PATH/pciex"
loadRuckusTcl "$::DIR_PATH/coregen"
loadRuckusTcl "$::DIR_PATH/xdc"

