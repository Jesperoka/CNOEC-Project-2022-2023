function future = ambientTemperatureEstimator(past, optimizationHorizon, TEMPORARY_trueData)
    % Ideally we would estimate the future based on the past,
    % but limiting scope of project results in using true data values
    ambientTemperatures = TEMPORARY_trueData(:, 3);
    past = past(~isnan(past));
    future = ambientTemperatures(length(past) + 1 : length(past) + optimizationHorizon);
end
