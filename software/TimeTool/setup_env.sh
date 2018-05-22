
# Enable cmake
#export MODULEPATH=/usr/share/Modules/modulefiles:/etc/modulefiles:/afs/slac.stanford.edu/package/spack/share/spack/modules/linux-rhel6-x86_64
#module load cmake-3.9.4-gcc-4.9.4-ofjqova

# Required packages
#source /afs/slac.stanford.edu/g/reseng/python/3.6.1/settings.sh
#source /afs/slac.stanford.edu/g/reseng/boost/1.64.0/settings.sh

# The following two are optional
#source /afs/slac.stanford.edu/g/reseng/zeromq/4.2.0/settings.sh
#source /afs/slac.stanford.edu/g/reseng/epics/base-R3-15-5-1-0/settings.sh

# Package directories
#export ROGUE_DIR=/afs/slac.stanford.edu/g/reseng/vol12/rogue/master
#export ROGUE_DIR=/afs/slac.stanford.edu/u/if/cpo/git/rogue
export ROGUE_DIR=/reg/neh/home/cpo/git/rogue

# Setup python path
export PYTHONPATH=${ROGUE_DIR}/python:${PYTHONPATH}

# Setup library path
export LD_LIBRARY_PATH=${ROGUE_DIR}/lib:${LD_LIBRARY_PATH}

