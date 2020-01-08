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
return

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

append nl [get_nets {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/*}]

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
SetDebugCoreClk ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/axiClk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/axiCache[*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/axiClk}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/axiWriteSlave[awready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/axiWriteSlave[wready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/dmaWrDescAck[address][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/dmaWrDescAck[buffId][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/dmaWrDescAck[contEn]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/dmaWrDescAck[dropEn]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/dmaWrDescAck[valid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/dmaWrDescRetAck}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[ackCount][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[awlen][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[axiLen][max][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[axiLen][req][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[axiLen][valid][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[continue]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescReq][dest][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescReq][valid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescRet][buffId][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescRet][continue]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescRet][dest][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescRet][firstUser][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescRet][id][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescRet][lastUser][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescRet][result][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescRet][size][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrDescRet][valid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrIdle]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrTrack][address][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrTrack][buffId][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrTrack][contEn]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrTrack][dest][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrTrack][dropEn]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrTrack][firstUser][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrTrack][id][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrTrack][inUse]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrTrack][overflow]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[dmaWrTrack][size][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[lastUser][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[reqCount][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[result][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[slave][tReady]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[stCount][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[state][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awaddr][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awburst][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awcache][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awid][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awlen][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awlock][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awqos][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awregion][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awsize][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][awvalid]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][bready]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][wid][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][wlast]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][wstrb][*]}
ConfigProbe ${ilaName} {U_Core/U_AxiPcieDma/U_V2Gen/U_ChanGen[0].U_DmaWrite/r[wMaster][wvalid]}

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

