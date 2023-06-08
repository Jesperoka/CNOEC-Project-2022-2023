% Load all data
gridPricesDayBefore = readmatrix("gridDayAheadPricesGermany_31_03.csv");
gridPrices          = readmatrix("gridDayAheadPricesGermany_01_04.csv");
weather             = readmatrix("weatherOneDayData.txt");
powerDemand         = readmatrix("powerDemandOneDayData.txt");

% Format and interpolate all data
MINUTES_IN_A_DAY    = 1440;

ambientTemperatures = interp1(weather(:,3) + 273.15, linspace(1, length(weather(:,3)), MINUTES_IN_A_DAY)).';
solarIrradiation    = interp1(weather(:,6), linspace(1, length(weather(:,6)), MINUTES_IN_A_DAY)).';
gridPricesDayBefore = interp1(gridPricesDayBefore(:, 2), linspace(1, length(gridPricesDayBefore(:, 2)), MINUTES_IN_A_DAY)).';
gridPrices          = interp1(gridPrices(:, 2), linspace(1, length(gridPrices(:, 2)), MINUTES_IN_A_DAY)).';
powerDemand         = interp1(powerDemand(:, 3), linspace(1, length(powerDemand(:, 3)), MINUTES_IN_A_DAY)).';
% note powerDemand doesn't actually change, since it's already by-the-minute data

clear("weather", "MINUTES_IN_A_DAY") % cleanup