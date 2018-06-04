# Setup environment
#source /afs/slac/g/reseng/rogue/v2.8.0/setup_env.sh
#source /afs/slac/g/reseng/rogue/pre-release/setup_env.sh
#source /afs/slac/g/reseng/rogue/master/setup_env.sh
source setup_env.sh

# Package directories
export SURF_DIR=${PWD}/../../firmware/submodules/surf/python/
export TTA_DIR=${PWD}/../../firmware/applications/TimeTool/python/
export AXID_DIR=${PWD}/../../firmware/submodules/axi-pcie-core/python/
export COM_DIR=${PWD}/../../firmware/common/python/
export LCLT_DIR=${PWD}/../../firmware/submodules/lcls-timing-core/python/

export TTOOL_DIR=${PWD}/../../firmware/targets/TimeToolKcu1500/python

# Setup python path
export PYTHONPATH=${SURF_DIR}:${AXID_DIR}:${COM_DIR}:${LCLT_DIR}:${TTA_DIR}:${TTOOL_DIR}:${PYTHONPATH}
