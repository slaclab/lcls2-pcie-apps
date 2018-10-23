# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load dcp files
#loadSource -path "$::DIR_PATH/XilinxKcu1500PciePhy_DaqSlave.dcp"
loadIpCore -path "$::DIR_PATH/XilinxKcu1500PciePhy_DaqSlave.xci"

loadConstraints -dir "$::DIR_PATH"
