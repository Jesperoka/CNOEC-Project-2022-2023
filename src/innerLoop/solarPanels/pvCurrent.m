% TODO: description and improve readability (also complete parameter getting)
function I_p = pvCurrent(I_p, T_p, G, V, pvPowerParams)
    q   = pvCurrentParams.electronCharge;
    k   = pvCurrentParams.boltzmannConstant;
    Tr  = pvCurrentParams.nominalTemperature;   % nominal temperature
    Eg0 = 1.1;                                  % semiconductor band-gap energy
    Voc = 21.6;                                 % open-circuit voltage
    Isc = 6.11;                                 % short-circuit current
    Ki  = 0.002;                                % short-circuit temperature coefficient
    Ns  = 36;                                   % panels connected in series
    Np  = 2;                                    % panels connected ii parallel
    n   = 1.6;                                  % ideality factor of diode
    Rs  = 1e-4;                                 % series resistance (realistically this not a constant if we want to implement MPPT)
    Rsh = 1e3;                                  % shunt resistance

    % Ideal Diode
    if I_p<0
        I_p=0;
    end

    % Circuit equations
    Iph     = (Isc+Ki*(T_p-Tr))*G/1000;
    Irs     = Isc/(exp(q*Voc/(Ns*k*n*T_p))-1);
    I0      = Irs*((T_p/Tr)^3)*exp(q*Eg0/n/k*(-1/T_p+1/Tr));
    Vt      = k*T_p/q;  % "diode thermal voltage"
    Ish     = ( V * Np/Ns + I_p*Rs) / Rsh

    I_p   = Np*Iph - Np*I0*(exp((V/Ns+I_p*Rs/Np)/n*Vt)-1) - Ish;
end