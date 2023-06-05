% Dynamic equation for the charging and discharging of the battery 
function C_b_dot = batteryDynamics(P_b, battParams)
    V_oc    = battParams.openCircuitVoltage;
    R_0     = battParams.batteryResistance;
    Q_nom   = battParams.nominalCapacity;
    
    I_b     = batteryCurrent(P_b, V_oc, R_0);
    C_b_dot = (1/Q_nom)*I_b;
end

function I_b = batteryCurrent(P_b, V_oc, R_0)
    I_b = V_oc/(2*R_0) - ((V_oc/(2*R_0))^2 - (P_b/R_0))^(1/2);
end
