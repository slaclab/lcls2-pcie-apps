#!/usr/bin/env python3

import sys
import argparse

import setupLibPaths
import pyrogue.gui
import timetool

import lcls2_pgp_fw_lib


#################################################################

# Set the argument parser
parser = argparse.ArgumentParser()

# Convert str to bool
argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

# Add arguments
parser.add_argument(
    "--dev",
    dest     = 'driverPath',
    type     = str,
    required = False,
    default  = '/dev/datadev_0',
    help     = "path to device",
)  

parser.add_argument(
    "--pgp3", 
    type     = argBool,
    required = False,
    default  = False,
    help     = "true = PGPv3, false = PGP2b",
) 

parser.add_argument(
    "--pollEn", 
    type     = argBool,
    required = False,
    default  = False,
    help     = "Enable auto-polling",
) 

parser.add_argument(
    "--initRead", 
    type     = argBool,
    required = False,
    default  = False,
    help     = "Enable read all variables at start",
)  

parser.add_argument(
    "--dataDebug", 
    type     = argBool,
    required = False,
    default  = False,
    help     = "Enable TimeToolRx module",
)  

# Get the arguments
args = parser.parse_args()

#################################################################

with timetool.TimeToolKcu1500Root(**vars(args)) as root:

# Create GUI
    appTop = pyrogue.gui.application(sys.argv)
    guiTop = pyrogue.gui.GuiTop()
    guiTop.addTree(root)
    guiTop.resize(1000, 1000)

    # Run gui
    appTop.exec_()


