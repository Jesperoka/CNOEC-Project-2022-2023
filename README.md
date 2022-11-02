# CNOEC-Project-2022-2023
Project for the course Constrained Numerical Optimization for Estimation and Control at Politecnico di Milano

### Useful things to remember

The README in dependencies has information on the use of MATLAB Engine API for Python, but the 
MATLAB functions themselves can be used from MATLAB directly if preferred.

To run (Python) submodules that import from outside their directory you have to run the .py file as a module:

    python -m src.simulation.badSimulation

Otherwise you will get an error stating:

    ImportError: attempted relative import with no known parent package