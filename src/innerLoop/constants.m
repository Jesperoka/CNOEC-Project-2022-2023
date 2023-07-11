clearvars;

% Load parameters into Simulink
panelCurrentParams      = pvCurrentParams();
panelTemperatureParams  = pvTemperatureParams();
batteryParams           = battParams();
optimizerParams         = optParams();

busInfo1                = Simulink.Bus.createObject(panelCurrentParams);
busInfo2                = Simulink.Bus.createObject(panelTemperatureParams);
busInfo3                = Simulink.Bus.createObject(batteryParams);
busInfo4                = Simulink.Bus.createObject(optimizerParams);

panCurrPars             = evalin('base', busInfo1.busName);
panTempPars             = evalin('base', busInfo2.busName);
battPars                = evalin('base', busInfo3.busName);
optPars                 = evalin('base', busInfo4.busName);

% TODO: create
% function output = airCoolerParams()
%     output = 0
% end

% Function outputting the parameters for the optimizer
function output = optParams()
    optimizerParams.optimizationHorizon     = 100;      % unit is simulationStepSize
    optimizerParams.controlVariableHorizon  = 10;       % how many intervals to divide optimizationHorizon into, must evenly divide optimizationHorizon
    optimizerParams.mpcBlockSize            = 15;       % unit is seconds
    optimizerParams.numControlInputs        = 4;        % must correspond with simulink model and optimizer functions
    optimizerParams.simulationStepSize      = 0.3;      % unit is seconds, granularity of optimizer simulation (IRK 1)
    optimizerParams.simulinkStepSize        = 0.2;      % unit is seconds, granularity of simulink simulation (ode14x)

    output = optimizerParams;
end

% Function outputting the parameters for the battery dynamics
function output = battParams()
    V_oc        = 210;          % V
    R_0         = 1;            % Ω
    Q_nom       = 10000/V_oc;    % C (TODO: check if number is A h, and also what 10000 is)

    battParams.openCircuitVoltage   = V_oc;
    battParams.batteryResistance    = R_0;
    battParams.nominalCapacity      = Q_nom;
    battParams.maxCharge            = 10*546480; % 10 times the max charge of a Tesla battery

    output = battParams;
end

% Function outputting the parameters for the power dynamics of the solar panels
function output = pvCurrentParams()
    q           = 1.6e-19;      % C
    k           = 1.3807e-23;   % J K^-1
    Tr          = 298.15;       % K
    Eg0         = 1.1;
    Voc         = 21.24;
    Isc         = 2.55;
    Ki          = 0.002;
    Ns          = 36;
    Np          = 1; % Number of panels (presumably)
    n           = 1.6;
    Rs          = 1e-4;
    Rsh         = 1e3;
    % TODO: add unit comments

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

    output = pvTemperatureParams;
end
