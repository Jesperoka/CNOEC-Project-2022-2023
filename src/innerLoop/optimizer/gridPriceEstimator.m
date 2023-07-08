function future = gridPriceEstimator(past, optimizationHorizon, TEMPORARY_trueData)
    % Ideally we would estimate the future based on the past,
    % but for grid prices we are using the previous day's prices
    gridPricesDayBefore = TEMPORARY_trueData(:, 4); 
    past = past(~isnan(past));
    future = gridPricesDayBefore(length(past) + 1 : length(past) + optimizationHorizon);
end
