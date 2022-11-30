% TODO: description and improve readability (also complete parameter getting)
function I_p = pvCurrent(I_p, T_p, G, V, pvPowerParams)
    q   = pvPowerParams.electronCharge;
    k   = pvPowerParams.boltzmannConstant;
    Tr  = pvPowerParams.nominalTemperature; % nominal temperature
    Eg0 = 1.1;
    Voc = 21.6;
    Isc = 6.11;
    Ki  = 0.002;
    Ns  = 36;
    Np  = 2;
    n   = 1.6;
    Rs  = 1e-4; % Realistically this not a constant if we want to implement MPPT
    Rsh = 1e3;

    % Ideal Diode
    if I_p<0
        I_p=0;
    end

    % Circuit equations
    Iph     = (Isc+Ki*(T_p-Tr))*G/1000;
    Irs     = Isc/(exp(q*Voc/(Ns*k*n*T_p))-1);
    I0      = Irs*((T_p/Tr)^3)*exp(q*Eg0/n/k*(-1/T_p+1/Tr));
    Vt      = k*T_p/q;

    I_p   = Np*Iph-Np*I0*(exp((V/Ns+I_p*Rs/Np)/n/Vt)-1)-(V*Np/Ns+I_p*Rs)/Rsh;
end