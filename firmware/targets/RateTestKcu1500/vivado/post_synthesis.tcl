##############################################################################
## This file is part of 'ATLAS RD53 DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'ATLAS RD53 DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Bypass the debug chipscope generation
#return

############################
## Open the synthesis design
############################
open_run synth_1

############################
## Get a list of nets
############################
set netFile ${PROJ_DIR}/net_log.txt
set fd [open ${netFile} "w"]
set nl ""

append nl [get_nets {U_Core/U_AxiPcieDma/*}]

regsub -all -line { } $nl "\n" nl
puts $fd $nl
close $fd

###############################
## Set the name of the ILA core
###############################
set ilaName u_ila_1

##################
## Create the core
##################
CreateDebugCore ${ilaName}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 4096 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {dmaClk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/dmaIbMasters[0][tData][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/dmaIbMasters[0][tDest][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/dmaIbMasters[0][tKeep][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/dmaIbMasters[0][tLast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/dmaIbMasters[0][tUser][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/dmaIbMasters[0][tValid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/dmaIbSlaves[0][tReady]}

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/sAxisMasters[0][tData][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/sAxisMasters[0][tDest][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/sAxisMasters[0][tKeep][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/sAxisMasters[0][tLast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/sAxisMasters[0][tUser][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/sAxisMasters[0][tValid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/sAxisSlaves[0][tReady]}

#ConfigProbe ${ilaName} {U_TimeToolCore/r[axilReadSlave][*}
#ConfigProbe ${ilaName} {U_TimeToolCore/axilWriteMaster[*}
#ConfigProbe ${ilaName} {U_TimeToolCore/r[axilWriteSlave][*}

# ConfigProbe ${ilaName} {U_TimeToolCore/r[addValue][*]}
# ConfigProbe ${ilaName} {U_TimeToolCore/r[dialInOpCode][*]}
# ConfigProbe ${ilaName} {U_TimeToolCore/r[dialInTriggerDelay][*]}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName} 

