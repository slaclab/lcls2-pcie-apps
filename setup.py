from setuptools import setup

# use softlinks to make the various "board-support-package" submodules
# look like subpackages of TimeTool.  Then __init__.py will modify
# sys.path so that the correct "local" versions of surf etc. are
# picked up.  A better approach would be using relative imports
# in the submodules, but that's more work.  -cpo

setup(
    name = 'lcls2_timetool',
    description = 'LCLS II TimeTool package',
    packages = [
        'lcls2_timetool',
        'lcls2_timetool.axipcie',
        'lcls2_timetool.ClinkFeb',
        'lcls2_timetool.l2si_core',
        'lcls2_timetool.lcls2_pgp_fw_lib.hardware.XilinxKcu1500',
        'lcls2_timetool.lcls2_pgp_fw_lib.hardware.SlacPgpCardG4',
        'lcls2_timetool.lcls2_pgp_fw_lib.hardware',
        'lcls2_timetool.lcls2_pgp_fw_lib.hardware.shared',
        'lcls2_timetool.lcls2_pgp_fw_lib',
        'lcls2_timetool.surf.misc',
        'lcls2_timetool.surf.xilinx',
        'lcls2_timetool.surf.axi',
        'lcls2_timetool.surf',
        'lcls2_timetool.surf.ethernet.xaui',
        'lcls2_timetool.surf.ethernet.udp',
        'lcls2_timetool.surf.ethernet.ten_gig',
        'lcls2_timetool.surf.ethernet',
        'lcls2_timetool.surf.ethernet.mac',
        'lcls2_timetool.surf.ethernet.gige',
        'lcls2_timetool.surf.protocols.clink',
        'lcls2_timetool.surf.protocols.jesd204b',
        'lcls2_timetool.surf.protocols.i2c',
        'lcls2_timetool.surf.protocols',
        'lcls2_timetool.surf.protocols.ssi',
        'lcls2_timetool.surf.protocols.batcher',
        'lcls2_timetool.surf.protocols.rssi',
        'lcls2_timetool.surf.protocols.pgp',
        'lcls2_timetool.surf.devices.intel',
        'lcls2_timetool.surf.devices.nxp',
        'lcls2_timetool.surf.devices.cypress',
        'lcls2_timetool.surf.devices.linear',
        'lcls2_timetool.surf.devices.micron',
        'lcls2_timetool.surf.devices',
        'lcls2_timetool.surf.devices.analog_devices',
        'lcls2_timetool.surf.devices.microchip',
        'lcls2_timetool.surf.devices.transceivers',
        'lcls2_timetool.surf.devices.silabs',
        'lcls2_timetool.surf.devices.ti',
        'lcls2_timetool.LclsTimingCore',
    ],
    package_dir = {
        'lcls2_timetool': 'firmware/common/python/lcls2_timetool',
        'lcls2_timetool.surf': 'firmware/submodules/surf/python/surf',
        'lcls2_timetool.axipcie': 'firmware/submodules/axi-pcie-core/python/axipcie',
        'lcls2_timetool.LclsTimingCore': 'firmware/submodules/lcls-timing-core/python/LclsTimingCore',
        'lcls2_timetool.lcls2_pgp_fw_lib': 'firmware/submodules/lcls2-pgp-fw-lib/python/lcls2_pgp_fw_lib',
        'lcls2_timetool.ClinkFeb': 'firmware/submodules/clink-gateway-fw-lib/python/ClinkFeb',
        'lcls2_timetool.l2si_core': 'firmware/submodules/l2si-core/python/l2si_core'
    }
)

