---
title: Neural Networks in constrained optimization
author: jg
tags: onnx NLP
date: 2026-09-17
draft: true
---

# Rationale

Incorporating neural networks in model predictive control has been trending for many years.
A carefully crafted model of a mechanical device may benefit from a pure data-driven approach to model stick/slip friction.
Human comfort may best be described by a learned model to be used as path constraints for an indoor climate system.

# Solutions

Machine learning tools (unconstrained-optimization) and CasADi (constrained optimization) are natural partners. They all share the language of mathematics, and in particular derivatives.

Since CasADi flexibly allows embedding any custom Functions in its computational graph,
many proof-of-concepts have popped up over the years.
The most mature one is probably [l4casadi](https://github.com/Tim-Salzmann/l4casadi).

CasADi 3.8 [introduces](https://web.casadi.org/get/#notesTab-38) a standardized way to create a seamless coupling.
We embraced [ONNX](https://onnx.ai/), the AI industry's exchange format for neural networks.

ONNX is meant for inference (=function evaluation) and encoding of neural networks,
but it's flexible enough to encode generic computational graphs, or indeed derivatives of neural networks.

# Hello world, ONNX

Let's consider a case of a shuttle driving around people on a bumpy road.
It's an optimal control problem with vibrations as path constraints. The vibration behaviour may be influenced by a parameter $\tau$ describing the wetness of the road:


```
Excerpt of /home/jgillis/work/screencasts/onnx/step1.py
/home/jgillis/work/screencasts/onnx/.latex/shuttle.tex
```

Using CasADi Opti, this becomes:
```
Excerpt of /home/jgillis/work/screencasts/onnx/step1.py showing just from ca.Opti to solve and excluding export_graph.
```

We can use torch to train a neural network and export it as onnx:

```
torch.onnx.export(model, (torch.zeros(1, 2, dtype=torch.float64),
                         torch.zeros(1, 1, dtype=torch.float64)), "vibr.onnx",
                  input_names=["x", "τ"], output_names=["y"],
                  dynamo=True, opset_version=18, external_data=False)
```

A new CasADi construct allows us to read that onnx file,
possibly make some parametric dimension concrete, and the create a CasADi Function:

```
vibr = ca.GraphBuilder("vibr.onnx").create("vibr")
print(vibr)
```

Print output
```
```

This required a little extra setup: Download an onnxruntime from https://github.com/microsoft/onnxruntime/releases, and make it available in CASADI_ONNXRUNTIME_LIB env variable. It's this library that will be in charge of evaluating the ONNX file efficiently, on a CPU or a GPU.

You can now happily evaluate this graph:
```
vibr(...)
```
Show output
```
```

# Jacobians and Hessians
How do we get a Jacobian to work? 
```
jacobian(vibr(x,t),x)
```

The lazy way is to defer to CasADi's in-built finite differences:

```
vibr = ca.GraphBuilder("vibr.onnx").create("vibr", {"enable_fd": True})
```

Limited precision and speed, but may get the job done.

The more interesting route is to have your machine learning tool perform source-code-transforming algorithmic differentiation on the neural network and make that part of the exported ONNX file. The most efficient way is when you keep 'vibr.onnx' for pure evalutation, and add for example 'adj_vibr.onnx' to do reverse sensitivity sweeps.
You can now imagine CasADi-generated `nlp_g` talking with 'vibr.onnx' and `nlp_jac_g` talking to 'adj_vibr.onnx'.

This boils down to some sort of convention on top of the ONNX standard, taylored to constrained optimization.

If you are using torch (and in fact the whole point of the ONNX exchange standard is that you can easily model/train in some environment and load the that graph in torch), there is a convenience package that does all the required plumbing: 


```
export(model, (torch.zeros(1, 2, dtype=torch.float64), torch.zeros(1, 1, dtype=torch.float64)),
       ".", name="vibr", overwrite=True, input_names=["x", "τ"], is_diff_in=[True, False])
```

This will generate 'vibr.onnx', 'adj_vibr.onnx', 'fwd_adj_vibr.onnx'

The CasADi Function `vibr` will now automatically become twice differentiable.
```
vibr = ca.GraphBuilder("vibr.onnx").create("vibr")
```

# A whitebox Neural Network

For a subset of the ONNX standard, we also allow to import models symbolically, encoding the neural network flow directly in MX.

```
vibr = ca.GraphBuilder("vibr.onnx").create("vibr", {"symbolic": True})
```

For small Neural Networks that may be more efficient, as CasADi is optimized to work with small/medium scale heterogenous models, as opposed to AI tools who are optimized for bulky tensor operations.

# Wrap-up

This new feature of CasADi is still in its infancy,
but I believe our progressive embracing of the ONNX standard will open a lot of possibilities in the future whilst avoiding vendor lock-in.




