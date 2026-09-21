"""Fine-tune the vibr weights on measurements, inside a CasADi optimization."""

import numpy as np
import torch
from torch import nn
import casadi as ca
from torch2casadi import export


class Vibr(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(nn.Linear(3, 16), nn.Tanh(), nn.Linear(16, 1))

    def forward(self, x, τ):
        return self.net(torch.cat((x, τ), dim=1))


class FreeWeights(nn.Module):
    """Make the weights arguments of forward(), so they become ONNX graph inputs."""
    def __init__(self, model):
        super().__init__()
        self.model = model
        self.names = [n for n, _ in model.named_parameters()]

    def forward(self, *args):
        n = len(self.names)
        return torch.func.functional_call(self.model, dict(zip(self.names, args[-n:])), args[:-n])


# Pretrain as in step2
torch.set_num_threads(1)
torch.manual_seed(42)
model = Vibr().double()

data = torch.rand(1536, 3, dtype=torch.float64)*torch.tensor([3., 1.5, 2.])
data[:, 2] -= 1
target = ((.3+.2*data[:, 0]+.04*data[:, 2])*data[:, 1]**2)[:, None]

optimizer = torch.optim.Adam(model.parameters(), lr=.01)
for _ in range(2500):
    optimizer.zero_grad()
    loss = (model.net(data)-target).square().mean()
    loss.backward()
    optimizer.step()
model.eval().requires_grad_(False)

# Export with the weights as graph inputs
params = [p.detach() for p in model.parameters()]
export(FreeWeights(model), (torch.zeros(1, 2, dtype=torch.float64),
                            torch.zeros(1, 1, dtype=torch.float64), *params), ".",
       name="vibr", input_names=["x", "τ", "W1", "b1", "W2", "b2"], hessian=False, overwrite=True)
vibr = ca.GraphBuilder("vibr.onnx").create("vibr")
print(vibr)

# Measurements from the actual vehicle: it vibrates a bit more than the pretraining data said
rng = np.random.default_rng(0)
meas = rng.uniform(0, 1, (64, 3))*[3., 1.5, 2.] - [0, 0, 1]
y_meas = (.35+.25*meas[:, 0]+.04*meas[:, 2])*meas[:, 1]**2 + .01*rng.standard_normal(64)

# Fit the weights to the measurements, staying close to the pretrained values
opti = ca.Opti()
weights = [opti.variable(p.numel()) for p in params]
residuals = ca.vertcat(*[vibr(m[:2], m[2], *weights) - y for m, y in zip(meas, y_meas)])
opti.minimize(ca.sumsqr(residuals)
              + 1e-2*sum(ca.sumsqr(w-p.reshape(-1).numpy()) for w, p in zip(weights, params)))
for w, p in zip(weights, params):
    opti.set_initial(w, p.reshape(-1).numpy())
opti.solver("ipopt", {}, {"hessian_approximation": "limited-memory",
                          "limited_memory_max_history": 50})
print("RMS error before:", float(np.sqrt(np.mean(opti.debug.value(residuals, opti.initial())**2))))
sol = opti.solve()
print("RMS error after: ", float(np.sqrt(np.mean(sol.value(residuals)**2))))

# Push the adapted weights back into torch
for w, p in zip(weights, model.parameters()):
    p.data = torch.tensor(sol.value(w), dtype=p.dtype).reshape(p.shape)
