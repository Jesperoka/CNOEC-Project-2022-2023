# Dependencies

## MATLAB-Python Integration

### MATLAB Engine API
The MATLAB Engine API for Python provides a package for Python to call MATLAB as a computational engine.
Different versions of both MATLAB have compatibility with different versions of Python.

The full list of version compatibilities are found at:
https://se.mathworks.com/support/requirements/python-compatibility.html

If you have Python 3.10.X, you will need at least MATLAB 2022b.

If you have MATLAB 2022b and Python 3.10.x, installation on windows can be done through pip
by opening a cmd- or powershell-console as admin, navigating to the MATLAB python engine folder:

    cd C:\Program Files\MATLAB\R2022b\extern\engines\python

and then running:

    python -m pip install .

The path to the MATLAB root folder can also be found by typing 'matlabroot' in a MATLAB terminal,
which will return your equivalent to C:\Program Files\MATLAB\R2022b.

Other methods of installation (i.e. for other versions of MATLAB and Python) can be found at:
https://se.mathworks.com/help/matlab/matlab_external/install-the-matlab-engine-for-python.html

### MATLAB Compiler SDK

Differences between MATLAB Engine API and MATLAB Compiler SDK: 
https://se.mathworks.com/help/compiler_sdk/python/difference-between-matlab-engine-api-for-python-and-matlab-compiler-sdk.html

