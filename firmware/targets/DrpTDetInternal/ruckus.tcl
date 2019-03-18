# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-pcie-core/hardware/XilinxKcu1500
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-pcie-core/hardware/XilinxKcu1500/ddr
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-pcie-core/hardware/XilinxKcu1500/pcie-extended
loadRuckusTcl $::env(TOP_DIR)/submodules/lcls-timing-core
loadRuckusTcl $::env(TOP_DIR)/submodules/l2si-core/base
loadRuckusTcl $::env(TOP_DIR)/submodules/l2si-core/xpm

loadRuckusTcl $::env(TOP_DIR)/common/drp
loadRuckusTcl $::env(TOP_DIR)/common/drp/coregen

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl"
loadConstraints -dir "$::DIR_PATH/hdl"
