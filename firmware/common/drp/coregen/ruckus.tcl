# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load dcp files
loadSource -path "$::DIR_PATH/AppToMig.dcp"
loadSource -path "$::DIR_PATH/AppIlvToMig.dcp"
loadIpCore -path "$::DIR_PATH/MigToPcie.xci"
loadIpCore -path "$::DIR_PATH/MigIlvToPcie.xci"
loadIpCore -path "$::DIR_PATH/MonToPcie.xci"
loadIpCore -path "$::DIR_PATH/PcieXbar.xci"
#loadIpCore -path "$::DIR_PATH/PcieXbarV2.xci"
loadIpCore -path "$::DIR_PATH/XilinxKcu1500PciePhy_DaqMaster.xci"
loadIpCore -path "$::DIR_PATH/XilinxKcu1500PciePhy_SimCam.xci"
loadIpCore -path "$::DIR_PATH/MigXbar.xci"
#loadIpCore -path "$::DIR_PATH/MigXbarV2.xci"
loadIpCore -path "$::DIR_PATH/MigXbarV3.xci"
loadIpCore -path "$::DIR_PATH/ila_0.xci"
loadIpCore -path "$::DIR_PATH/debug_bridge_0.xci"
loadIpCore -path "$::DIR_PATH/bd_54be_0_bsip_0.xci"
loadIpCore -path "$::DIR_PATH/jtag_bridge.xci"
loadIpCore -path "$::DIR_PATH/bd_6f57_axi_jtag_0.xci"
