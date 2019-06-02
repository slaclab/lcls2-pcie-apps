set_property -dict {PACKAGE_PIN AP24 IOSTANDARD LVCMOS18} [get_ports sda]
set_property -dict {PACKAGE_PIN AN24 IOSTANDARD LVCMOS18} [get_ports scl]
set_property -dict {PACKAGE_PIN AL24 IOSTANDARD LVCMOS18} [get_ports i2c_rst_l]

create_clock -period 3.332 -name ddrClkP0 [get_ports {ddrClkP[0]}]
#create_clock -period 3.332 -name ddrClkP1 [get_ports {ddrClkP[1]}]

#
#  *RefClkP[0] are programmable: set to 185.7 MHz
#
create_clock -period 5.380 -name qsfp0RefClkP0 [get_ports {qsfp0RefClkP[0]}]
create_clock -period 6.400 -name qsfp0RefClkP1 [get_ports {qsfp0RefClkP[1]}]
create_clock -period 5.380 -name qsfp1RefClkP0 [get_ports {qsfp1RefClkP[0]}]
create_clock -period 6.400 -name qsfp1RefClkP1 [get_ports {qsfp1RefClkP[1]}]

set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks ddrClkP0] \
                 -group [get_clocks -include_generated_clocks qsfp0RefClkP0] \
                 -group [get_clocks -include_generated_clocks qsfp0RefClkP1] \
                 -group [get_clocks -include_generated_clocks qsfp1RefClkP0] \
                 -group [get_clocks -include_generated_clocks qsfp1RefClkP1] \
                 -group [get_clocks -include_generated_clocks pciRefClkP] \
                 -group [get_clocks -include_generated_clocks userClkP] \
                 -group [get_clocks -include_generated_clocks userRefClkP]

create_generated_clock -name clk200_0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name axilClk0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]
#create_generated_clock -name clk200_1 [get_pins {GEN_SEMI[1].U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
#create_generated_clock -name axilClk1 [get_pins {GEN_SEMI[1].U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]

set_clock_groups -asynchronous -group [get_clocks clk200_0] -group [get_clocks axilClk0]


set_clock_groups -asynchronous \
                 -group [get_clocks [list [get_clocks -of_objects [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]] [get_clocks -of_objects [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]] [get_clocks -of_objects [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]] [get_clocks -of_objects [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]]]] \
                 -group [get_clocks [list [get_clocks -of_objects [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]] [get_clocks -of_objects [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]] [get_clocks -of_objects [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]] [get_clocks -of_objects [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]]]]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
