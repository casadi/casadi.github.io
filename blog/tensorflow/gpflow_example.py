from casadi import *
from pylab import *
import gpflow

# Needs: pip install gpflow casadi

# Create data points: a noisy sine wave
N = 20
np.random.seed(0)
data = np.linspace(0,10,N).reshape((N,1))
value = np.sin(data)+np.random.normal(0,0.1,(N,1))

# Perform Gaussian process regression
model = gpflow.models.GPR(data, value, gpflow.kernels.Constant(1) + gpflow.kernels.Linear(1) + gpflow.kernels.White(1) + gpflow.kernels.RBF(1))
gpflow.train.ScipyOptimizer().minimize(model)

# Sample the resulting regression finely for plotting
xf = np.linspace(0,10,10*N).reshape((-1,1))
[mean,variance] = model.predict_y(xf)
mean = mean.squeeze()
sigma = np.sqrt(variance).squeeze()

# Plotting
fill_between(xf.squeeze(), mean-3*sigma, mean+3*sigma,color="#aaaaff",label="fit 3 sigma bounds")
plot(data,value,'ro',label="data")
plot(xf,mean,'k-',label="fit")
xlabel('independant variable')
ylabel('dependant variable')
legend()

savefig('gpflow1d.png', bbox_inches='tight')

# Package the resulting regression model in a CasADi callback
class GPR(Callback):
  def __init__(self, name,  opts={}):
    Callback.__init__(self)
    self.construct(name, opts)

  def eval(self, arg):
    [mean,_] = model.predict_y(np.array(arg[0]))
    return [mean]

# Instantiate the Callback (make sure to keep a reference to it!)
gpr = GPR('GPR', {"enable_fd":True})
print(gpr)


# Find the minimum of the regression model
x = MX.sym("x")
solver = nlpsol("solver","ipopt",{"x":x,"f":gpr(x)})
res = solver(x0=5)

plot(res["x"],gpr(res["x"]),'k*',markersize=10,label="Function minimum by CasADi/Ipopt")
legend()

savefig('gpflow1d_min.png', bbox_inches='tight')
