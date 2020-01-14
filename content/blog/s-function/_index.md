---
title: CasADi codegen and S-Functions
author: jg
tags: NLP simulink
date: 2018-07-13
image: simulink.png
---


While the [user guide](http://docs.casadi.org) does explain code-generation in full detail,
it is handy to have a demonstration in a real environment like Matlab's S-functions.

<!--more-->

# The problem

We will design a Simulink block that implements a nonlinear mapping from ($\mathbf{R}^2$, $\mathbf{R}$) to ($\mathbf{R}$,$\mathbf{R}^2$):

```matlab
import casadi.*

x = MX.sym('x',2);
y = MX.sym('y');

w = dot(x,y*x);
z = sin(x)+y+w;

f = Function('f',{x,y},{w,z});
```

# Code-generating

You may generate code from this with:
```matlab
f.generate('f.c')
```

However, we'll use the more advanced syntax since we have advanced requirements.
In particular, we will use Matlab's data-types for real and integer numbers, requiring us to include a header:

```matlab
cg_options = struct;
cg_options.casadi_real = 'real_T';
cg_options.casadi_int = 'int_T';
cg_options.with_header = true;
cg = CodeGenerator('f',cg_options);
cg.add_include('simstruc.h');
cg.add(f);
cg.generate();
```

This will create `f.c`, and also `f.h` (since we set the option `with_header`).

# S-Function initialize routine




Our S-Function code should include the header `f.h`.
With it, we have access to the problem dimensions:
```matlab
int_T n_in  = f_n_in();
int_T n_out = f_n_out();
```

Next, we can set the block's input/output port dimensions:
```matlab
int_T i;
if (!ssSetNumInputPorts(S, n_in)) return;
for (i=0;i<n_in;++i) {
  const int_T* sp = f_sparsity_in(i);
  /* Dense vector inputs assumed here */
  ssSetInputPortWidth(S, i, sp[0]);
  ssSetInputPortDirectFeedThrough(S, i, 1);
}

if (!ssSetNumOutputPorts(S, n_out)) return;
for (i=0;i<n_out;++i) {
  const int_T* sp = f_sparsity_out(i);
  /* Dense vector outputs assumed here */
  ssSetOutputPortWidth(S, i, sp[0]);
}
```

CaADi codegenerated functions require working memory to evaluate.
We can query the size requirements with:
```matlab
int_T sz_arg, sz_res, sz_iw, sz_w;
f_work(&sz_arg, &sz_res, &sz_iw, &sz_w);
```

Our notion of workspaces maps easily to Simulink's:
```matlab
ssSetNumRWork(S, sz_w);
ssSetNumIWork(S, sz_iw);
ssSetNumPWork(S, sz_arg+sz_res);
```

The only issue is that we differentiate between pointers for the arguments and the results,
while they are combined into a generic `void*` buffer in Simulink.

# S-Function output routine


First, we need access to the working memory. Simple enough for the real and integer workspaces:
```matlab
    real_T* w = ssGetRWork(S);
    int_T* iw = ssGetIWork(S);
```


For `arg` and `res` we have to perform arithmatic and casting from `void**` to the desired types:
```matlab
    void** p = ssGetPWork(S);
    const real_T** arg = (const real_T**) p;
    p += sz_arg;
    real_T** res = (real_T**) p;
```

Next, make `arg` point to the input data:
```matlab
    for (i=0; i<n_in;++i) {
      arg[i] = *ssGetInputPortRealSignalPtrs(S,i);
    }
```

Make `res` point to the output data:
```matlab
    for (i=0; i<n_out;++i) {
      res[i] = ssGetOutputPortRealSignal(S,i);
    }
```

Finally, run the CasADi function:
```matlab
    f(arg,res,iw,w,0);
```

# Running

To actually run the block, we need to compile our S-Function:
```matlab
mex s_function.c f.c
```

{{% figure src="simulink.png" title="View of simulink diagram with our S-Function block in it" %}}
{{% figure src="scope.png" title="Numeric simulation result" %}}



Download code: [do_demo.m](do_demo.m), [s_function.c](s_function.c), [demo.slx](demo.slx).

In summary, we've shown how to use CasADi codegen in general, and in the setting of Simulink S-Functions specifically.
