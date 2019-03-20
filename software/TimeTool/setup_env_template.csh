# Setup environment
source /afs/slac/g/reseng/rogue/pre-release/setup_rogue.csh

# Package directories
setenv SURF_DIR ${PWD}/../../firmware/submodules/surf/python
setenv AXID_DIR ${PWD}/../../firmware/submodules/axi-pcie-core/python
setenv LCLT_DIR ${PWD}/../../firmware/submodules/lcls-timing-core/python
setenv COM_DIR  ${PWD}/../../firmware/submodules/lcls2-pgp-fw-lib/python
setenv TTA_DIR  ${PWD}/../../firmware/applications/TimeTool/python
setenv TTOOL_DIR  ${PWD}/../../firmware/targets/TimeToolKcu1500/python
setenv FEB_DIR  ${PWD}/../../firmware/submodules/clink-gateway-fw-lib/python

# Setup python path
setenv PYTHONPATH ${SURF_DIR}:${AXID_DIR}:${LCLT_DIR}:${COM_DIR}:${TTA_DIR}:${TTOOL_DIR}:${FEB_DIR}:${PYTHONPATH}
