% Splits P_tot into 3 components based on values of alpha and beta, where sum(alpha, beta) in [0, 1]
function [P_p_in_h, P_p_in_g, P_p_in_b] = pvPowerSplitter(P_p, alpha, beta)
    P_p_in_h = P_p*(1 - alpha - beta);
    P_p_in_g = P_p*alpha;
    P_p_in_b = P_p*beta;
end