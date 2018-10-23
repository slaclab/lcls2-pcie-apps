# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadSource -path "$::DIR_PATH/Mig0Empty.vhd"
loadSource -path "$::DIR_PATH/Mig1Empty.vhd"
loadSource -path "$::DIR_PATH/Mig2Empty.vhd"
loadSource -path "$::DIR_PATH/Mig3Empty.vhd"

