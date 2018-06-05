from casadi import *

x = MX.sym('x',2); # Two states
p = MX.sym('p');   # Free parameter

# Expression for ODE right-hand side
z = 1-x[1]**2;
rhs = vertcat(z*x[0]-x[1]+2*tanh(p),x[0])

# ODE declaration with free parameter
ode = {'x':x,'p':p,'ode':rhs}

# Construct a Function that integrates over 1s
F = integrator('F','cvodes',ode,{'tf':1})

# Control vector
u = MX.sym('u',4,1)

x = [0,1] # Initial state
for k in range(4):
  # Integrate 1s forward in time:
  # call integrator symbolically
  res = F(x0=x,p=u[k])
  x = res["xf"]

# NLP declaration
nlp = {'x':u,'f':dot(u,u),'g':x};

# Solve using IPOPT
solver = nlpsol('solver','ipopt',nlp)
res = solver(x0=0.2,lbg=0,ubg=0)

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns

np.random.seed(sum(map(ord, "aesthetics")))


from pylab import *
fig = figure()

sns.set_style("ticks")
sns.set_context("talk")


gf = np.linspace(0,1,100)
tg = [0,1,2,3,4]

colors = [None,None]
labels = [{"label":'x_1'},{"label":'x_2'}]

F = integrator('F','cvodes',ode,{'tf':1,'grid':gf})
x0 = vertcat(0,1)
for k in range(4):
  sim = F(x0=x0,p=res["x"][k])
  f1 = plot(k+gf,horzcat(x0[0],sim["xf"][0,:]).T,'--',**labels[0])
  f2 = plot(k+gf,horzcat(x0[1],sim["xf"][1,:]).T,'--',**labels[1])
  if colors[0] is None:
    step(tg,vertcat(res["x"][0],res["x"]),label="u")
    legend(loc='upper center')
    colors[0] = f1[0].get_color()
    colors[1] = f2[0].get_color()
    labels = [{"color":f1[0].get_color()},{"color":f2[0].get_color()}]

  x0 = sim["xf"][:,-1]


grid(True)


xlabel('Time [s]')
title("Optimal control effort to reach x=0")

savefig('content/home/ocp.png', bbox_inches='tight',transparent=True)
