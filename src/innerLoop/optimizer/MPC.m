% Finite horizon optimal control
function [alpha, beta, gamma, I_air] = MPC(initialValues, estimates, parameters, initialGuess, optimizerParams) % pass estiamtes
    N = optimizerParams.optimizationHorizon;
    C = optimizerParams.numControlInputs;
    
    options         = optimoptions( 'fmincon',...
                                    'Algorithm','interior-point',...
                                    'MaxFunctionEvaluations', 30000,...
                                    'MaxIterations', 10000,...
                                    'ConstraintTolerance', 1.0e-20,...
                                    'StepTolerance', 1.0e-20,...
                                    'EnableFeasibilityMode', false,...
                                    'ScaleProblem', true, ...
                                    'SubproblemAlgorithm','cg',...
                                    'UseParallel', false);   
    
    [A, b]          = createLinearConstraints(N); % TODO: can use persistent + isempty() later
    
    lowerBound      = zeros(C*N, 1, "double");
    upperBound      = Inf*ones(C*N, 1, "double");

    [costFunction, constraintFunction] = createNonlinearCostAndConstraints(initialValues, estimates, parameters, optimizerParams);

    [u_star, fval, exitflag, output] = fmincon(costFunction, initialGuess, A, b, [], [], lowerBound, upperBound, constraintFunction, options);
    
    [alpha, beta, gamma, I_air] = splitInputVector(u_star, N, C);

    disp(exitflag)
    disp(output)
end


% This implementation is specific to the ordering- and number of control inputs,  and their upper bounds
function [A, b] = createLinearConstraints(optimizationHorizon)
    % Constraint Au <= b represents
    %
    % alpha_i + beta_i <= 1
    % alpha_i <= 1
    % beta_i <= 1
    % gamma_i <= 1
    % I_air_i <= I_AIR_MAX
    %
    % for a column vector u = [alpha; beta; gamma; I_air]
    I_AIR_MAX = 10; % TODO: move to a parameter struct

    N = optimizationHorizon;

    A = cast([[eye(N), zeros(N, 3*N)] + [zeros(N, N), eye(N), zeros(N, 2*N)];
        eye(4*N)], "double");

    b = cast([ones(4*N, 1);
        I_AIR_MAX*ones(N, 1)], "double");
    
end


% This wrapper funtion allows for sharing the result of the system simulation 
% between the cost function and constraint function at each iteration
function [costFunction, constraintFunction] = createNonlinearCostAndConstraints(initialValues, estimates, parameters, optimizerParams)
    N = optimizerParams.optimizationHorizon;
    C = optimizerParams.numControlInputs;

    batteryParams = parameters{3};
    gridPriceEstimate = estimates(:,4);

    uLast   = NaN(C*N, 1, "double"); % last u-value for which simulateSystem() was called
    P_g_in  = NaN(N, 1, "double"); % shared result of simulateSystem()
    P_g_out = NaN(N, 1, "double"); % shared result of simulateSystem() 
    C_b     = NaN(N, 1, "double"); % shared result of simulateSystem()

    costFunction        = @enclosedCostFunction;
    constraintFunction  = @enclosedNonlinearConstraintFunction;

    function [c, ceq] = enclosedNonlinearConstraintFunction(u)
        if ~isequal(u, uLast)
            [alpha, beta, gamma, I_air] = splitInputVector(u, N, C);
            [P_g_in, P_g_out, C_b]      = simulateSystem(alpha, beta, gamma, I_air, initialValues, estimates, parameters, optimizerParams);
            uLast = u;
        end
        c = cast([-1.0*C_b;                                % require non-negative battery charge
             C_b - batteryParams.maxCharge], "double");    % require charges less than max capacity
        ceq = [];
        assert(allfinite(c))
    end


    function cost = enclosedCostFunction(u)
        if ~isequal(u, uLast)
            [alpha, beta, gamma, I_air] = splitInputVector(u, N, C);
            [P_g_in, P_g_out, C_b]      = simulateSystem(alpha, beta, gamma, I_air, initialValues, estimates, parameters, optimizerParams);
            uLast = u;
        end
        cost = cast(-1.0*gridPriceEstimate.' * (P_g_in - P_g_out), "double");
        assert(isfinite(cost))
    end

end


% Simulate the system to compute the necessary vectors for the cost function and constraint function
function [P_g_in, P_g_out, C_b] = simulateSystem(alpha, beta, gamma, I_air, initialValues, estimates, parameters, optimizerParams)
    % Parameters
    N   = optimizerParams.optimizationHorizon;
    dt  = optimizerParams.simulationStepSize;
    V_cs = 12; % TODO: move to airCooler parameter struct
    V_p  = 12; % TODO: move to panelCurrent parameter struct (also move the one in the simulink file)

    pvTemperatureParams = parameters{1};
    pvCurrentParams     = parameters{2};
    battParams          = parameters{3};

    % Estimates
    powerDemandEstimate         = estimates(:,1);
    solarIrradiationEstimate    = estimates(:,2);
    ambientTemperatureEstimate  = estimates(:,3);

    % Parameterizable functions
    T_p_simulation_step = @(T_p_, T_a_, V_air_, G_, T_p_next_)( @(T_p_next_)( ...
        T_p_next_ - (T_p_ + dt*pvTemperatureDynamics(0.5*(T_p_ + T_p_next_), T_a_, V_air_, G_, pvTemperatureParams)) ) );
    
    I_p_characteristic_eq = @(T_p_, G_, V_p_, I_p_)( @(I_p_)( ...
        I_p_ - pvCurrent(I_p_, T_p_, G_, V_p_, pvCurrentParams) ) );

    % Initialize vectors to initial values
    T_p_0       = initialValues(1);
    I_p_0       = initialValues(2);
    P_h_in_a_0  = initialValues(3);
    C_b_0       = initialValues(4);

    T_p         = T_p_0*ones(N, 1, "double");
    I_p         = I_p_0*ones(N, 1, "double");
    P_h_in_a    = P_h_in_a_0*ones(N, 1, "double");
    C_b         = C_b_0*ones(N, 1, "double");
    
    P_d         = powerDemandEstimate(1)*ones(N, 1, "double");

    % Simulation
    for i = 1 : N - 1
        % Estimates
        G           = solarIrradiationEstimate(i+1);
        T_a         = ambientTemperatureEstimate(i+1);
        P_d(i+1)    = powerDemandEstimate(i+1) + V_cs*I_air(i+1);

        V_air = airCooler(I_air(i));
        
        % Parameterized functions
        T_p_sim_step    = T_p_simulation_step(T_p(i), T_a, V_air, G);
        I_p_char_eq     = I_p_characteristic_eq(T_p(i), G, V_p);

        % Solar Panel Dynamics

        T_p(i+1)        = fzero(T_p_sim_step, T_p(i));
        I_p(i+1)        = max( fzero(I_p_char_eq, I_p(i)),  0.0 ); % I_p(i) is just the initial guess, has nothing to do with I_p(i+1)
        P_p             = V_p * I_p(i+1);

        % Power Allocation 
        [P_h_in, P_g_in, P_b_in] = pvPowerSplitter(P_p, alpha(i+1), beta(i+1));
        [P_b_out, P_g_out] = powerDrawSplitter(P_d(i+1), P_h_in_a(i), gamma(i+1));

        P_b_minus       = -1.0*min( P_b_in - P_b_out,  0.0 );
        P_g_minus       = -1.0*min( P_g_in - P_g_out,  0.0 );

        P_h_in_a(i+1) = P_h_in + P_b_minus + P_g_minus;

        P_b     = P_b_in - P_b_out; 

        C_b(i+1) = C_b(i) + dt*batteryDynamics(P_b, battParams); % this is what 1st order IRK turns into when system dynamics only depends on input... I think.
    end

    % Grid power flow output vectors
    P_g_in  = (alpha * V_p) .* I_p;
    P_g_out = gamma .* (P_d - P_h_in_a);

end


% Helper funtion to split the contiguous input vector u^T = [alpha^T, beta^T, gamma^T, I_air^T]
function [alpha, beta, gamma, I_air] = splitInputVector(u, optimizationHorizon, numControlInputs)
    assert(length(u) / numControlInputs == optimizationHorizon);

    alpha   = u(1                         : 1*optimizationHorizon);
    beta    = u(1*optimizationHorizon + 1 : 2*optimizationHorizon);
    gamma   = u(2*optimizationHorizon + 1 : 3*optimizationHorizon);
    I_air   = u(3*optimizationHorizon + 1 : 4*optimizationHorizon);
end
