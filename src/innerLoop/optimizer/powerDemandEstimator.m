function future = powerDemandEstimator(past, optimizationHorizon, TEMPORARY_trueData)
    % Ideally we would estimate the future based on the past,
    % but limiting scope of project results in using true data values
    powerDemand = TEMPORARY_trueData(:, 1);
    past = past(~isnan(past));
    future = powerDemand(length(past) + 1 : length(past) + optimizationHorizon);
end
