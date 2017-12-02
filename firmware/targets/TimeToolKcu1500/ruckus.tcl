# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/axi-pcie-core
loadRuckusTcl $::env(PROJ_DIR)/../../common

# Load local source Code and constraints
loadSource -dir "$::DIR_PATH/hdl"

# Check for partial reconfiguration
if { [info exists ::env(BYPASS_RECONFIG)] != 1 || $::env(BYPASS_RECONFIG) == 0 } {
   # Check if the partial reconfiguration not applied yet
   if { [get_property PR_FLOW [current_project]] != 1 } {

      # Configure for partial reconfiguration
      set_property PR_FLOW 1 [current_project]

      #######################################################################################
      # Define the partial reconfiguration partitions
      # Note: TCL commands below were copied from GUI mode's TCL console 
      #      Refer to UG947 in section "Lab 2: UltraScale Basic Partial Reconfiguration Flow"
      #######################################################################################
      create_partition_def -name APP -module Application
      create_reconfig_module -name Application -partition_def [get_partition_defs APP ]  -define_from Application
      create_pr_configuration -name config_1 -partitions [list U_App:Application ]
      set_property PR_CONFIGURATION config_1 [get_runs impl_1]
   }
}
