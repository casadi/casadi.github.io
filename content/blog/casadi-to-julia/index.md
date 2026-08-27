---
title: From CasADi Function to Julia function, via ONNX
author: jg
tags: onnx julia
date: 2026-08-27
image: pipeline.png
---

CasADi 3.8 ships a `GraphBuilder` class: a format-neutral view on a computational graph, which
can export a CasADi `Function` to an ONNX file and import one back.

Export opens a route into Julia that needs no C compiler and no CasADi on the other side.
Three calls, end to end.

{{% figure src="pipeline.png" title="CasADi Function to Julia function in three steps" %}}

# Exporting from CasADi

```python
import casadi as ca

x = ca.MX.sym("x", 2)
p = ca.MX.sym("p")

f = ca.Function("f", [x, p], [ca.sin(x) * p + x[0]], ["x", "p"], ["z"])

ca.GraphBuilder(f).export_onnx("f.onnx")

print(f(ca.DM([0.3, 0.7]), 2.0))   # [0.89104, 1.58844]
```

The graph survives node for node, `x[0]` included -- it becomes a genuine ONNX `Slice`. ONNX
is being used here as a general expression-graph format, not as a neural-network container.

# Loading in Julia

[ONNX.jl](https://github.com/FluxML/ONNX.jl) reads the file into an
[Umlaut](https://dfdx.github.io/Umlaut.jl/dev/) *tape*, and
[`Umlaut.compile`](https://dfdx.github.io/Umlaut.jl/dev/reference/#Umlaut.compile)
turns that tape into a plain Julia function:

```julia
using ONNX, Umlaut

x = reshape([0.3, 0.7], 2, 1)
p = reshape([2.0], 1, 1)

f = Umlaut.compile(ONNX.load("f.onnx", x, p))

println(f(x, p))   # [0.891040413322679; 1.588435374475382;;]
```

Same numbers as CasADi. And no `ccall`, no shared object to ship: what comes back is ordinary
Julia code.

# Introspecting the result

`compile` does no optimization. It transcribes the tape into an `Expr` -- one line per node --
and hands it to `Base.eval`. `Umlaut.to_expr` shows you exactly what it built:

```julia
julia> println(Umlaut.to_expr(tape))
function var"##tape#278"(x1::Matrix{Float64}, x2::Matrix{Float64})
    x3 = (ONNX._sin)(x1)
    x4 = (ONNX.mul)(x3, x2)
    x5 = [0, 0]; x6 = [1, 1]; x7 = [0, 1]; x8 = [1, 1]
    x9 = (ONNX.onnx_slice)(x1, x5, x6, x7, x8)
    x10 = (ONNX.add)(x4, x9)
    return x10
end
```

Because it is an ordinary method, Julia's own tooling works on it from there. `@code_lowered`
confirms nothing was folded away -- the `Slice` and its four constants are still individual
operations:

```julia
julia> @code_lowered f(x, p)
CodeInfo(
1 ─       x3 = (ONNX._sin)(x1)
│   %2  = x3
│         x4 = (ONNX.mul)(%2, x2)
│         x5 = [0, 0]
│         x6 = [1, 1]
│         x7 = [0, 1]
│         x8 = [1, 1]
│         x9 = (ONNX.onnx_slice)(x1, %8, %9, %10, %11)
│         x10 = (ONNX.add)(%13, %14)
)
```

And `@code_typed` shows what it costs:

```julia
julia> @code_typed f(x, p)
CodeInfo(
1 ─ %1 = invoke ONNX._sin(x1::Matrix{Float64})::Matrix{Float64}
│   %2 = invoke ONNX.mul(%1::Matrix{Float64}, x2::Vararg{Matrix{Float64}})::Matrix{Float64}
│   %3 = invoke ONNX.onnx_slice(x1::Matrix{Float64}, [0, 0]::Vector{Int64}, ...)::Any
│   %4 = invoke ONNX.add(%2::Matrix{Float64}, %3::Vararg{Any})::Any
) => Any
```

Note the `::Any`. `ONNX.onnx_slice` ends in `data[I...]` with a heterogeneous index vector, so
inference gives up there and the `Any` propagates downstream. The answer is still correct -- at
run time it *is* a `Matrix{Float64}` -- but the function is type-unstable.

# Three things to know

**Build the function in `MX`.** `GraphBuilder` walks a function's MX instructions, so an
`SXFunction` is rejected outright. You can still get an SX expression across by inlining it
into an MX graph -- `fsx.call([X, P], True, False)`, where the `True` is `always_inline` -- but
the result is scalarised, one ONNX node per scalar operation. Fine small, unpleasant large.

**Dimensions are reversed.** A CasADi 2-vector is a `1x2` ONNX tensor, and ONNX.jl reverses
axes on load to respect Julia's column-major convention, so you hand it a `2x1` matrix. Worth
a `reshape` and a sanity check on your first function.

**It is a portability bridge, not a fast path.** The type instability above, together with one
materialised array per tape node, costs roughly 900 ns and 1.9 kB per call here, against 25 ns
for the hand-written `sin.(x) .* p .+ x[1]`. ONNX.jl's kernels are written for tensor-sized
work, so on the small nodes a CasADi graph produces the per-node overhead dominates. Since
`to_expr` hands you a plain `Expr`, that is fixable: folding the constant slice and re-fusing
the broadcasts gets within a factor two of hand-written. [optimize.jl](optimize.jl) is one such
pass, in fifty lines.

# The other direction

The same class imports. `create` freezes an ONNX model back into an evaluable CasADi
`Function`:

```python
g = ca.GraphBuilder("f.onnx").create("g", {"symbolic": True})
print(g)                             # g:(x[2],p)->(z[2]) MXFunction
print(g(ca.DM([[0.3, 0.7]]), 2.0))   # [0.89104, 1.58844]
```

With `symbolic: True` the model is rebuilt as an MX graph, so it is differentiable and can be
embedded in an NLP like any other CasADi expression. Leave the option out and CasADi evaluates
through ONNX Runtime instead: faster, but opaque to AD.

So ONNX works as a bridge in both directions -- a model authored in Julia or Python becomes
part of a CasADi optimization problem, and a CasADi graph becomes a native function on the
other side.

Download code: [demo.py](demo.py), [demo.jl](demo.jl), [optimize.jl](optimize.jl)
