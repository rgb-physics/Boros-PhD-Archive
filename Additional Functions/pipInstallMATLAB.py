import sys
import subprocess

# Install package
def pipInstallMATLAB(packageName):
    # implement pip as a subprocess:
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', packageName])   

# Run function
pipInstallMATLAB(packageName)


