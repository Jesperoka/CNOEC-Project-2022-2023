import matlab.engine
from math import sin
from math import pi
from random import uniform
from numpy import interp
from numpy import ndarray
from ..visualization import plotHelpers

# WARNING THIS FILE IS CURRENTLY UGLY AND WILL BE CHANGED

if __name__ == "__main__":
    # Setting up MATLAB Engine
    m = matlab.engine.start_matlab()
    m.cd("src/innerLoop/solarPanels")

    # Loading constants
    pvParams = m.constants()

    # Simulation setup
    phaseLag = pi/9
    T_p_0 = 0 + 273.15 # Kelvin
    t0 = 0
    tf = 86400
    tspan = [t0, tf]
    epsilon = 0.18
    maxSolarIrradiance = 1000.0 # W/m^2

    # Generating some basic solar irradiance and ambient temperature data.
    uniformTimes = [x for x in range(0, tf + 1)]
    G   = [uniform(0.999, 1.001)*maxSolarIrradiance*sin((2*pi)*(t/tf)) if sin((2*pi)*(t/tf)) >= 0 else 0.0 for t in uniformTimes]
    T_a = [273.15 + 20*sin(2*pi*(t/tf) - phaseLag) + 10*uniform(0.999, 1.001) for t in uniformTimes]
    # G = [0.0 if t <= 0.3*tf else 1000.0 for t in range(0, tf + 1)]
    # T_a = [25 + 273.15 if t <= 1*tf else 5 + 273.15 for t in range(0, tf + 1)]

    # Input in terms of panel surface air flow
    V_air = [0.0 if t < 0.16*tf or t >= 0.26*tf else 0.4 for t in range(0, tf + 1)]

    # Putting Python variables in MATLAB workspace.
    m.workspace['T_p_0'] = float(T_p_0)
    m.workspace['epsilon'] = float(epsilon)
    m.workspace['G'] = m.cell2mat(G)
    m.workspace['T_a'] = m.cell2mat(T_a)
    m.workspace['pvParams'] = pvParams
    m.workspace['t0'] = float(t0)
    m.workspace['tf'] = float(tf)
    m.workspace['V_air'] = m.cell2mat(V_air)
   
    # Because we need to pass a function-type to ode45, we need to use eval().
    t, T_p = m.eval('ode15s( @(t, T_p) pvTemperatureDynamics(t, T_p, T_a, G, V_air, pvParams), [t0 tf], T_p_0)', nargout=2)
    m.exit()

    # Flatten data
    tFlat = [t[0] for t in t]

    # Interpolate for smoother graph
    T_a_interpolated = interp(tFlat, uniformTimes, T_a)
    G_interpolated = interp(tFlat, uniformTimes, G)
    V_air_interpolated = interp(tFlat, uniformTimes, V_air)

    # Plot using standardized plotting helper function
    # Data: [t, T_p] [t, T_a_interpolated] [t, G_interpolated] [t, V_air_interpolated]
    # Labels: "Ambient Temperature (T_a)" "Input Surface Air Velocity (V_air)"
    fig, axes = plotHelpers.standardizedPlot([[t, T_p], [t, T_a_interpolated], [t, G_interpolated], [t, V_air_interpolated]], 
        labels=["Panel Temperature (T_p)", "Ambient Temperature (T_a)",  "Solar Irradiance (G)", "Input Surface Air Velocity (V_air)"],
        xlabel="time (s)",
        ylabel="temperature (K)",
        ylabel2="Solar Irradiance (W m^-2)",
        title="Solar Panel Temperature Dynamics",
        twin=True,
        twinSep=2,
        ylabel3="air velocity (m s^-1)")