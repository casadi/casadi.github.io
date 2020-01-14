---
title: CasADi-driven MPC in Simulink (part 2)
author: jg
tags: MPC simulink
date: 2019-12-19
image: mpc_diagram.png
---


In this post, we have a new take on nonlinear MPC in Simulink using CasADi.

<!--more-->

# Interpreter mode

In an [earlier post on MPC in Simulink](https://web.casadi.org/blog/mpc-simulink/), we used an interpreted 'Matlab system' block in the simulink diagram. This is flexible, but slow because of interpreter overhead.

# code-generation mode
In an [earlier post on S-Functions](https://web.casadi.org/blog/s-function/), we showed how Casadi-generated C code can be embedded efficiently in a Simulink diagram using S-functions.
The result is fast, but has restrictions: only `SqpMethod` combined with `Qrqp` or `Osqp` solver can be code-generated (as of 3.5), not e.g. `ipopt`.

# C api mode

Here, we will work with CasADi's C API (new since 3.5) and make Ipopt run within Simulink.

## Constructing a Function
After constructing an Ipopt solver, we create a $\mathbb{R}^2$ symbol to represent current state, and call the solver with symbolic lower and upper variable bounds:
```
solver = nlpsol('solver', 'ipopt', prob, options);

s0 = MX.sym('s0',2);

lbw_sym = MX(lbw);
ubw_sym = MX(ubw);
lbw_sym(1:2) = s0;
ubw_sym(1:2) = s0;

sol_sym = solver('x0', w0, 'lbx', lbw_sym, 'ubx', ubw_sym,...
            'lbg', lbg, 'ubg', ubg);
```
The resultant expression graph, which has the NLP solver embedded, is used to create a Function mapping from current state to optimal control action to be applied:

```matlab
f = Function('f',{s0},{sol_sym.x(3)});
```

Next, we save the Function to the disk. It should be noted that the steps up to here could as well be done from Python, or using different modeling techniques (e.g. Opti).
```matlab
f.save('f.casadi');
```

## C API

Classic CasADi codegen gives you an API with C functions for querying dimensions of inputs and outputs and evaluating. Those C functions are prefixed with the CasADi Function name:

```cpp
#include "f.h"

int_T n_in  = f_n_in();
int_T n_out = f_n_out();
int_T sz_arg, sz_res, sz_iw, sz_w;
f_work(&sz_arg, &sz_res, &sz_iw, &sz_w);

f(arg,res,iw,w,0);
```

The C API mirrors this syntax, but uses an identifier argument instead of prefixing:
```cpp
#include <casadi/casadi_c.h>

int_T n_in = casadi_c_n_in_id(id);
int_T n_out = casadi_c_n_out_id(id);
casadi_c_work_id(id, &sz_arg, &sz_res, &sz_iw, &sz_w);
```

This identifier is obtained from loading the saved file from disk, and specifying a particular Function by name:
```
int ret = casadi_c_push_file("f.casadi");
int id = casadi_c_id("f");
```

Calling the function involves checking out and releasing thread-local memory:
```
int mem = casadi_c_checkout_id(id);
casadi_c_eval_id(id, arg, res, iw, w, mem);
casadi_c_release_id(id, mem);
```

## Compilation

Different from code-generation, our S-function is still dependent on the CasADi runtime.

We'll need to compile the S-function using appropriate include and link flags:
```
lib_path = GlobalOptions.getCasadiPath();
inc_path = GlobalOptions.getCasadiIncludePath();
mex('-v',['-I' inc_path],['-L' lib_path],'-lcasadi', 'casadi_fun.c')
```

# Conclusion

With the above ingredients, one can embed arbitrary CasADi Functions into Simulink with minimal overhead. A fully functional example is available: [do_demo.m](do_demo.m) (run this file first), [casadi_fun.c](casadi_fun.c), [mpc_demo.slx](mpc_demo.slx)
