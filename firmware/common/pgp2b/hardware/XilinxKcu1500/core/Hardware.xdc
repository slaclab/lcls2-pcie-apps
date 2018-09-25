##############################################################################
## This file is part of 'SLAC PGP Gen3 Card'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'SLAC PGP Gen3 Card', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

#######
# PGP #
#######

create_clock -name pgpRxClk0 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk1 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk2 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk3 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk4 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[4].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgpRxClk5 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[5].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]

create_clock -name pgpTxClk0 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk1 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk2 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk3 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk4 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[4].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgpTxClk5 -period 4.000 [get_pins {U_App/U_Pgp/GEN_LANE[5].U_Lane/U_Pgp/PgpGthCoreWrapper_1/U_PgpGthCore/inst/gen_gtwizard_gthe3_top.PgpGthCore_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]

#######
# EVR #
#######

set_case_analysis 1 [get_pins {U_App/U_Evr/U_RXCLK/S}]
set_case_analysis 1 [get_pins {U_App/U_Evr/U_TXCLK/S}]

create_clock -name evrRxClk0 -period 5.384 [get_pins {U_App/U_Evr/GEN_VEC[0].U_GTP/LOCREF_G.U_TimingGthCore/inst/gen_gtwizard_gthe3_top.TimingGth_fixedlat_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[0].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name evrTxClk0 -period 5.384 [get_pins {U_App/U_Evr/GEN_VEC[0].U_GTP/LOCREF_G.U_TimingGthCore/inst/gen_gtwizard_gthe3_top.TimingGth_fixedlat_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[0].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]

create_clock -name evrRxClk1 -period 5.384 [get_pins {U_App/U_Evr/GEN_VEC[1].U_GTP/LOCREF_G.U_TimingGthCore/inst/gen_gtwizard_gthe3_top.TimingGth_fixedlat_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[0].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name evrTxClk1 -period 5.384 [get_pins {U_App/U_Evr/GEN_VEC[1].U_GTP/LOCREF_G.U_TimingGthCore/inst/gen_gtwizard_gthe3_top.TimingGth_fixedlat_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[0].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]

create_generated_clock -name evrRefMon0  [get_pins {U_App/U_Evr/GEN_VEC[0].U_GTP/LOCREF_G.TIMING_TXCLK_BUFG_GT/O}]
create_generated_clock -name evrRefMon1  [get_pins {U_App/U_Evr/GEN_VEC[1].U_GTP/LOCREF_G.TIMING_TXCLK_BUFG_GT/O}]

######################
# Timing Constraints #
######################

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pciRefClkP}] -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pciRefClkP}] -group [get_clocks -include_generated_clocks {qsfp0RefClkP1}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pciRefClkP}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pciRefClkP}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP1}]

set_clock_groups -asynchronous -group [get_clocks {evrTxClk0}] -group [get_clocks {evrRxClk0}] -group [get_clocks -include_generated_clocks {pciRefClkP}]
set_clock_groups -asynchronous -group [get_clocks {evrTxClk1}] -group [get_clocks {evrRxClk1}] -group [get_clocks -include_generated_clocks {pciRefClkP}]

set_clock_groups -asynchronous -group [get_clocks {pgpTxClk0}] -group [get_clocks {pgpRxClk0}] -group [get_clocks {drpClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk1}] -group [get_clocks {pgpRxClk1}] -group [get_clocks {drpClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk2}] -group [get_clocks {pgpRxClk2}] -group [get_clocks {drpClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk3}] -group [get_clocks {pgpRxClk3}] -group [get_clocks {drpClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk4}] -group [get_clocks {pgpRxClk4}] -group [get_clocks {drpClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk5}] -group [get_clocks {pgpRxClk5}] -group [get_clocks {drpClk}]

set_clock_groups -asynchronous -group [get_clocks {pgpTxClk0}] -group [get_clocks {pgpRxClk0}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk1}] -group [get_clocks {pgpRxClk1}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk2}] -group [get_clocks {pgpRxClk2}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk3}] -group [get_clocks {pgpRxClk3}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk4}] -group [get_clocks {pgpRxClk4}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk5}] -group [get_clocks {pgpRxClk5}] -group [get_clocks {sysClk}]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {userClkP0}] -group [get_clocks {sysClk}] -group [get_clocks {drpClk}]  
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {userClkP1}] -group [get_clocks {sysClk}] -group [get_clocks {drpClk}]  
set_clock_groups -asynchronous -group [get_clocks {evrRefMon0}] -group [get_clocks {evrRefMon1}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {evrRefMon0}] -group [get_clocks {evrRefMon1}] -group [get_clocks {drpClk}]
set_clock_groups -asynchronous -group [get_clocks evrRxClk0] -group [get_clocks evrRxClk1]
