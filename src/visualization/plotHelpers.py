# TODO: file description
import matplotlib.pyplot as plt

# TODO: comment
colorProfiles = {"dark": 
{"foregroundColor": "#BBBBBB", "backgroundColor": "#191919","graphColors": ["#6E975C", "#1E4150", "#DA7A41", "#D0C58E"]}}

# TODO: comment
def plotLabeledData(ax, labeledData, graphColors):
    for i, (dataArray, label) in enumerate(labeledData):
        if len(dataArray) == 2: # quick fix
            ax.plot(*dataArray, label=label, color=graphColors[i])
        else:
            ax.plot(dataArray, label=label, color=graphColors[i])

# TODO: comment        
def getColors(colorProfile="dark"):
    foregroundColor = colorProfiles[colorProfile]["foregroundColor"]
    backgroundColor = colorProfiles[colorProfile]["backgroundColor"]
    graphColors = colorProfiles[colorProfile]["graphColors"]
    return foregroundColor, backgroundColor, graphColors

# TODO: comment
def stylizeFigure(fig, axes, title, xlabel, ylabels, foregroundColor, backgroundColor, labelFontSize):
    for ax, ylabel in zip(axes, ylabels):
        plt.setp(ax.spines.values(), color=foregroundColor)
        ax.tick_params('both', colors=foregroundColor)
        ax.set_ylabel(ylabel, color=foregroundColor, fontsize=labelFontSize)
        ax.set_facecolor(backgroundColor)
    axes[0].set_xlabel(xlabel, color=foregroundColor, fontsize=labelFontSize)
    fig.suptitle(title, color=foregroundColor, fontsize=1.5*labelFontSize)
    fig.set_facecolor(backgroundColor)
    fig.set_edgecolor("none")
    fig.legend(facecolor=backgroundColor, edgecolor=foregroundColor, labelcolor=foregroundColor, fontsize=labelFontSize)

# TODO: comment
# Argument 'data' needs to be a list of lists, even if only passing one list of y values, i.e. [[1,2,3,....]]
def standardizedPlot(data, labels, title="Standardized Plot", xlabel="x-axis", ylabel="y-axis-1", ylabel2="y-axis-2", colorProfile="dark", twin=False, twinSep=None, figsize=(8, 6), grid=True, labelFontSize=14):
    fig, ax1 = plt.subplots(sharey = False, figsize=figsize)
    foregroundColor, backgroundColor, graphColors = getColors(colorProfile=colorProfile)
    if twin:
        axes = [ax1, ax1.twinx()]
        labeledData = zip(data[:twinSep], labels[:twinSep])
        TwinLabeledData = zip(data[twinSep:], labels[twinSep:])
        plotLabeledData(axes[0], labeledData, graphColors[:twinSep])
        plotLabeledData(axes[1], TwinLabeledData, graphColors[twinSep:])
        ylabels = [ylabel, ylabel2]
    else:
        axes = [ax1]
        labeledData = zip(data, labels)
        plotLabeledData(axes[0], labeledData, graphColors)
        ylabels = [ylabel] 
    stylizeFigure(fig, axes, title, xlabel, ylabels, foregroundColor, backgroundColor, labelFontSize)
    plt.grid(grid, linewidth=0.25)
    plt.show()
    return fig, axes