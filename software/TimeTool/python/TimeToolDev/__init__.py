#!/usr/bin/env python

# this sys.path.append is a hack to allow TimeToolDev to import it's
# own version of camera-specific submodules (surf/axi-pcie-core etc.) that
# have been placed as subdirectories here by setup.py.  ryan herbst
# thinks of these packages as a device-specific "board support package" - cpo.
import sys
import os
sys.path.append(os.path.dirname(os.path.realpath(__file__)))

from TimeToolDev.TimeToolDev       import *
from TimeToolDev.TimeToolStreams   import *
