set_property -dict {PACKAGE_PIN AP24 IOSTANDARD LVCMOS18} [get_ports sda]
set_property -dict {PACKAGE_PIN AN24 IOSTANDARD LVCMOS18} [get_ports scl]
set_property -dict {PACKAGE_PIN AL24 IOSTANDARD LVCMOS18} [get_ports i2c_rst_l]

create_clock -period 3.332 -name ddrClkP0 [get_ports {ddrClkP[0]}]
create_clock -period 3.332 -name ddrClkP1 [get_ports {ddrClkP[1]}]

create_clock -period 6.400 -name qsfp0RefClkP0 [get_ports {qsfp0RefClkP[0]}]
create_clock -period 6.400 -name qsfp0RefClkP1 [get_ports {qsfp0RefClkP[1]}]
create_clock -period 6.400 -name qsfp1RefClkP0 [get_ports {qsfp1RefClkP[0]}]
create_clock -period 6.400 -name qsfp1RefClkP1 [get_ports {qsfp1RefClkP[1]}]

set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks ddrClkP0] \
                 -group [get_clocks -include_generated_clocks ddrClkP1] \
                 -group [get_clocks -include_generated_clocks qsfp0RefClkP0] \
                 -group [get_clocks -include_generated_clocks qsfp0RefClkP1] \
                 -group [get_clocks -include_generated_clocks qsfp1RefClkP0] \
                 -group [get_clocks -include_generated_clocks qsfp1RefClkP1] \
                 -group [get_clocks -include_generated_clocks pciRefClkP] \
                 -group [get_clocks -include_generated_clocks pciExtRefClkP] \
                 -group [get_clocks -include_generated_clocks userClkP] \
                 -group [get_clocks -include_generated_clocks userRefClkP]

create_generated_clock -name clk200_0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name axilClk0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]
create_generated_clock -name clk200_1 [get_pins {GEN_SEMI[1].U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name axilClk1 [get_pins {GEN_SEMI[1].U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]

set_clock_groups -asynchronous \
                 -group [get_clocks clk200_0] \
                 -group [get_clocks clk200_1] \
                 -group [get_clocks axilClk0] \
                 -group [get_clocks axilClk1]


create_generated_clock -name phyRxClk00 -source [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/I}] -master_clock rxoutclk_out[0]_2 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk00 -source [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/I}] -master_clock txoutclk_out[0] [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyTxClk00] -group [get_clocks phyRxClk00]

create_generated_clock -name phyRxClk01 -source [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/I}] -master_clock rxoutclk_out[0]_3 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk01 -source [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/I}] -master_clock txoutclk_out[0]_1 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyTxClk01] -group [get_clocks phyRxClk01]

create_generated_clock -name phyRxClk02 -source [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/I}] -master_clock rxoutclk_out[0]_4 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk02 -source [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/I}] -master_clock txoutclk_out[0]_2 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyTxClk02] -group [get_clocks phyRxClk02]

create_generated_clock -name phyRxClk03 -source [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/I}] -master_clock rxoutclk_out[0]_5 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk03 -source [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/I}] -master_clock txoutclk_out[0]_3 [get_pins {GEN_SEMI[0].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyTxClk03] -group [get_clocks phyRxClk03]

create_generated_clock -name phyRxClk10 -source [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/I}] -master_clock rxoutclk_out[0]_6 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk10 -source [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/I}] -master_clock txoutclk_out[0]_4 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[0].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyTxClk10] -group [get_clocks phyRxClk10]

create_generated_clock -name phyRxClk11 -source [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/I}] -master_clock rxoutclk_out[0]_7 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk11 -source [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/I}] -master_clock txoutclk_out[0]_5 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[1].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyTxClk11] -group [get_clocks phyRxClk11]

create_generated_clock -name phyRxClk12 -source [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/I}] -master_clock rxoutclk_out[0]_8 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk12 -source [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/I}] -master_clock txoutclk_out[0]_6 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[2].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyTxClk12] -group [get_clocks phyRxClk12]

create_generated_clock -name phyRxClk13 -source [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/I}] -master_clock rxoutclk_out[0]_9 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]
create_generated_clock -name phyTxClk13 -source [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/I}] -master_clock txoutclk_out[0]_7 [get_pins {GEN_SEMI[1].U_Hw/U_Pgp/GEN_LANE[3].U_Lane/U_Pgp/U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe3_top.Pgp3GthUsIp10G_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]
set_clock_groups -asynchronous -group [get_clocks phyTxClk13] -group [get_clocks phyRxClk13]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
