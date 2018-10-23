set_property PACKAGE_PIN AV39 [get_ports timingRefClkN]
set_property PACKAGE_PIN AV38 [get_ports timingRefClkP]
set_property PACKAGE_PIN AU46 [get_ports timingRxN]
set_property PACKAGE_PIN AU45 [get_ports timingRxP]
set_property PACKAGE_PIN AU41 [get_ports timingTxN]
set_property PACKAGE_PIN AU40 [get_ports timingTxP]

create_clock -period 5.380 -name timingRefClkP [get_ports timingRefClkP]

set_property -dict {PACKAGE_PIN AP24 IOSTANDARD LVCMOS18} [get_ports sda]
set_property -dict {PACKAGE_PIN AN24 IOSTANDARD LVCMOS18} [get_ports scl]
set_property -dict {PACKAGE_PIN AL24 IOSTANDARD LVCMOS18} [get_ports i2c_rst_l]

create_clock -period 3.332 -name ddrClkP0 [get_ports {ddrClkP[0]}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {ddrClkP0}] -group [get_clocks -include_generated_clocks pciRefClkP] -group [get_clocks -include_generated_clocks pciExtRefClkP] -group [get_clocks -include_generated_clocks timingRefClkP]

create_clock -period 3.332 -name ddrClkP1 [get_ports {ddrClkP[1]}]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {ddrClkP1}] -group [get_clocks -include_generated_clocks pciRefClkP] -group [get_clocks -include_generated_clocks pciExtRefClkP] -group [get_clocks -include_generated_clocks timingRefClkP]

create_generated_clock -name sysClk_0 -source [get_pins U_Core/U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/I] -master_clock txoutclk_out[3] [get_pins U_Core/U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]
create_generated_clock -name clk200_0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name axilClk0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]
create_generated_clock -name tdetClk0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT2}]

set_clock_groups -asynchronous \
                 -group [get_clocks sysClk_0] \
                 -group [get_clocks clk200_0] \
                 -group [get_clocks axilClk0] \
                 -group [get_clocks tdetClk0]

create_generated_clock -name sysClk_1 -source [get_pins U_Extended/U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/I] -master_clock txoutclk_out[3]_1 [get_pins U_Extended/U_AxiPciePhy/U_AxiPcie/inst/pcie3_ip_i/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O]
create_generated_clock -name clk200_1 [get_pins {GEN_SEMI[1].U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name axilClk1 [get_pins {GEN_SEMI[1].U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]

set_clock_groups -asynchronous \
                 -group [get_clocks sysClk_1] \
                 -group [get_clocks clk200_1] \
                 -group [get_clocks axilClk1]

