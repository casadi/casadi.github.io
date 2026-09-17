"""Black-box ONNX evaluation with exported AD derivatives."""
import casadi as ca

x = ca.MX.sym("x", 2)
u = ca.MX.sym("u")
F = ca.Function("F", [x, u], [ca.vertcat(x[0]+x[1]+u/2, x[1]+u)])

vibr = ca.GraphBuilder("vibr.onnx").create("vibr")

opti = ca.Opti()
τ = opti.parameter()
opti.set_value(τ, 0)

N = 3
X = opti.variable(2, N+1)
U = opti.variable(1, N)
opti.minimize(ca.sumsqr(U))

for k in range(N):
    opti.subject_to(       X[:, k+1] == F(X[:, k], U[:, k]))
    opti.subject_to(-1 <= (U[:, k]   <= 1))
    opti.subject_to( 0 <= (X[1, k]   <= 1.5))
    opti.subject_to(vibr(X[:, k], τ) <= .48)
opti.subject_to(X[:, 0] == [0, 0])
opti.subject_to(X[:, N] == [1.8, 0])

ca.export_graph(ca.jacobian(ca.cse(opti.g), X), "step5.html")

opti.solver("ipopt")

sol = opti.solve()
print("Wetness 0, objective:", sol.value(opti.f))
print("First acceleration:", sol.value(U[0, 0]))

opti.set_value(τ, 1)
sol = opti.solve()
print("Wetness 1, objective:", sol.value(opti.f))
print("First acceleration:", sol.value(U[0, 0]))
