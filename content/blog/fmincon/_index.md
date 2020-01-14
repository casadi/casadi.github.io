---
title: Breaking free of CasADi's solvers
author: jg
tags: NLP fmincon
date: 2018-07-13
---

Once you've modeled your optimization problem in CasADi,
you don't have to stick to the solvers we interface.

In this post, we briefly demonstrate how we can make CasADi and Matlab's `fmincon` cooperate.

<!--more-->

# Trivial unconstrained problem

Let's consider a very simple scalar unconstrained optimization:

$$
\begin{align}
  \displaystyle \underset{x}
  {\text{minimize}}\quad & \sin(x)^2 \\
\end{align}
$$

You can solve this with `fminunc`:
```matlab
fminunc(@(x) sin(x)^2, 0.1)
```
The first argument, an anonymous function, can contain any code, including CasADi code.

Let's use CasADi to evaluate the objective:

```matlab
import casadi.*
x = MX.sym('x');
f = Function('f',{x},{sin(x)^2});

fminunc(@(x) full(f(x)), 0.1)
```

Simple enough, but do mind the `full` to go from CasADi numeric matrix type to a Matlab matrix.

As is, `fminunc` will perform finite differences under the hood.
That's a shame since CasADi can do algorithmic differentiation.

Let's supply the gradient of the objective, computed by CasADi, as well:
```matlab
fg = Function('fg',{x},{y,gradient(y,x)});
fg_full = returntypes('full',fg);

options = optimoptions('fminunc','SpecifyObjectiveGradient',true);
fminunc(@(x) fg_full(x), 0.1, options)
```

Note the `returntypes` helper such that you don't need to explicitly convert from a CasADi numeric matrix to a Matlab matrix.

For this scalar example, you will hardly see any speed-up.
For a decision space of size $n$, the default finite differences approach will cost you `n` times the cost of the objective function evaluation:
`O(n cost(f))`
The algorithmic differentation approach will just cost you `O(cost(f))`. There's a screencast available to learn [more about this aspect](https://www.youtube.com/watch?v=mYOkLkS5yqc).

Download code: [demo1.m](demo1.m)

# Optimal control problem

Next, we will consider the [the race car example](../ocp/#coding).

We assume we have modeled the problem as NLP:
$$
\begin{align}
  \displaystyle \underset{x}
  {\text{minimize}}\quad & f(x,p) \newline
    \text{subject to} \, \quad & \textrm{lbg} \leq g(x,p) \leq \textrm{ubg} \newline
\end{align}
$$

We will solve this problem using `fmincon`.
We just need to construct CasADi functions to compute the objective and constraints and their sensitivities,
and massage them to match the API of `fmincon`.
Again, you can omit the sensitivities and rely on (much slower!) finite differences.

```
% Function to compute objective and its gradient
f = casadi.Function('f',{x,p},{f,gradient(f,x)});

% Function to compute constraint vector, its Jacobian, and bounds
g = casadi.Function('g',{x,p},{g,jacobian(g,x),lbg,ubg});

options = optimoptions('fmincon',...
                       'Display','iter',...
                       'Algorithm','sqp',...
                       'SpecifyObjectiveGradient',true,...
                       'SpecifyConstraintGradient',true);

[x_opt,fval] = fmincon(@(x) obj_casadi(f,x,p),x0,[],[],[],[],[],[], @(x) nonlin_casadi(g,x,p),options);
```

Note the helper functions `obj_casadi` and `nonlin_casadi`.

The first helper is simple enough, and could also be achieved with `returntypes`:
```matlab
function [f,g]=obj_casadi(f_function,x,p)
  [f,g] = f_function(x,p);
  f = full(f);
  g = full(g);
end
```

The second helper is somewhat more involved since we need to separate out the equalities from the inequalities:
```matlab
function [c,ceq,gradc,gradceq]=nonlin_casadi(g_function,x,p)
  % Morph the constraints into c<=0, ceq==0
  %
  % CasADi way: lbg <= g <= ubg
  [g,J,lbg,ubg] = g_function(x,p);
  g = full(g);
  lbg = full(lbg);
  ubg = full(ubg);
  J = sparse(J);

  % Classify into eq/ineq
  eq = lbg==ubg;
  ineq = lbg~=ubg;

  % Classify into free/fixed
  lbg_fixed = lbg~=-inf;
  ubg_fixed = ubg~=inf;

  % Constraint vector
  c = [lbg(ineq&lbg_fixed)-g(ineq&lbg_fixed);g(ineq&ubg_fixed)-ubg(ineq&ubg_fixed)];
  ceq = g(eq)-lbg(eq);

  % Constraint Jacobian tranposed
  gradc = [-J(ineq&lbg_fixed,:);J(ineq&ubg_fixed,:)]';
  gradceq = J(eq,:)';
end
```


There's more options to go from here with `fmincon`.
You may use `which_depends` to classify constraints into linear/nonlinear, you may specify a Hessian,
or you can work with matrix-free (large-scale) methods that require the computation of a matrix-vector product instead of the matrix.

And remember, you always have the code-generation option to speed up your problem if the bottleneck lies with the function evaluations.

In conclusion, choosing to model a problem in CasADi does not lock you in with our solvers.
We've seen how you can embed calls to CasADi function evaluations into third-party codes.

Download code: [demo.m](demo.m), [nonlin_casadi.m](nonlin_casadi.m), [obj_casadi.m](obj_casadi.m),
