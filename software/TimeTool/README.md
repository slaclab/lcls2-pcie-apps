# slaclab/lcls2-pcie-apps/software/TimeTool

<!--- ######################################################## -->

# How to install the Rogue With Anaconda

> https://slaclab.github.io/rogue/installing/anaconda.html

<!--- ######################################################## -->

# How to reprogram the FEB firmware via Rogue software

1) Setup the rogue environment
```
$ cd lcls2-pcie-apps/software/TimeTool
$ source setup_env_template.sh
```

2) Run the FEB firmware update script:
```
$ python scripts/updateFeb.py --lane <PGP_LANE> --mcs <PATH_TO_MCS>
```
where <PGP_LANE> is the PGP lane index (range from 0 to 3)
and <PATH_TO_MCS> is the path to the firmware .MCS file


<!--- ######################################################## -->

# How to reprogram the PCIe firmware via Rogue software

1) Setup the rogue environment
```
$ cd cd lcls2-pcie-apps/software/TimeTool
$ source setup_env_template.sh
```

2) Run the PCIe firmware update script:
```
$ python scripts/updatePcieFpga.py --path ../../firmware/targets/TimeToolKcu1500/images/
```

3) Reboot the computer
```
sudo reboot
```

<!--- ######################################################## -->

# How to run the Rogue PyQT GUI

1) Setup the rogue environment
```
$ cd cd lcls2-pcie-apps/software/TimeTool
$ source setup_env_template.sh
```

2) Lauch the GUI:
```
$ python scripts/gui.py
```

<!--- ######################################################## -->

# How to run the Rogue PyQT GUI with VCS firmware simulator

1) Start up two terminal

2) In the 1st terminal, launch the VCS simulation
```
$ source lcls2-pcie-apps/firmware/setup_env_slac.sh
$ cd lcls2-pcie-apps/firmware/targets/TimeToolKcu1500/
$ make vcs
$ cd ../../build/TimeToolKcu1500/TimeToolKcu1500_project.sim/sim_1/behav/
$ source setup_env.sh
$ ./sim_vcs_mx.sh
$ ./simv -gui &
```

3) When the VCS GUI pops up, start the simulation run

4) In the 2nd terminal, launch the PyQT GUI in simulation mode
```
$ cd cd lcls2-pcie-apps/software/TimeTool
$ source setup_env_template.sh
$ python scripts/gui.py --dev sim
```

<!--- ######################################################## -->
