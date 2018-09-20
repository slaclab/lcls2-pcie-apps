# Setup environment
#source /afs/slac/g/reseng/rogue/v2.8.0/setup_env.csh
#source /afs/slac/g/reseng/rogue/pre-release/setup_env.csh
#source /afs/slac/g/reseng/rogue/master/setup_env.csh
#source /u/ey/rherbst/projects/gen_daq/rogue/setup.csh
source /mnt/host/rogue/develpc/pre-release/setup_env.csh

# Package directories
setenv SURF_DIR ${PWD}/../../firmware/submodules/surf/python
setenv LCLT_DIR ${PWD}/../../firmware/submodules/lcls-timing-core/python
setenv AXID_DIR ${PWD}/../../firmware/submodules/axi-pcie-core/python
setenv COM_DIR  ${PWD}/../../firmware/common/python
setenv TTA_DIR  ${PWD}/../../firmware/applications/TimeTool/python
setenv TAR_DIR  ${PWD}/../../firmware/targets/RateTestKcu1500/python

# Setup python path
setenv PYTHONPATH ${SURF_DIR}:${LCLT_DIR}:${AXID_DIR}:${COM_DIR}:${TTA_DIR}:${TAR_DIR}:${PYTHONPATH}

