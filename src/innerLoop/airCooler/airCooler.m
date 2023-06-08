% placeholder file
function V_air = airCooler(I_in)
    % THIS IS JUST A MADE UP FAN ARRAY THAT CAN BLOW MORE AIR
    % IF IT IS GIVEN MORE CURRENT.
    % LOOSELY BASED ON: https://noctua.at/en/nf-f12-industrialppc-3000-pwm/specification

    areaOfPvPanel   = 0.7749; % m^2
    numberOfPanels  = 1;

    maxAirflow      = 186.7/(60*60); % m^3 s^-1
    maxCurrent      = 0.3;           % A
    area            = pi*0.118^2;         % m^2

    numberOfFans    = ceil(numberOfPanels*(areaOfPvPanel)/area);
    currentPerFan   = I_in/numberOfFans;
    
    V_air           = (maxAirflow/maxCurrent)*currentPerFan;
end
