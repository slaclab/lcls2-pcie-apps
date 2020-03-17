#!/usr/bin/env python

# this sys.path.append is a hack to allow TimeToolDev to import its
# own version of device-specific submodules (surf/axi-pcie-core etc.) that
# have been placed as subdirectories here by setup.py.  ryan herbst
# thinks of these packages as a device-specific "board support package".
# this allows one to put multiple devices in the same conda env.
# a cleaner approach would be to use relative imports everywhere, but
# that would be a lot of work for the tid-air people - cpo.
import sys
import os
sys.path.append(os.path.dirname(os.path.realpath(__file__)))

from lcls2_timetool._Application           import *
from lcls2_timetool._AppLane               import *
from lcls2_timetool._Fex                   import *
from lcls2_timetool._Prescale              import *
from lcls2_timetool._ByPass                import *
from lcls2_timetool._FIR                   import *
from lcls2_timetool._FrameIIR              import *
from lcls2_timetool._FrameSubtractor       import *
from lcls2_timetool._Piranha4VcsEmu        import *
from lcls2_timetool._TimeToolKcu1500       import *
from lcls2_timetool._RunControl            import *
from lcls2_timetool._TimeToolKcu1500Root   import *
