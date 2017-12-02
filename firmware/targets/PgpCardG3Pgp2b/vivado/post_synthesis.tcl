##############################################################################
## This file is part of 'DUNE Development Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'DUNE Development Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Bypass the debug chipscope generation
return

############################
## Open the synthesis design
############################
open_run synth_1

###############################
## Set the name of the ILA core
###############################
set ilaName u_ila_0

##################
## Create the core
##################
CreateDebugCore ${ilaName}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/axilClk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/drpGnt}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/drpOverride}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/drpRdy}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/gtRxUserReset}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/pgpRxReset}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/pgpTxReset}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/SOFT_RESET_RX_IN}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/DONT_RESET_ON_DATA_ERROR_IN}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/GT0_DATA_VALID_IN}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/GT0_DRP_BUSY_OUT}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/GT0_RX_FSM_RESET_DONE_OUT}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/gt0_rxbufreset_in}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/gt0_rxlpmreset_in}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/gt0_rxpcsreset_in}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/gt0_rxpmareset_in}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/gt0_rxresetdone_out}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/gt0_rxuserrdy_in}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/SOFT_RESET_RX_IN}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/GT0_TX_FSM_RESET_DONE_OUT}
ConfigProbe ${ilaName} {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/gt0_txresetdone_out}


##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName} ${PROJ_DIR}/images/debug_probes_${PRJ_VERSION}.ltx
