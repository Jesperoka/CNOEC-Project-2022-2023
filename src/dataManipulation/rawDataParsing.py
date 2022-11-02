# File containing functions for parsing raw data specific to our project.

# Dictionary of columnnames of house1_tstat_blk1.tab and house1_tstat_blk2.tab
tStatColumns = {
        "Date": 0, "Time": 1, "System Setting": 2, "System Mode": 3,	
        "Calendar Event": 4, "Program Mode": 5, "Cool Set Temp (C)": 6,	"Heat Set Temp (C)": 7,
        "Current Temp (C)": 8, "Current Humidity (%RH)": 9, "Outdoor Temp (C)": 10, "Wind Speed (km/h)": 11,	
        "Cool Stage 1 (sec)": 12, "Cool Stage 2 (sec)": 13, "Heat Stage 1 (sec)": 14, "Heat Stage 2 (sec)": 15,
        "Aux Heat 1 (sec)": 16, "Aux Heat 2 (sec)": 17, "Fan (sec)": 18, "DM Offset": 19,
        "Thermostat Temperature (C)": 20, "Thermostat Humidity (%RH)": 21, "Thermostat Motion": 22, "Living Room (C)": 23,	
        "Living Room Motion": 24, "Bedroom (C)": 25, "Bedroom Motion": 26, "Downstairs (C)": 27,	
        "Downstairs Motion}": 28}

# Extracts columns from tabular file.
# @param columns list of indices of columns to extract.
# @param skipRows number of rows to skip from the top of the file.
# @param delimiter character to split lines after. Default is whitespace.
def extractColumns(tabFilePath, columns, skipRows=0, delimiter=None):
    assert skipRows >= 0 and (type(delimiter) == None or type(delimiter == str))
    print("parsing", tabFilePath, "...")
    with open(tabFilePath) as table:
        lines = table.readlines()[skipRows::]
        data = [None] * len(lines)
        for i, line in enumerate(lines):
            data[i] = [line.split(delimiter)[col] for col in columns]
    print("finished parsing", tabFilePath+".")
    return data

# Examples of usage
if __name__ == "__main__":
    numRowsToSkip = 1
    relativeFilePath = "rawData/house1/house1_tstat_blk1.tab"
    columnsToExtract = [ tStatColumns["Date"], tStatColumns["Current Temp (C)"]]

    columnData = extractColumns(relativeFilePath, columnsToExtract, numRowsToSkip)

    print(columnData)