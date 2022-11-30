% Parameters to load into Simulink
pvPowerParams       = pvPowerParams();
pvTemperatureParams = pvTemperatureParams();
battParams          = battParams();

% TODO: create
% function output = airCoolerParams()
%     output = 0
% end

% Function outputting the parameters for the battery dynamics
function output = battParams()
    V_oc        = 210;          % V
    R_0         = 1;            % Ω
    Q_nom       = 10000/V_oc    % C (TODO: check if number is A h, and also what 10000 is)

    battParams.openCircuitVoltage   = V_oc;
    battParams.batteryResistance    = R_0;
    battParams.nominalCapacity      = Q_nom;

    output = battParams;
end

% Function outputting the parameters for the power dynamics of the solar panels
function output = pvPowerParams()
    q           = 1.6e-19; % electron charge [C]
    k           = 1.3805e-23; % Boltzmann's constant
    Tr          = 298.15; % nominal temperature
    Eg0         = 1.1;
    Voc         = 21.24;
    Isc         = 2.55;
    Ki          = 0.002;
    Ns          = 36;
    Np          = 1;
    n           = 1.6;
    Rs          = 1e-4;
    Rsh         = 1e3;

    pvPowerParams.electronCharge        = q;
    pvPowerParams.boltzmannConstant     = k;
    pvPowerParams.nominalTemperature    = Tr;
    % TODO: complete parameter assignments to parameter struct

    output = pvPowerParams;
end

% Function outputting the parameters for the temperature dynamics of the solar panels
function output = pvTemperatureParams()
    P           = 3.72;         % m
    L           = 1.23;         % m
    A           = 0.7749;       % m^2
    m_p         = 18.04;        % kg 
    c_pp        = 750;          % J kg^-1 K^-1
    epsilon_n   = 0.18;         % dimensionless (UNFINISHED)
    Pr          = 0.71;         % dimensionless (UNFINISHED)

    g           = 9.81;         % m s^-2
    L_c         = A / P;        % m 
    v           = 1.6*10^-5;    % dimensionless (UNFINISHED) 
    alpha_a     = 21*10^-6;     % m^2 s^-1      (UNFINISHED)

    pvTemperatureParams.rayleigh = [g, L_c, v, alpha_a];

    pvTemperatureParams.panelLength            = L;    % m
    pvTemperatureParams.panelArea              = A;    % m^2
    pvTemperatureParams.panelMass              = m_p;  % kg
    pvTemperatureParams.characteristicLength   = L_c;  % m
    pvTemperatureParams.panelAvgHeatCapacity   = c_pp; % J kg^-1 K^-1
    pvTemperatureParams.prandtlNumber          = Pr;   % dimensionless  

    output = pvParams;
end