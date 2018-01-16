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

create_clock -name pgpRxClk0 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
create_clock -name pgpRxClk1 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[1].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
create_clock -name pgpRxClk2 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[2].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
create_clock -name pgpRxClk3 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[3].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]

create_clock -name pgpRxClk4 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[0].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
create_clock -name pgpRxClk5 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[1].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
create_clock -name pgpRxClk6 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[2].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]
create_clock -name pgpRxClk7 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[3].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/RXOUTCLK}]

create_clock -name pgpTxClk0 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
create_clock -name pgpTxClk1 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[1].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
create_clock -name pgpTxClk2 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[2].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
create_clock -name pgpTxClk3 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[3].U_West/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]

create_clock -name pgpTxClk4 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[0].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
create_clock -name pgpTxClk5 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[1].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
create_clock -name pgpTxClk6 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[2].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]
create_clock -name pgpTxClk7 -period 6.400 [get_pins {U_App/U_Pgp/GEN_VEC[3].U_East/U_Pgp/GTP7_CORE_GEN[0].U_GT/U0/Pgp2bGtp7Drp_i/gt0_Pgp2bGtp7Drp_i/gtpe2_i/TXOUTCLK}]

#############
# User LEDs #
#############

set_property -dict { PACKAGE_PIN Y31 IOSTANDARD LVCMOS25 } [get_ports { ledDbg }]

set_property -dict { PACKAGE_PIN H29 IOSTANDARD LVCMOS33 } [get_ports { ledRedL[0]   }]
set_property -dict { PACKAGE_PIN K30 IOSTANDARD LVCMOS33 } [get_ports { ledBlueL[0]  }]
set_property -dict { PACKAGE_PIN J30 IOSTANDARD LVCMOS33 } [get_ports { ledGreenL[0] }]

set_property -dict { PACKAGE_PIN G29 IOSTANDARD LVCMOS33 } [get_ports { ledRedL[1]   }]
set_property -dict { PACKAGE_PIN G30 IOSTANDARD LVCMOS33 } [get_ports { ledBlueL[1]  }]
set_property -dict { PACKAGE_PIN K31 IOSTANDARD LVCMOS33 } [get_ports { ledGreenL[1] }]

set_property -dict { PACKAGE_PIN G32 IOSTANDARD LVCMOS33 } [get_ports { ledRedL[2]   }]
set_property -dict { PACKAGE_PIN K33 IOSTANDARD LVCMOS33 } [get_ports { ledBlueL[2]  }]
set_property -dict { PACKAGE_PIN J34 IOSTANDARD LVCMOS33 } [get_ports { ledGreenL[2] }]

set_property -dict { PACKAGE_PIN H33 IOSTANDARD LVCMOS33 } [get_ports { ledRedL[3]   }]
set_property -dict { PACKAGE_PIN G34 IOSTANDARD LVCMOS33 } [get_ports { ledBlueL[3]  }]
set_property -dict { PACKAGE_PIN L32 IOSTANDARD LVCMOS33 } [get_ports { ledGreenL[3] }]

set_property -dict { PACKAGE_PIN J31 IOSTANDARD LVCMOS33 } [get_ports { ledRedL[4]   }]
set_property -dict { PACKAGE_PIN H31 IOSTANDARD LVCMOS33 } [get_ports { ledBlueL[4]  }]
set_property -dict { PACKAGE_PIN G31 IOSTANDARD LVCMOS33 } [get_ports { ledGreenL[4] }]

set_property -dict { PACKAGE_PIN L29 IOSTANDARD LVCMOS33 } [get_ports { ledRedL[5]   }]
set_property -dict { PACKAGE_PIN L30 IOSTANDARD LVCMOS33 } [get_ports { ledBlueL[5]  }]
set_property -dict { PACKAGE_PIN H32 IOSTANDARD LVCMOS33 } [get_ports { ledGreenL[5] }]

######################
# Timing Constraints #
######################

create_clock -name evrRxClk -period 5.384 [get_pins {U_App/U_Evr/U_GTP/Gtp7Core_Inst/gtpe2_i/RXOUTCLK}]
create_clock -name evrTxClk -period 5.384 [get_pins {U_App/U_Evr/U_GTP/Gtp7Core_Inst/gtpe2_i/TXOUTCLK}]

set_clock_groups -asynchronous -group [get_clocks {pgpTxClk0}] -group [get_clocks {pgpRxClk0}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk1}] -group [get_clocks {pgpRxClk1}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk2}] -group [get_clocks {pgpRxClk2}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk3}] -group [get_clocks {pgpRxClk3}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk4}] -group [get_clocks {pgpRxClk4}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk5}] -group [get_clocks {pgpRxClk5}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk6}] -group [get_clocks {pgpRxClk6}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk7}] -group [get_clocks {pgpRxClk7}] -group [get_clocks {sysClk}]

set_clock_groups -asynchronous -group [get_clocks {evrTxClk}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]

set_clock_groups -asynchronous -group [get_clocks {pgpRxClk0}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpRxClk1}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpRxClk2}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpRxClk3}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpRxClk4}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpRxClk5}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpRxClk6}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpRxClk7}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]

set_clock_groups -asynchronous -group [get_clocks {pgpTxClk0}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk1}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk2}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk3}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk4}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk5}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk6}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]
set_clock_groups -asynchronous -group [get_clocks {pgpTxClk7}] -group [get_clocks {evrRxClk}] -group [get_clocks {sysClk}]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {evrRefClk0}] -group [get_clocks {sysClk}]   
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {evrRefClk1}] -group [get_clocks {sysClk}]

######################
# Area Constraint    #
######################
create_pblock PGP_WEST_GRP
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[0].U_West/U_PgpMon}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[1].U_West/U_PgpMon}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[2].U_West/U_PgpMon}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[3].U_West/U_PgpMon}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[0].U_West/U_Pgp}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[1].U_West/U_Pgp}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[2].U_West/U_Pgp}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[3].U_West/U_Pgp}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[0].U_West/BUILD_FIFO.U_Rx}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[1].U_West/BUILD_FIFO.U_Rx}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[2].U_West/BUILD_FIFO.U_Rx}]
add_cells_to_pblock [get_pblocks PGP_WEST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[3].U_West/BUILD_FIFO.U_Rx}]
resize_pblock [get_pblocks PGP_WEST_GRP] -add {CLOCKREGION_X0Y0:CLOCKREGION_X0Y4}

create_pblock PGP_EAST_GRP
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[0].U_East/U_PgpMon}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[1].U_East/U_PgpMon}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[2].U_East/U_PgpMon}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[3].U_East/U_PgpMon}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[0].U_East/U_Pgp}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[1].U_East/U_Pgp}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[2].U_East/U_Pgp}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[3].U_East/U_Pgp}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[0].U_East/BUILD_FIFO.U_Rx}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[1].U_East/BUILD_FIFO.U_Rx}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[2].U_East/BUILD_FIFO.U_Rx}]
add_cells_to_pblock [get_pblocks PGP_EAST_GRP] [get_cells {U_App/U_Pgp/GEN_VEC[3].U_East/BUILD_FIFO.U_Rx}]
resize_pblock [get_pblocks PGP_EAST_GRP] -add {CLOCKREGION_X1Y0:CLOCKREGION_X1Y4}
