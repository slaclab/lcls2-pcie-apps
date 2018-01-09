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

create_clock -name pgp3PhyRxClk0 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgp3PhyRxClk1 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgp3PhyRxClk2 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgp3PhyRxClk3 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgp3PhyRxClk4 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[4].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgp3PhyRxClk5 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[5].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgp3PhyRxClk6 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[6].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]
create_clock -name pgp3PhyRxClk7 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[7].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]

create_clock -name pgp3PhyTxClk0 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgp3PhyTxClk1 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgp3PhyTxClk2 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgp3PhyTxClk3 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgp3PhyTxClk4 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[4].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgp3PhyTxClk5 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[5].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgp3PhyTxClk6 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[6].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]
create_clock -name pgp3PhyTxClk7 -period 3.200 [get_pins {U_App/U_Pgp/GEN_LANE[7].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/U_Pgp3GthUsIp_1/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[2].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/TXOUTCLK}]

######################
# Timing Constraints #
######################

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pgp3PhyRxClk0}] -group [get_clocks -include_generated_clocks {pgp3PhyTxClk0}] -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}] -group [get_clocks -include_generated_clocks {pciRefClkP}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pgp3PhyRxClk1}] -group [get_clocks -include_generated_clocks {pgp3PhyTxClk1}] -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}] -group [get_clocks -include_generated_clocks {pciRefClkP}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pgp3PhyRxClk2}] -group [get_clocks -include_generated_clocks {pgp3PhyTxClk2}] -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}] -group [get_clocks -include_generated_clocks {pciRefClkP}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pgp3PhyRxClk3}] -group [get_clocks -include_generated_clocks {pgp3PhyTxClk3}] -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}] -group [get_clocks -include_generated_clocks {pciRefClkP}]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pgp3PhyRxClk4}] -group [get_clocks -include_generated_clocks {pgp3PhyTxClk4}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}] -group [get_clocks -include_generated_clocks {pciRefClkP}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pgp3PhyRxClk5}] -group [get_clocks -include_generated_clocks {pgp3PhyTxClk5}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}] -group [get_clocks -include_generated_clocks {pciRefClkP}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pgp3PhyRxClk6}] -group [get_clocks -include_generated_clocks {pgp3PhyTxClk6}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}] -group [get_clocks -include_generated_clocks {pciRefClkP}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {pgp3PhyRxClk7}] -group [get_clocks -include_generated_clocks {pgp3PhyTxClk7}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}] -group [get_clocks -include_generated_clocks {pciRefClkP}]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]] -group [get_clocks -of_objects [get_pins U_Core/U_REG/U_Version/GEN_DEVICE_DNA.DeviceDna_1/GEN_ULTRA_SCALE.DeviceDnaUltraScale_Inst/BUFGCE_DIV_Inst/O]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]] -group [get_clocks -of_objects [get_pins U_axilClk/O]]
