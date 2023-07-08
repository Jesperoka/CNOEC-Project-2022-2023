function future = solarIrradiationEstimator(past, optimizationHorizon, TEMPORARY_trueData)
    % Ideally we would estimate the future based on the past,
    % but limiting scope of project results in using true data values
    solarIrradiation = TEMPORARY_trueData(:, 2);
    past = past(~isnan(past));
    future = solarIrradiation(length(past) + 1 : length(past) + optimizationHorizon);
end
