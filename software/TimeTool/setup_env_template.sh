# Setup environment
#source /afs/slac/g/reseng/rogue/pre-release/setup_rogue.sh

# Package directories
export SURF_DIR=${PWD}/../../firmware/submodules/surf/python
export AXID_DIR=${PWD}/../../firmware/submodules/axi-pcie-core/python
export LCLT_DIR=${PWD}/../../firmware/submodules/lcls-timing-core/python
export COM_DIR=${PWD}/../../firmware/submodules/lcls2-pgp-fw-lib/python
export TTA_DIR=${PWD}/../../firmware/applications/TimeTool/python
export TTOOL_DIR=${PWD}/../../firmware/targets/TimeToolKcu1500/python
export FEB_DIR=${PWD}/../../firmware/targets/clink-gateway-fw-lib/python

# Setup python path
export PYTHONPATH=${SURF_DIR}:${AXID_DIR}:${LCLT_DIR}:${COM_DIR}:${TTA_DIR}:${TTOOL_DIR}:${FEB_DIR}:${PYTHONPATH}
