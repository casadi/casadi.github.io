import casadi as ca

x = ca.MX.sym("x", 2)
p = ca.MX.sym("p")

f = ca.Function("f", [x, p], [ca.sin(x) * p + x[0]], ["x", "p"], ["z"])

ca.GraphBuilder(f).export_onnx("f.onnx")

print(f(ca.DM([0.3, 0.7]), 2.0))
