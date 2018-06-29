#!/bin/bash
BUILD_DIR=$1
MINIMUM_ARGUMENTS=1
MCS_LOCATION=${BUILD_DIR}/TimeToolKcu1500/TimeToolKcu1500_project.runs/impl_1

if [ $# -ne $MINIMUM_ARGUMENTS ] ; then
   echo -e ""
   echo -e "Usage:   `basename "$0"` <build directory location> (e.g. /u1/sioan/build/)"
   echo -e ""
   exit 0 
fi

./updateProm.py --mcs_pri ${MCS_LOCATION}/TimeToolKcu1500_primary.mcs --mcs_sec ${MCS_LOCATION}/TimeToolKcu1500_secondary.mcs
#echo --mcs_pri ${MCS_LOCATION}/TimeToolKcu1500_primary.mcs --mcs_sec ${MCS_LOCATION}/TimeToolKcu1500_secondary.mcs

