# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and Constraints
loadSource      -dir "$::DIR_PATH/rtl"
loadConstraints -dir "$::DIR_PATH/rtl"

loadSource -path "$::DIR_PATH/../XilinxKcu1500/pgp2b/PgpLane.vhd"
loadSource -path "$::DIR_PATH/../XilinxKcu1500/pgp2b/PgpLaneTx.vhd"
