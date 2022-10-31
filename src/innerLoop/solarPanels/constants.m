function out = constants()
    P           = 3.72;     % m
    L           = 1.23;     % m
    A           = 0.7749;   % m^2
    m_p         = 18.04;    % kg 
    c_pp        = 0.7;      % kJ kg^-1 K^-1
    epsilon_n   = 0.18;     % dimensionless

    g           = 9.81;     % m s^-2
    L_c         = A / P;    % m 
    v           = 15.06;    % dimensionless (UNFINISHED)
    alpha_a     = 18.46;    % m^2 s^-1      (UNFINISHED)

    pvParams.rayleigh = [g, L_c, v, alpha_a];

    pvParams.panelArea            = A;      % m^2
    pvParams.panelMass            = m_p;    % kg
    pvParams.characteristicLength = L_c;    % m
    pvParams.panelAvgHeatCapacity = c_pp;   % kJ kg^-1 K^-1


    out = pvParams;
end