#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# Title      : Data Dev test
#-----------------------------------------------------------------------------
# File       : dataDev.py
# Created    : 2017-03-22
#-----------------------------------------------------------------------------
# This file is part of the rogue_example software. It is subject to 
# the license terms in the LICENSE.txt file found in the top-level directory 
# of this distribution and at: 
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
# No part of the rogue_example software, including this file, may be 
# copied, modified, propagated, or distributed except according to the terms 
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import sys
import argparse
import pyrogue as pr
import rogue.hardware.axi
import axipcie as pcie

#################################################################
    
# Set the argument parser
parser = argparse.ArgumentParser()

# Add arguments
parser.add_argument(
    "--dev", 
    type     = str,
    required = False,
    default  = '/dev/datadev_0',
    help     = "path to device",
)  

parser.add_argument(
    "--mcs_pri", 
    type     = str,
    required = True,
    help     = "path to primary MCS file",
)  

parser.add_argument(
    "--mcs_sec", 
    type     = str,
    required = True,
    help     = "path to secondary MCS file",
)    

# Get the arguments
args = parser.parse_args()

#################################################################
    
# Set base
base = pr.Root(name='PcieTop',description='')

# Create the stream interface
memMap = rogue.hardware.axi.AxiMemMap(args.dev)

# Add Base Device
base.add(pcie.AxiPcieCore(memBase=memMap,useSpi=True))

# Start the system
base.start(pollEn=False)

# Load the primary MCS file to QSPI[0]
base.AxiPcieCore.AxiMicronN25Q[0].LoadMcsFile(args.mcs_pri)  

# Load the secondary MCS file to QSPI[1]
base.AxiPcieCore.AxiMicronN25Q[1].LoadMcsFile(args.mcs_sec)  
    
# Close out
base.stop()
exit()
