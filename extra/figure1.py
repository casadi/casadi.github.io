import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns
from casadi import *

np.random.seed(sum(map(ord, "aesthetics")))


x = MX.sym('x',2) # Two states

# Expression for ODE right-hand side
z = 1-x[1]**2
rhs = vertcat(z*x[0]-x[1],x[0])

ode = {}         # ODE declaration
ode['x']   = x   # states
ode['ode'] = rhs # right-hand side

tg = np.linspace(0,4,1000);
# Construct a Function that integrates over 1s
F = integrator('F','cvodes',ode,{'tf':4,'grid':tg});

# Start from x=[0;1]
res = F(x0=[0,1])


from pylab import *
fig = figure()


sns.set_style("ticks")
sns.set_context("talk")

C1 = plot(tg,horzcat(0,res["xf"][0,:]).T,'--',label='x_1')[0].get_color()
C2 = plot(tg,horzcat(1,res["xf"][1,:]).T,'--',label='x_2')[0].get_color()
legend(loc='upper center')
plot(0,0,'o',color=C1,markersize=10)
plot(0,1,'o',color=C2,markersize=10)
plot(4,res["xf"][0,-1],'o',markersize=10,markerfacecolor='None',markeredgewidth=2,markeredgecolor=C1)
plot(4,res["xf"][1,-1],'o',markersize=10,markerfacecolor='None',markeredgewidth=2,markeredgecolor=C2)
xlim([-0.2,4.2])
grid(True)

xlabel('Time [s]')

savefig('content/home/integration.png', bbox_inches='tight',transparent=True)
