function u_star = MPC() % pass estiamtes
    optimizationHorizon = 10 % optimization horizon
    numControlInputs    = 5

    options         = optimoptions('fmincon','Algorithm','interior-point'); % 'UseParallel', true    
    A               = linearConstraintMatrix() % TODO: can use persistent + isempty() later
    ceq             = nonlinearContraints() 
    u0              = zeros(numControlInputs*optimizationHorizon) % can probably be last optimal input
    costFunction    = createCostFunction(optimizationHorizon, numControlInputs)

    u_star = fmincon(costFunction, u0, A, b, A)
end

function  A = createLinearConstraintMatrix()
    % TODO:
    A = 0
end


% This wrapper funtion allows for sharing the result of the 
% system simulation between the cost function and constraint function
function [costFunction, constraintFunction] = createNonlinearCostAndConstraints(optimizationHorizon, numControlInputs)
    uLast   = []; % last u-value for which simulateSystem() was called
    P_g_in  = []; % shared result of simulateSystem()
    P_g_out = []; % shared result of simulateSystem() 
    C_b     = []; % shared result of simulateSystem()

    % TODO: get all parameters

    costFunction        = @enclosedCostFunction
    constraintFunction  = @enclosedNonlinearConstraintFunction

    function [c, ceq] = enclosedNonlinearConstraintFunction(u)
        if ~isequal(u, uLast)
            uLast = u;
            [alpha, beta, gamma, I_air] = splitInputVector(u, optimizationHorizon, numControlInputs)
            [P_g_in, P_g_out, C_b]      = systemDynamics(alpha, beta, gamma, I_air, initialValues, estimates, parameters)
        end
        c = [-1.0*C_b;                      % require non-negative battery charge
             C_b - battParams.maxCharge]    % require charges less than max capacity
        ceq = []
    end


    function costFunction = enclosedCostFunction(u)
        if ~isequal(u, uLast)
            uLast = u;
            [alpha, beta, gamma, I_air] = splitInputVector(u, optimizationHorizon, numControlInputs)
            [P_g_in, P_g_out, C_b]      = systemDynamics(alpha, beta, gamma, I_air, initialValues, estimates, parameters)
        end
        cost = -1.0*gridPriceEstimate.' * (P_g_in - P_g_out);
    end

end


% Simulate the system to compute the necessary vectors for the cost function and constraint function
function [P_g_in, P_g_out, C_b] = simulateSystem(alpha, beta, gamma, I_air, initialValues, estimates, parameters)
    % Parameters
    [solarIrradiationEstimate, ambientTemperatureEstimate, powerDemandEstimate] = estimates
    [pvTemperatureParams, pvPowerParams, battParams, optimizationHorizon] = parameters
    [T_p_0, I_p_0, P_h_in_a_0] = initialValues

    % Parameterizable functions
    T_p_simulation_step = @(T_p, T_a, V_air, G, T_p_next)( @(T_p_next)( ...
        T_p_next - (T_p + dt*pvTemperatureDynamics(0.5*(T_p + T_p_next), T_a, V_air, G, pvTemperatureParams)) ) )
    
    I_p_characteristic_eq = @(T_p, G, V_p, I_p)( @(I_p)( ...
        I_p - pvCurrent(I_p, T_p, G, V_p, pvPowerParams) ) )

    % Initialize vectors to initial value
    T_p         = T_p_0*ones(optimizationHorizon)
    I_p         = I_p_0*ones(optimizationHorizon)
    P_h_in_a    = P_h_in_a_0*ones(optimizationHorizon)
    C_b         = C_b_0*ones(optimizationHorizon) 

    % Simulation
    for i = 1 : optimizationHorizon - 1
        % Estimates
        G           = solarIrradiationEstimate(i+1)
        T_a         = ambientTemperatureEstimate(i+1)
        P_d(i+1)    = powerDemandEstimate(i+1) + V_cs*I_air(i+1)

        V_air = airCooler(I_air(i))
        
        % Parameterized functions
        T_p_sim_step    = T_p_simulation_step(T_p(i), T_a, V_air, G)
        I_p_char_eq     = I_p_characteristic_eq(T_p(i), G, V_p)

        % Solar Panel Dynamics
        T_p(i+1)        = fzero(T_p_sim_step, T_p(i))
        I_p(i+1)        = max( fzero(I_p_char_eq, I_p(i)),  0.0 )
        P_p             = V_p * I_p(i+1)

        % Power Allocation 
        P_h_in          = (1 - alpha(i+1) - beta(i+1)) * P_p
        P_b_minus       = max( beta(i+1)*P_p - (1-gamma(i+1)) * (P_d(i+1) - P_h_in_a(i)),  0.0 )
        P_g_minus       = max( alpha(i+1)*P_p - gamma(i+1)*(P_d(i+1) - P_h_in_a(i))     ,  0.0 ) 

        P_h_in_a(i+1) = P_h_in + P_b_minus + P_g_minus

        P_b_in  = beta(i+1)*P_p % TODO: can just replace these expressions with the allocator functions
        P_b_out = (1 - gamma(i+1))*(P_d - P_in_h_a(i))
        P_b     = P_b_in - P_b_out 

        C_b(i+1) = C_b(i) + dt*batteryDynamics(P_b, battParams) 
    end

    % Grid power flow output vectors
    P_g_in  = (alpha * V_p) .* I_p
    P_g_out = gamma .* (P_d - P_h_in_a)

end

function [alpha, beta, gamma, I_air] = splitInputVector(u, optimizationHorizon, numControlInputs)
    assert(length(u) / numControlInputs == optimizationHorizon);

    alpha   = u(1                         : 1*optimizationHorizon);
    beta    = u(1*optimizationHorizon + 1 : 2*optimizationHorizon);
    gamma   = u(2*optimizationHorizon + 1 : 3*optimizationHorizon);
    I_air   = u(3*optimizationHorizon + 1 : 4*optimizationHorizon);
end
