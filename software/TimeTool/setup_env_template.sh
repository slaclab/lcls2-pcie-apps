
# Rogue
#source /mnt/host/rogue/develpc/master/setup_env.sh
source /afs/slac.stanford.edu/g/reseng/rogue/master/setup_env.sh
#source $HOME/projects/gen_daq/rogue/setup.sh

# Package directories
export SURF_DIR=${PWD}/../../firmware/submodules/surf/python/
export TTA_DIR=${PWD}/../../firmware/applications/TimeTool/python/
export AXID_DIR=${PWD}/../../firmware/submodules/axi-pcie-core/python/
export COM_DIR=${PWD}/../../firmware/common/python/
export LCLT_DIR=${PWD}/../../firmware/submodules/lcls-timing-core/python/

export LOC_DIR=${PWD}/python/

# Setup python path
export PYTHONPATH=${SURF_DIR}:${AXID_DIR}:${COM_DIR}:${LCLT_DIR}:${TTA_DIR}:${LOC_DIR}:${PYTHONPATH}

