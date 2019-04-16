# Setup environment
source /afs/slac.stanford.edu/g/reseng/rogue/anaconda/rogue_pre-release.sh
conda activate rogue_v3.3.1

# Package directories
export SURF_DIR=${PWD}/../../firmware/submodules/surf/python
export AXID_DIR=${PWD}/../../firmware/submodules/axi-pcie-core/python
export LCLT_DIR=${PWD}/../../firmware/submodules/lcls-timing-core/python
export COM_DIR=${PWD}/../../firmware/submodules/lcls2-pgp-fw-lib/python
export TTA_DIR=${PWD}/../../firmware/applications/TimeTool/python
export FEB_DIR=${PWD}/../../firmware/submodules/clink-gateway-fw-lib/python
export TTOOL_DIR=${PWD}/python

# Setup python path
export PYTHONPATH=${TTOOL_DIR}:${SURF_DIR}:${AXID_DIR}:${LCLT_DIR}:${COM_DIR}:${TTA_DIR}:${FEB_DIR}:${PYTHONPATH}
