# Setup environment
#source /afs/slac/g/reseng/rogue/v2.8.0/setup_env.csh
source /afs/slac/g/reseng/rogue/pre-release/setup_env.csh
#source /afs/slac/g/reseng/rogue/master/setup_env.csh

# Package directories
setenv SURF_DIR ${PWD}/../../firmware/submodules/surf/python/
setenv TTA_DIR  ${PWD}/../../firmware/applications/TimeTool/python/
setenv AXID_DIR ${PWD}/../../firmware/submodules/axi-pcie-core/python/
setenv COM_DIR  ${PWD}/../../firmware/common/python/
setenv LCLT_DIR ${PWD}/../../firmware/submodules/lcls-timing-core/python/
setenv TAR_DIR  ${PWD}/../../firmware/targets/TimeToolKcu1500/

# Setup python path
setenv PYTHONPATH ${SURF_DIR}:${AXID_DIR}:${COM_DIR}:${LCLT_DIR}:${TTA_DIR}:${LOC_DIR}:${PYTHONPATH}

