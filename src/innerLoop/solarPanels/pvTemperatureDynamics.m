% This file implements the mathematical relations governing the temperature dynamics of a solar panel.

% TODO: Description
function T_p_dot = pvTemperatureDynamics(t, T_p, T_a, G, V_air, pvParams)
    L_c     = pvParams.characteristicLength;
    A       = pvParams.panelArea;
    m_p     = pvParams.panelMass;
    c_pp    = pvParams.panelAvgHeatCapacity;
    Pr      = pvParams.prandtlNumber;
    L       = pvParams.panelLength;
    rayleighParams = pvParams.rayleigh;

    epsilon = 0.18;

    G       = interp1([0:length(G)-1], G, t);
    T_a     = interp1([0:length(T_a)-1], T_a, t);
    V_air   = interp1([0:length(V_air)-1], V_air, t);
    if V_air == 0
        Ra  = rayleighNumber(T_p, T_a, rayleighParams);
        Nu  = nusseltNaturalConvection(Ra);
    else
        Re  = reynoldsNumber(V_air, L, rayleighParams(3)); % <---- This is what control input (air cooling) will affect.
        Nu  = nusseltForcedConvection(Re, Pr);
    end

    K   = filmThermalConductivity(T_p, T_a);
    h   = heatTransferCoefficient(Nu, K, L_c); % <---- Which in turn affects the heat transfer coefficient.

    Q_in_dot    = heatInput(G, epsilon, A); % <---- epsilon is also affected by the control input (dust/dirt occlusion). [not yet implemented]
    Q_out_dot   = heatOutput(T_p, T_a, h, A);

    T_p_dot = heatTransfer(Q_in_dot, Q_out_dot, [m_p, c_pp]);
end

% (UNFINISHED) Rayleigh number for natural convection. Used to calculate Nusselt Number.
function Ra = rayleighNumber(T_p, T_a, params)
    g       = params(1);
    L_c     = params(2);
    v       = params(3); % <--- temporarily constant, kinematic viscosity of air.
    alpha_a = params(4); % <--- temporarily constant, thermal diffusivity of air.
    delta_T = abs(T_p - T_a);
    T_f     = (T_p + T_a) / 2;
    beta    = 1 / T_f;

    Ra = (g * beta * delta_T * L_c^3) / (v * alpha_a);
end

% Nusselt number in the case of only natural convection airflow.
function Nu = nusseltNaturalConvection(Ra)
    if Ra < 10^4                        % No convection, only conduction.
        Nu = 1;
    elseif 10^4 <= Ra && Ra < 10^7      % Natural Convection.
        Nu  = 0.54*(Ra^(1/4));
    elseif 10^7 <= Ra && Ra <= 10^11    % Natural Convection.
        Nu = 0.15*(Ra^(1/3));
    else
        error("Error. Nusselt number outside expected range.");
    end
end

% Reynolds number must be used when we have forced convection.
function Re = reynoldsNumber(V_air, length, v)
    Re = V_air*length/v;
end

% Nusselt number in the case of constant air flow across the panel surface
function Nu = nusseltForcedConvection(Re, Pr)
    if Re < 5*10^5 
        Nu = 0.664*(Re^(1/2))*(Pr^(1/3))
    elseif 5*10^5 <= Re && Re <= 10^7
        Nu = (0.037*(Re^(4/5)) - 871)*(Pr^(1/3))
    else
        error("Error. Nusselt number outside expected range.");
    end
end

% (UNFINISHED) Thermal conductivity evaluated at the mean film temperature of the solar panel and the surrounding ambient air.
function K = filmThermalConductivity(T_p, T_a)
    K = 0.23498 % TODO: find a more accurate function for this.
end

% Overall heat transfer coefficient as a function of the Nusselt number Nu and thermal conductivity K.
function h = heatTransferCoefficient(Nu, K, param)
    L_c = param
    
    h = (Nu * K) / L_c
    disp(h)
end

% Solar irradiation heat gain equation.
function Q_in_dot = heatInput(G, epsilon, param)
    A = param;

    Q_in_dot = G * A * (1 - epsilon);
end

% Pure convection heat loss equation.
function Q_out_dot = heatOutput(T_p, T_a, h, param)
    A = param;

    Q_out_dot = h * A * (T_p - T_a);
end

% Thin plate, uniform properties heat transfer equation.
function T_p_dot = heatTransfer(Q_in_dot, Q_out_dot, params) 
    m_p     = params(1);
    c_pp    = params(2);

    T_p_dot = (Q_in_dot - Q_out_dot) / (m_p * c_pp);
end