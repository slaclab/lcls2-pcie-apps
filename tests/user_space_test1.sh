#!/bin/bash

#TOP=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )/..

CURDIR=$(pwd -P )

TOP="$(dirname "$CURDIR")"

cd $TOP/firmware/

source setup_env_slac.sh

cd $TOP/firmware/targets/TimeToolKcu1500

make clean

make vcs

cd $TOP/firmware/build/TimeToolKcu1500/TimeToolKcu1500_project.sim/sim_1/behav/

source setup_env.sh

./sim_vcs_mx.sh

./simv &
echo "ran simv"

sleep 5

cd $TOP/software/TimeTool
echo $(pwd -P)

source setup_env_template.sh
echo "Sourced setup_enstuff_template.sh"

python scripts/integrated_system_test.py
echo "ran python script"

pkill simv
