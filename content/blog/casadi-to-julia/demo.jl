using ONNX, Umlaut

x = reshape([0.3, 0.7], 2, 1)
p = reshape([2.0], 1, 1)

tape = ONNX.load("f.onnx", x, p)
f = Umlaut.compile(tape)

println(f(x, p))
