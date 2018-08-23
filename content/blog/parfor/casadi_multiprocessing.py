from multiprocessing import Pool

from casadi import *

N = 250
rs = np.linspace(1,3,N)

x = SX.sym('x')
y = SX.sym('y')

v = vertcat(x,y)
f = (1-x)**2+(y-x**2)**2
g = x**2+y**2
nlp = {'x': v, 'f': f, 'g': g}

# Create IPOPT solver object
options = {};
options["print_time"] = False
options["ipopt"] = {"print_level":0}
solver = casadi.nlpsol('solver', 'ipopt', nlp,options)


def optimize(r):
  res = solver(x0=[2.5,3.0],      # solution guess
               lbx=-inf,          # lower bound on x
               ubx=inf,           # upper bound on x
               lbg=-inf,          # lower bound on g
               ubg=r)         # upper bound on g
   
  
  return float(res["f"])

b = Pool(2)
fsol = b.map(optimize, rs)

from pylab import *
xlabel('Value of r')
ylabel('Objective value at solution')
plot(rs,fsol,'o')
show()
