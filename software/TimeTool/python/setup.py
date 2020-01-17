from setuptools import setup, find_packages

# use softlinks to make the various "board-support-package" submodules
# look like subpackages of TimeTool.  Then __init__.py will modify
# sys.path so that the correct "local" versions of surf etc. are
# picked up.  A better approach would be using relative imports
# in the submodules, but that's more work.  -cpo

subpackages = ['submodules/surf/python/surf','submodules/axi-pcie-core/python/axipcie','submodules/lcls-timing-core/python/LclsTimingCore','submodules/lcls2-pgp-fw-lib/python/XilinxKcu1500Pgp','submodules/clink-gateway-fw-lib/python/ClinkFeb','applications/TimeTool/python/TimeTool']

import os
print(os.path.dirname(os.path.realpath(__file__)))

for pkgpath in subpackages:
    pkgname = pkgpath.split('/')[-1]
    linkname = os.path.join('TimeToolDev',pkgname)
    if os.path.islink(linkname): os.remove(linkname)
    os.symlink(os.path.join('../../../../firmware',pkgpath),linkname)

setup(
    name = 'TimeToolDev',
    description = 'LCLS II TimeTool package',
    packages = find_packages(),
)
