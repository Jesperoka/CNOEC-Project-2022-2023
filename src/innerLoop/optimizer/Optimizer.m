function [alpha, beta, gamma, I_air] = optimizer(...
                                                         houseActualPower,...
                                                         batteryCharge,...
                                                         solarPanelTemperature,...
                                                         solarPanelCurrent,...
                                                         historyVectors,...
                                                         initialGuess,...
                                                         optimizerParams,...
                                                         TEMPORARY_panelTemperatureParams,...
                                                         TEMPORARY_panelCurrentParams,...
                                                         TEMPORARY_batteryParams,...
                                                         TEMPORARY_trueData...
                                                        ) %#codegen

%     V_mppt = zeros(optimizerParams.controlVariableHorizon, 1); % not used

    powerDemandHistory          = historyVectors(:,1);
    gridPriceHistory            = historyVectors(:,2); 
    solarIrradiationHistory     = historyVectors(:,3); 
    ambientTemperatureHistory   = historyVectors(:,4); 

    estimateLength      = floor(optimizerParams.simulationStepSize * optimizerParams.optimizationHorizon);
    interpolationPoints = linspace(1, estimateLength, optimizerParams.optimizationHorizon).';

    powerDemandEstimate         = powerDemandEstimator(powerDemandHistory, estimateLength, TEMPORARY_trueData);
    solarIrradiationEstimate    = solarIrradiationEstimator(solarIrradiationHistory, estimateLength, TEMPORARY_trueData); 
    ambientTemperatureEstimate  = ambientTemperatureEstimator(ambientTemperatureHistory, estimateLength, TEMPORARY_trueData); 
    gridPriceEstimate           = gridPriceEstimator(gridPriceHistory, estimateLength, TEMPORARY_trueData);

    powerDemandEstimate         = interp1(powerDemandEstimate, interpolationPoints);
    solarIrradiationEstimate    = interp1(solarIrradiationEstimate, interpolationPoints);
    ambientTemperatureEstimate  = interp1(ambientTemperatureEstimate, interpolationPoints);
    gridPriceEstimate           = interp1(gridPriceEstimate, interpolationPoints);

    estimates       = [powerDemandEstimate, solarIrradiationEstimate, ambientTemperatureEstimate, gridPriceEstimate];
    initialValues   = [solarPanelTemperature, solarPanelCurrent, houseActualPower, batteryCharge];
    parameters      = {TEMPORARY_panelTemperatureParams, TEMPORARY_panelCurrentParams, TEMPORARY_batteryParams};
    
    assert(all(size(initialGuess) == [4*optimizerParams.controlVariableHorizon, 1]))
    [alpha, beta, gamma, I_air] = MPC(initialValues, estimates, parameters, initialGuess, optimizerParams);
    
    assert(all(size(alpha) == [optimizerParams.controlVariableHorizon, 1]))
    assert(all(size(beta)  == [optimizerParams.controlVariableHorizon, 1]))
    assert(all(size(gamma) == [optimizerParams.controlVariableHorizon, 1]))
    assert(all(size(I_air) == [optimizerParams.controlVariableHorizon, 1]))
end
