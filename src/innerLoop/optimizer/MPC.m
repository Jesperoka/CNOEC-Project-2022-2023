function u_star = MPC()
    % Optimization

    % SQP
    options = optimoptions('fmincon','Algorithm','sqp');

    

    u_star = []
end

function nonlinearConstraints = nonlinearContraints()
    % This function would call all the nonlinear constraint functions and
    % populate the vector nonlinearConstraints in the format require by fmincon() from MATLAB
    % Think of it as a vector function that uses the other individual functions to compute
    % the nonlinear constraints.

    nonlinearConstraints = [] % currently empty
end

function cost = costFunction()
    cost = 1 %%%placeholder
end