% This file contains two simple MATLAB functions to serve as an example of how to call MATLAB functions from Python.

function [outputArg1,outputArg2] = exampleFunction(inputArg1,inputArg2)
    %exampleFunction1 Basic addition of constant values
    constVal1 = 4;
    constVal2 = 29;
    outputArg1 = inputArg1 + constVal1;
    outputArg2 = localFunction(inputArg2, constVal2);
    test(13); % you can also call external functions
end

function [outputArg1] = localFunction(inputArg1, inputArg2)
    %exampleFunction2 Local function not visible externally (due to name of .m file)
    outputArg1 = inputArg1 + inputArg2;
end