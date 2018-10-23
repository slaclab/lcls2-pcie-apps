# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadSource -path "$::DIR_PATH/Mig0.vhd"
loadSource -path "$::DIR_PATH/Mig1.vhd"
loadSource -path "$::DIR_PATH/Mig0D.vhd"
loadSource -path "$::DIR_PATH/Mig1D.vhd"
#loadSource -path "$::DIR_PATH/Mig2.vhd"
#loadSource -path "$::DIR_PATH/Mig3.vhd"
loadSource -path "$::DIR_PATH/MigA.vhd"
loadSource -path "$::DIR_PATH/MigB.vhd"

# Load xci files
loadIpCore -path "$::DIR_PATH/XilinxKcu1500Mig0Core.xci"
loadIpCore -path "$::DIR_PATH/XilinxKcu1500Mig1Core.xci"
#loadIpCore -path "$::DIR_PATH/XilinxKcu1500Mig2Core.xci"
#loadIpCore -path "$::DIR_PATH/XilinxKcu1500Mig3Core.xci"

# Load dcp files
#loadSource -path "$::DIR_PATH/XilinxKcu1500Mig0Core.dcp"
#loadSource -path "$::DIR_PATH/XilinxKcu1500Mig1Core.dcp"
#loadSource -path "$::DIR_PATH/XilinxKcu1500Mig2Core.dcp"
#loadSource -path "$::DIR_PATH/XilinxKcu1500Mig3Core.dcp"

loadConstraints -path "$::DIR_PATH/XilinxKcu1500Mig0.xdc"
loadConstraints -path "$::DIR_PATH/XilinxKcu1500Mig1.xdc"
#loadConstraints -path "$::DIR_PATH/XilinxKcu1500Mig2.xdc"
#loadConstraints -path "$::DIR_PATH/XilinxKcu1500Mig3.xdc"

