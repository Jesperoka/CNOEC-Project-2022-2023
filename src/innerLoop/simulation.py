import matlab.engine
from math import sin
from math import pi
from random import uniform
import matplotlib.pyplot as plt

if __name__ == "__main__":
    # Setting up MATLAB Engine
    m = matlab.engine.start_matlab()
    m.cd("src/innerLoop/solarPanels")

    # Loading constants
    pvParams = m.constants()

    # Simulation setup
    T_p_0 = 18 + 273.15 # Kelvin
    t0 = 0
    tf = 1000
    tspan = [t0, tf]
    epsilon = 0.18
    maxSolarIrradiance = 1000 # W/m^2

    # Generating some basic solar irradiance and ambient temperature data. Just sine curves.
    G   = [uniform(0.999, 1.001)*maxSolarIrradiance*sin((2*pi)*(t/tf)) if sin((2*pi)*(t/tf)) >= 0 else 0.0 for t in range(0, tf + 1)]
    T_a = [273.15 + 20*sin(2*pi*(t/tf) + pi/9) + 10*uniform(0.999, 1.001) for t in range(0, tf + 1)]

    # Putting Python variables in MATLAB workspace.
    m.workspace['T_p_0'] = float(T_p_0)
    m.workspace['epsilon'] = float(epsilon)
    m.workspace['G'] = m.cell2mat(G)
    m.workspace['T_a'] = m.cell2mat(T_a)
    m.workspace['pvParams'] = pvParams
    m.workspace['t0'] = float(t0)
    m.workspace['tf'] = float(tf)
   
    # Because we need to pass a function type to ode45, we need to use eval().
    t, T_p = m.eval('ode15s( @(t, T_p) pvTemperatureDynamics(t, T_p, T_a, G, epsilon, pvParams), [t0 tf], T_p_0)', nargout=2)
    m.exit()

    # Very basic plot
    fig, ax1 = plt.subplots(sharey = False, figsize=(8, 6))
    axes = [ax1, ax1.twinx()]

    axes[0].plot(t, T_p, label="T_p", color="#6E975C")
    axes[0].plot(T_a, label="T_a", color="#1E4150")
    axes[1].plot(G, label="G", color="#DA7A41")

    ylabels = ['temperature (K)', 'irradiance (W m^-2)']
    xlabels = ['time']

    foregroundColor = "#BBBBBB"
    backgroundColor = "#191919"
    labelFontSize = 16

    for ax, ylabel in zip(axes, ylabels):
        plt.setp(ax.spines.values(), color=foregroundColor)
        ax.tick_params('both', colors=foregroundColor)
        ax.set_ylabel(ylabel, color=foregroundColor, fontsize=labelFontSize)
        ax.set_facecolor(backgroundColor)
    
    fig.suptitle("test", color=foregroundColor, fontsize=2*labelFontSize)
    fig.set_facecolor(backgroundColor)
    fig.set_edgecolor("none")

    fig.legend(facecolor=backgroundColor, edgecolor=foregroundColor, labelcolor=foregroundColor)
    plt.show()