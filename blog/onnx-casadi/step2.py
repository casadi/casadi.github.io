"""Train a tiny surrogate and export a plain ONNX model with PyTorch."""

import torch
from torch import nn


class Vibr(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(nn.Linear(3, 16), nn.Tanh(), nn.Linear(16, 1))

    def forward(self, x, τ):
        return self.net(torch.cat((x, τ), dim=1))


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

print("Training MSE:", loss.item())
model.eval().requires_grad_(False)

torch.onnx.export(model, (torch.zeros(1, 2, dtype=torch.float64),
                         torch.zeros(1, 1, dtype=torch.float64)), "vibr.onnx",
                  input_names=["x", "τ"], output_names=["y"],
                  dynamo=True, opset_version=18, external_data=False)
