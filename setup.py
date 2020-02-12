
from distutils.core import setup
from git import Repo

repo = Repo()

# Get version before adding version file
ver = repo.git.describe('--tags')

# append version constant to package init
with open('python/surf/__init__.py','a') as vf:
    vf.write(f'\n__version__="{ver}"\n')

setup (
    name='lcls2_timetool',
    version=ver,
    packages=['lcls2_timetool'],
    package_dir={'':'firmware/common/python'},
    scripts['software/scripts/timetoolGui']
)

