
# Incase python path is not set
if ( ! $?PYTHONPATH ) then
   setenv PYTHONPATH ""
endif

# Set current directory
set CMD=($_)
set LOC_PATH=`readlink -f "$CMD[2]"`
set LOC_DIR=`dirname "$LOC_PATH"`

# Package directories
setenv SURF_DIR ${LOC_DIR}/../../firmware/submodules/surf/python
setenv LCLT_DIR ${LOC_DIR}/../../firmware/submodules/lcls-timing-core/python
setenv AXID_DIR ${LOC_DIR}/../../firmware/submodules/axi-pcie-core/python
setenv PGP_DIR  ${LOC_DIR}/../../firmware/submodules/lcls2-pgp-fw-lib/python
setenv TTA_DIR  ${LOC_DIR}/../../firmware/applications/TimeTool/python
setenv TAR_DIR  ${LOC_DIR}/../../firmware/targets/TimeToolKcu1500/python

# Setup python path
setenv PYTHONPATH ${SURF_DIR}:${LCLT_DIR}:${AXID_DIR}:${PGP_DIR}:${TTA_DIR}:${TAR_DIR}:${PYTHONPATH}

