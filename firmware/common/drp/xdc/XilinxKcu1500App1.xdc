##############################################################################
## This file is part of 'axi-pcie-core'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'axi-pcie-core', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

###########
# QSFP[1] #
###########


##########
# Clocks #
##########

# create_clock -period 8.000 -name qsfp1RefClkP1 [get_ports {qsfp1RefClkP[1]}]


####################################################################################
# Constraints from file : 'DrpTDet.xdc'
####################################################################################

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks qsfp0RefClkP0] -group [get_clocks -include_generated_clocks qsfp0RefClkP1] -group [get_clocks -include_generated_clocks qsfp1RefClkP0] -group [get_clocks -include_generated_clocks qsfp1RefClkP1] -group [get_clocks -include_generated_clocks pciRefClkP] -group [get_clocks -include_generated_clocks pciExtRefClkP]





# set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {userClkP}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}]
# set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks {userClkP}] -group [get_clocks -include_generated_clocks {qsfp1RefClkP1}]




