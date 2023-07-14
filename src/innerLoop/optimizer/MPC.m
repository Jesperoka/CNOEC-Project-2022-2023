% Finite horizon optimal control
function [alpha, beta, gamma, I_air] = MPC(initialValues, estimates, parameters, initialGuess, optimizerParams) % pass estiamtes    
    persistent K C options A b lowerBound upperBound;
    if isempty(A)
        K = optimizerParams.controlVariableHorizon;
        C = optimizerParams.numControlInputs;

        [A, b]      = createLinearConstraints(K);   
        lowerBound  = zeros(C*K, 1, "double");      
        upperBound  = Inf*ones(C*K, 1, "double");

        options         = optimoptions( 'fmincon',...
                                    'Algorithm','interior-point',...
                                    'MaxFunctionEvaluations', 25000,...
                                    'MaxIterations', 10000,...
                                    'ConstraintTolerance', 1.0e-8,...
                                    'StepTolerance', 1.0e-15,...
                                    'EnableFeasibilityMode', false,...
                                    'ScaleProblem', true, ...
                                    'SubproblemAlgorithm','cg',...
                                    'HessianApproximation', 'bfgs',...
                                    'BarrierParamUpdate','monotone',...
                                    'HonorBounds',false,...
                                    'UseParallel', true); 
    end

    [costFunction, constraintFunction] = createNonlinearCostAndConstraints(initialValues, estimates, parameters, optimizerParams);

    [u_star, ~, exitflag, output] = fmincon(costFunction, initialGuess, A, b, [], [], lowerBound, upperBound, constraintFunction, options);
    
    [alpha, beta, gamma, I_air] = splitInputVector(u_star, K, C);

    disp(exitflag)
    disp(output)
end


% This implementation is specific to the ordering- and number of control inputs,  and their upper bounds
function [A, b] = createLinearConstraints(controlVariableHorizon)
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

    K = controlVariableHorizon;

    A = cast([[eye(K), zeros(K, 3*K)] + [zeros(K, K), eye(K), zeros(K, 2*K)];
        eye(4*K)], "double");

    b = cast([ones(4*K, 1);
        I_AIR_MAX*ones(K, 1)], "double");
    
end


% This wrapper funtion allows for sharing the result of the system simulation 
% between the cost function and constraint function at each iteration
function [costFunction, constraintFunction] = createNonlinearCostAndConstraints(initialValues, estimates, parameters, optimizerParams)
    N = optimizerParams.optimizationHorizon;
    K = optimizerParams.controlVariableHorizon;
    C = optimizerParams.numControlInputs;

    batteryParams = parameters{3};
    gridPriceEstimate = estimates(:,4);

    uLast   = NaN(C*K, 1, "double"); % last u-value for which simulateSystem() was called
    P_g_in  = NaN(N, 1, "double"); % shared result of simulateSystem()
    P_g_out = NaN(N, 1, "double"); % shared result of simulateSystem() 
    C_b     = NaN(N, 1, "double"); % shared result of simulateSystem()

    costFunction        = @enclosedCostFunction;
    constraintFunction  = @enclosedNonlinearConstraintFunction;

    function [c, ceq] = enclosedNonlinearConstraintFunction(u)
        if ~isequal(u, uLast)
            [alpha, beta, gamma, I_air] = splitInputVector(u, K, C);
            [P_g_in, P_g_out, C_b]      = simulateSystem(alpha, beta, gamma, I_air, initialValues, estimates, parameters, optimizerParams);
            uLast = u;
        end
        c = cast([-1.0*C_b;                          % require non-negative battery charge
             C_b - batteryParams.maxCharge], "double");    % require charges less than max capacity
        ceq = [];
        assert(allfinite(c))
    end


    function cost = enclosedCostFunction(u)
        if ~isequal(u, uLast)
            [alpha, beta, gamma, I_air] = splitInputVector(u, K, C);
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
    K   = optimizerParams.controlVariableHorizon;
    dt  = optimizerParams.simulationStepSize;
    V_cs = 12; % TODO: move to airCooler parameter struct
    V_p  = 12; % TODO: move to panelCurrent parameter struct (also move the one in the simulink file)
    
    assert(mod(N, K) == 0); % opt. horizon must be divisible by control var. horizon

    % Reduce control granularity for computational feasibility
    singleControlInputLength    = N / K;
    justSomeOnes                = ones([singleControlInputLength, 1]);

    repeatedAlpha   = kron(alpha, justSomeOnes);
    repeatedBeta    = kron(beta,  justSomeOnes);
    repeatedGamma   = kron(gamma, justSomeOnes);
    repeatedI_air   = max(kron(I_air, justSomeOnes), 0.0);  % negative values cause problems for fzero()

    assert(length(repeatedGamma) == N);

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
%     P_h_in_a_0  = initialValues(3);
    C_b_0       = initialValues(4);

    T_p         = T_p_0*ones(N, 1, "double");
    I_p         = I_p_0*ones(N, 1, "double");
%     P_h_in_a    = P_h_in_a_0*ones(N, 1, "double");
    C_b         = C_b_0*ones(N, 1, "double");
    
    P_d         = powerDemandEstimate(1)*ones(N, 1, "double");

    P_g_in      = zeros(N, 1);
    P_g_out      = zeros(N, 1);

    % Simulation
    for i = 1 : N - 1
        % Estimates
        G           = solarIrradiationEstimate(i+1);
        T_a         = ambientTemperatureEstimate(i+1);
        P_d(i+1)    = powerDemandEstimate(i+1) + V_cs*repeatedI_air(i+1);

        V_air = airCooler(repeatedI_air(i));
        
        % Parameterized functions
        T_p_sim_step    = T_p_simulation_step(T_p(i), T_a, V_air, G);
        I_p_char_eq     = I_p_characteristic_eq(T_p(i), G, V_p);

        % Solar Panel Dynamics
        T_p(i+1)        = fzero(T_p_sim_step, T_p(i));
        I_p(i+1)        = max( fzero(I_p_char_eq, I_p(i)),  0.0 );
        P_p             = V_p * I_p(i+1);

        % Power Allocation 
        [P_h_in,  P_g_in(i+1), P_b_in]  = pvPowerSplitter(P_p, repeatedAlpha(i+1), repeatedBeta(i+1));
        [P_b_out, P_g_out(i+1)]         = powerDrawSplitter(P_d(i+1), P_h_in, repeatedGamma(i+1)); % WARNING: double check, changed from P_h_in_a to P_h_in

        P_b = P_b_in - P_b_out; 

        C_b(i+1) = C_b(i) + dt*batteryDynamics(P_b, battParams); % this is what 1st order IRK turns into when system dynamics only depends on input... I think.
    end
end


% Helper funtion to split the contiguous input vector u^T = [alpha^T, beta^T, gamma^T, I_air^T]
function [alpha, beta, gamma, I_air] = splitInputVector(u, controlVariableHorizon, numControlInputs)
    assert(length(u) / numControlInputs == controlVariableHorizon);

    alpha   = u(1                            : 1*controlVariableHorizon);
    beta    = u(1*controlVariableHorizon + 1 : 2*controlVariableHorizon);
    gamma   = u(2*controlVariableHorizon + 1 : 3*controlVariableHorizon);
    I_air   = u(3*controlVariableHorizon + 1 : 4*controlVariableHorizon);
end
