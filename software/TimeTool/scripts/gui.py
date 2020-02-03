#!/usr/bin/env python3

import sys
import argparse

import setupLibPaths
import pyrogue.gui
import pyrogue.pydm
import timetool

import rogue

#rogue.Logging.setFilter('pyrogue.batcher', rogue.Logging.Debug)

#################################################################

# Set the argument parser
parser = argparse.ArgumentParser()

# Convert str to bool
argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

def auto_int(x):
    return int (x,0)

# Add arguments
parser.add_argument(
    "--dev",
    dest     = 'dev',
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

#parser.add_argument(
#    "--serverPort",
#    type = int,
#    default = 9099)
  

# Get the arguments
args = parser.parse_args()

#################################################################

with timetool.TimeToolKcu1500Root(**vars(args)) as root:

#    pyrogue.pydm.runPyDM(root=root)

    # Create GUI
    appTop = pyrogue.gui.application(sys.argv)
    guiTop = pyrogue.gui.GuiTop()
    guiTop.addTree(root)
    guiTop.resize(1000, 1000)

    # Run gui
    appTop.exec_()


