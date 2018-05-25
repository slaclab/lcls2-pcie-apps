#!/bin/bash
source /reg/g/psdm/etc/psconda.sh
conda activate /reg/neh/home/cpo/.conda/envs/timetoolLab2/
cd ../
source setup_env_template.sh
cd scripts
./gui.py
