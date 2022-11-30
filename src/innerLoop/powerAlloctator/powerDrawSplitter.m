% Outputs the amount of power to draw from battery storage vs grid power, based on gamma and P_diff.
function [P_out_b, P_out_g] = powerDrawSplitter(P_d, P_in_h, gamma)
    P_diff = P_d - P_in_h;
    P_out_g = P_diff*gamma;
    P_out_b = P_diff*(1 - gamma);
end