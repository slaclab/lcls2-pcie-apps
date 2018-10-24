
# Incase python path is not set
if [ -z "$PYTHONPATH" ]
then
   PYTHONPATH=""
fi

# Current directory
LOC_DIR=$(dirname -- "$(readlink -f ${BASH_SOURCE[0]})")

# Package directories
export SURF_DIR=${LOC_DIR}/../../firmware/submodules/surf/python/
export AXID_DIR=${LOC_DIR}/../../firmware/submodules/axi-pcie-core/python/
export PGP_DIR=${LOC_DIR}/../../firmware/submodules/lcls2-pgp-fw-lib/python
export LCLT_DIR=${LOC_DIR}/../../firmware/submodules/lcls-timing-core/python/
export TTA_DIR=${LOC_DIR}/../../firmware/applications/TimeTool/python/
export TAR_DIR=${LOC_DIR}/../../firmware/targets/RateTestKcu1500/python

# Setup python path
export PYTHONPATH=${SURF_DIR}:${AXID_DIR}:${PGP_DIR}:${LCLT_DIR}:${TTA_DIR}:${TAR_DIR}:${PYTHONPATH}


