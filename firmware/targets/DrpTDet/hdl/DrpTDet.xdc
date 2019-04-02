# QSFP0 MGTREGCLK0 (programmable)
set_property PACKAGE_PIN AV39 [get_ports timingRefClkN]
set_property PACKAGE_PIN AV38 [get_ports timingRefClkP]
# QSFP0 Lane 0
set_property PACKAGE_PIN AU46 [get_ports timingRxN]
set_property PACKAGE_PIN AU45 [get_ports timingRxP]
set_property PACKAGE_PIN AU41 [get_ports timingTxN]
set_property PACKAGE_PIN AU40 [get_ports timingTxP]

create_clock -period 5.380 -name timingRefClkP [get_ports timingRefClkP]

# QSFP1 MGTREFCLK1 (non-programmable)
set_property PACKAGE_PIN AN37 [get_ports {userRefClkN}]
set_property PACKAGE_PIN AN36 [get_ports {userRefClkP}]
create_clock -period 6.400 -name userRefClkP [get_ports userRefClkP]

set_property -dict {PACKAGE_PIN AP24 IOSTANDARD LVCMOS18} [get_ports sda]
set_property -dict {PACKAGE_PIN AN24 IOSTANDARD LVCMOS18} [get_ports scl]
set_property -dict {PACKAGE_PIN AL24 IOSTANDARD LVCMOS18} [get_ports i2c_rst_l]

create_clock -period 3.332 -name ddrClkP0 [get_ports {ddrClkP[0]}]
create_clock -period 3.332 -name ddrClkP1 [get_ports {ddrClkP[1]}]
set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP0}] \
                 -group [get_clocks -include_generated_clocks {ddrClkP1}] \
                 -group [get_clocks -include_generated_clocks pciRefClkP] \
                 -group [get_clocks -include_generated_clocks pciExtRefClkP] \
                 -group [get_clocks -include_generated_clocks timingRefClkP] \
                 -group [get_clocks -include_generated_clocks userClkP] \
                 -group [get_clocks -include_generated_clocks userRefClkP]

create_generated_clock -name clk200_0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name axilClk0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]
create_generated_clock -name tdetClk0 [get_pins {GEN_SEMI[0].U_MMCM/MmcmGen.U_Mmcm/CLKOUT2}]
create_generated_clock -name clk200_1 [get_pins {GEN_SEMI[1].U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name axilClk1 [get_pins {GEN_SEMI[1].U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]


set_clock_groups -asynchronous \
                 -group [get_clocks clk200_0] \
                 -group [get_clocks clk200_1] \
                 -group [get_clocks axilClk0] \
                 -group [get_clocks axilClk1] \
                 -group [get_clocks tdetClk0]

create_generated_clock -name timingRecClk [get_pins {U_Timing/TimingGthCoreWrapper_1/GEN_EXTREF.U_TimingGthCore/inst/gen_gtwizard_gthe3_top.TimingGth_extref_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[0].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/RXOUTCLK}]

set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks timingRefClkP] \
                 -group [get_clocks timingRecClk]
