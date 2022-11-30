% placeholder file
function V_air = airCooler(I_in)
    % compute dynamics of air cooling system
    %   - compressed air -> pre-charge compressed air in tank
    %   - electric fan
    %   

    areaOfPvPanel   = 0.7749; % m^2
    numberOfPanels  = 1;

    % Placeholder industrial electric fan
    % https://noctua.at/en/nf-f12-industrialppc-3000-pwm/specification
    maxAirflow      = 186.7/(60*60); % m^3 s^-1
    maxCurrent      = 0.3;           % A
    area            = pi*0.118^2;         % m^2

    numberOfFans    = ceil(numberOfPanels*(areaOfPvPanel)/area);
    currentPerFan   = I_in/numberOfFans;
    
    V_air           = (maxAirflow/maxCurrent)*currentPerFan;
end
