# Details on how to setup the matlab and matlab.engine packages can be found in the dependencies directory
import matlab.engine


# Example of how to run a basic MATLAB function from Python
def runExample(matlabEngine):
    inOne = 1
    inTwo = 4
    print("Inputs to exampleFunction() are:", inOne, "and", inTwo)

    # Multiple outputs are output as tuples. 
    # The number of output arguments must be specified by 'nargout', unless it exactly equals 1.
    outOne, outTwo = matlabEngine.exampleFunction(inOne, inTwo, nargout=2)
    print("Outputs from exampleFunction() are:", outOne, "and", outTwo)


# Certain things need to be in order before using the engine.
if __name__ == "__main__": 
    # start_matlab() returns an object that is used to access the MATLAB engine.
    m = matlab.engine.start_matlab()

    # Just like in MATLAB itself, the function .m file needs to be in the current folder or on the MATLAB PATH.
    currentPath = m.cd(nargout=1) # Here nargout=1 is optional
    print(currentPath)

    # We can change the current folder with MATLAB's cd function. In this case the argument is the relative path
    # from the (assumed) path to the project directory.
    m.cd("src/test") 
    print(m.cd()) # Here nargout=1 is optional

    # We can pass the engine object to Python functions.
    runExample(m) 

    # This is how you shut down the MATLAB engine (Notice that it is just another MATLAB function).
    m.exit()
