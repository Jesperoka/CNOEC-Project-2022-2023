% Splits P_tot into 3 components based on values of alpha and beta, where sum(alpha, beta) in [0, 1]
function P_in_h, P_in_g, P_in_b = powerSplitter(P_tot, alpha, beta)
    P_in_h = P_tot*(1 - alpha - beta)
    P_in_g = P_tot*alpha
    P_in_b = P_tot*beta
end