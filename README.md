# lcls2-timetool

## Travis CI Status:
[![Anaconda-Server Badge](https://anaconda.org/tidair-tag/timetoolkcu1500/badges/version.svg)](https://anaconda.org/tidair-tag/timetoolkcu1500)
[![Anaconda-Server Badge](https://anaconda.org/tidair-tag/timetoolkcu1500/badges/latest_release_date.svg)](https://anaconda.org/tidair-tag/timetoolkcu1500)

<!--- ######################################################## -->

# Before you clone the GIT repository

1) Create a github account:
> https://github.com/

2) On the Linux machine that you will clone the github from, generate a SSH key (if not already done)
> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

3) Add a new SSH key to your GitHub account
> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

# Clone the GIT repository

```
$ git clone --recursive git@github.com:slaclab/lcls2-pcie-apps
```

<!--- ######################################################## -->

# How to build the PCIe firmware

1) Setup Xilinx licensing
```
$ source lcls2-timetool/firmware/setup_env_slac.sh
```

2) Go to the target directory and make the firmware:
```
$ cd lcls2-timetool/firmware/targets/TimeToolKcu1500/
$ make
```

3) Optional: Review the results in GUI mode
```
$ make gui
```

<!--- ######################################################## -->

# How to load the driver

```
# Confirm that you have the board the computer with VID=1a4a ("SLAC") and PID=2030 ("AXI Stream DAQ")
$ lspci -nn | grep SLAC
04:00.0 Signal processing controller [1180]: SLAC National Accelerator Lab TID-AIR AXI Stream DAQ PCIe card [1a4a:2030]

# Clone the driver github repo:
$ git clone --recursive https://github.com/slaclab/aes-stream-drivers

# Go to the driver directory
$ cd aes-stream-drivers/data_dev/driver/

# Build the driver
$ make

# Load the driver
$ sudo /sbin/insmod ./datadev.ko cfgSize=0x50000 cfgRxCount=256 cfgTxCount=16

# Give appropriate group/permissions
$ sudo chmod 666 /dev/data_dev*

# Check for the loaded device
$ cat /proc/datadev_0

```

<!--- ######################################################## -->
