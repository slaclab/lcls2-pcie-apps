# lcls2-pcie-apps
LCLS2 PCIE-Express Board Applications

# Before you clone the GIT repository

> Create a github account:
> https://github.com/

> On the Linux machine that you will clone the github from, generate a SSH key (if not already done)
> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

> Add a new SSH key to your GitHub account
> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

> Setup for large filesystems on github

```
$ git lfs install
```

> Verify that you have git version 2.13.0 (or later) installed 

```
$ git version
git version 2.13.0
```

> Verify that you have git-lfs version 2.1.1 (or later) installed 

```
$ git-lfs version
git-lfs/2.1.1
```

# Clone the GIT repository

```$ git clone --recursive https://github.com/slaclab/lcls2-pcie-apps```

# How to build the firmware

> Setup your Xilinx Vivado:

>> If you are on the SLAC AFS network:

```$ source lcls2-pcie-apps/firmware/setup_slac.csh```

>> Else you will need to install Vivado and install the Xilinx Licensing

> Go to the firmware's target directory:

```$ cd lcls2-pcie-apps/firmware/targets/TimeToolKcu1500```

> Build the firmware

```$ make```

> Optional: Open up the project in GUI mode to view the firmware build results

```$ make gui```

# How to program the KCU1500
> https://docs.google.com/presentation/d/10eIsAbLmslcNk94yV-F1D3hBfxudBf0EFo4xjcn9qPk/edit?usp=sharing

# How to load the driver

```
# Clone the driver github repo:
$ git clone --recursive https://github.com/slaclab/aes-stream-drivers

# Go to the driver directory
$ cd aes-stream-drivers/data_dev/driver/

# Build the driver
$ make

# add new driver
$ sudo /sbin/insmod datadev.ko || exit 1

# give appropriate group/permissions
$ sudo chmod 666 /dev/datadev*

# Check for the loaded device
$ cat /proc/data_dev0

```
