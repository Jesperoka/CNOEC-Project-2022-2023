from ..dataManipulation import rawDataParsing
from ..visualization import plotHelpers

if __name__ == "__main__":
    cols = rawDataParsing.tStatColumns
    columnsToExtract = [cols["Outdoor Temp (C)"], cols["Wind Speed (km/h)"]]
    numRowsToSkip = 1
    relativeFilePath = "rawData/house1/house1_tstat_blk1.tab"

    columnData = rawDataParsing.extractColumns(relativeFilePath, columnsToExtract, numRowsToSkip)

    convertedData1 = [float(x[0]) for x in columnData]
    convertedData2 = [float(x[1]) for x in columnData]

    timeData = [5*t/60 for t in range(len(convertedData1))]

    plotHelpers.standardizedPlot([[timeData, convertedData1], [timeData, convertedData2]], ["Measured Outdoor Temperature", "Measured Wind Speed"], 
        title="Temperature and Wind Data from a House During 9 Days in February 2016",
        xlabel="time (hours)",
        ylabel="Temperature (C)",
        twin=True,
        twinSep=1,
        ylabel2="Wind Speed (km/h)")