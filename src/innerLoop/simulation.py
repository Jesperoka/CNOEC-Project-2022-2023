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

    # Generating some basic solar irradiance and ambient temperature data.
    G   = [100000*sin(2*pi*t/100) + 100000*uniform(0.9, 1.1) for t in range(200)]
    T_a = [20*sin(2*pi*t/100+ pi/9) + 10*uniform(0.9, 1.1) for t in range(200)]

    # Putting Python variables in MATLAB workspace.
    m.workspace["G"] = m.cell2mat(G)
    m.workspace["T_a"] = m.cell2mat(T_a)
    m.workspace['pvParams'] = pvParams
    m.workspace['tf'] = 150
   
    # Because we need to pass a function type to ode45, we need to use eval().
    t, T_p = m.eval('ode45( @(t, T_p) pvTemperatureDynamics(t, T_p, T_a, G, 0.18, struct(pvParams)), [0, 150], 18)', nargout=2)

    # Very basic plot
    plt.legend()
    # T_p_celsius = [x - 273.15 for x in T_p]
    plt.plot(t, T_p)
    # plt.plot(G)
    # T_a_celsius = [x - 273.15 for x in T_a]
    plt.plot(T_a)
    plt.show()