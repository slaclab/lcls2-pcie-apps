#somehow need to verify that /u1/psreldev directory exists.  Which is won't unless it's been made once.

echo  "starting build script"

echo  "setting builtin to exit when anything fails"
set -e

echo "export HOME=~"
export HOME=~
echo "export USER=`whoami`"#!/bin/bash

#somehow need to verify that /u1/psreldev directory exists.  Which is won't unless it's been made once.

echo  "starting build script"

echo  "setting builtin to exit when anything fails"
set -e

echo "export HOME=~"
export HOME=~
echo "export USER=`whoami`"
export USER=`whoami`

echo "source /reg/g/psdm/sw/conda2/manage/bin/psconda.sh"
source /reg/g/psdm/sw/conda2/manage/bin/psconda.sh


echo "activating conda environment with git-lfs"
conda activate /reg/g/psdm/sw/conda2/inst/envs/ps-2.0.5/

echo "doing the git clean -fxd"
git clean -fxd

echo "initializing submodules"
git submodule init

echo "updating (recursively)"
git submodule update --recursive

echo "generating simulated data"
cd firmware/simulations/TimeToolKcu1500ComponentTb/data_generation_scripts
python make_simulation_input_file.py
cd ../../../../

echo "sourcing the build environment"
source firmware/setup_env_slac.sh

echo "going to the time tool top directory to make"
cd firmware/targets/TimeToolKcu1500

echo "git lfs install --force"
git lfs install --force
echo "git-lfs pull"
git-lfs pull
echo "git submodule foreach git-lfs pull"
git submodule foreach git-lfs pull


echo "making clean"
make clean

echo "making no gui"
make nogui

echo "executing simulation script"
cd ../../build/TimeToolKcu1500/
vivado -mode batch -source firmware/targets/TimeToolKcu1500/simulation.tcl



#source setup_env.sh -py2
# don't install python2 version because it checks syntax of py3 files
#./build_all.sh
#pytest psana/psana/tests
#pytest psana/psana/tests/byhand_mpi.py
export USER=`whoami`

echo "source /reg/g/psdm/sw/conda2/manage/bin/psconda.sh"
source /reg/g/psdm/sw/conda2/manage/bin/psconda.sh


echo "activating conda environment with git-lfs"
conda activate /reg/g/psdm/sw/conda2/inst/envs/ps-2.0.5/

echo "doing the git clean -fxd"
git clean -fxd

echo "initializing submodules"
git submodule init

echo "updating (recursively)"
git submodule update --recursive

echo "generating simulated data"
cd firmware/simulations/TimeToolKcu1500ComponentTb/data_generation_scripts
python make_simulation_input_file.py
cd ../../../../

echo "sourcing the build environment"
source firmware/setup_env_slac.sh

echo "going to the time tool top directory to make"
cd firmware/targets/TimeToolKcu1500

echo "git lfs install --force"
git lfs install --force
echo "git-lfs pull"
git-lfs pull
echo "git submodule foreach git-lfs pull"
git submodule foreach git-lfs pull


echo "making clean"
make clean

echo "making no gui"
make nogui

echo "executing simulation script"
cd ../../build/TimeToolKcu1500/
vivado -mode batch -source firmware/targets/TimeToolKcu1500/simulation.tcl
