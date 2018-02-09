# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadSource      -dir  "$::DIR_PATH/pgp2b"
loadConstraints -dir  "$::DIR_PATH/pgp2b"
loadIpCore      -path "$::DIR_PATH/pgp2b/Pgp2bGtp7Drp.xci"

loadSource      -dir "$::DIR_PATH/core"
loadConstraints -dir "$::DIR_PATH/core"

loadSource      -dir  "$::DIR_PATH/evr"
loadConstraints -dir  "$::DIR_PATH/evr"
