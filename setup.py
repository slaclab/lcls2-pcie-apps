from setuptools import setup, find_packages

pdirlist = ['firmware/submodules/surf/python',
            'firmware/submodules/axi-pcie-core/python',
            'firmware/submodules/lcls-timing-core/python',
            'firmware/submodules/lcls2-pgp-fw-lib/python',
            'firmware/applications/TimeTool/python',
            'firmware/submodules/clink-gateway-fw-lib/python',
            'software/TimeTool/python',
            'software/TimeTool/scripts']

pnamelist = ['surf','axipcie','LclsTimingCore','lcls2_pgp_fw_lib','TimeTool','ClinkFeb','TimeToolDev','scripts']

for pname,pdir in zip(pnamelist,pdirlist):
    setup(
        name = pname,
        license = 'LCLS II',
        description = 'LCLS II firmware package',
        package_dir = {'':pdir},
        packages = find_packages(pdir),
    )
