
# Rogue
#source /afs/slac.stanford.edu/g/reseng/rogue/master/setup_env.csh
source $HOME/projects/gen_daq/rogue/setup.csh

# Package directories
setenv SURF_DIR ${PWD}/../../firmware/submodules/surf/python/
setenv TTA_DIR  ${PWD}/../../firmware/applications/TimeTool/python/

setenv LOC_DIR ${PWD}/python/

# Setup python path
setenv PYTHONPATH ${SURF_DIR}:${TTA_DIR}:${LOC_DIR}:${PYTHONPATH}

