---
date: 2014-10-13T20:07:19Z
draft: false
title: "Extended description"
description: "no description"
weight: 6
mode: "manual"
---

## Executive summary of CasADi

CasADi [^1] is a general-purpose tool for quick, yet highly efficient implementation of algorithms for numerical optimization in general and numerical optimal control in particular.

### Symbolic framework with algorithmic differentiation (AD)
A state-of-the-art implementation of algorithmic differentiation (AD), implemented within a symbolic framework, forms the backbone of CasADi. Users construct directed acyclic expression graphs using an _everything-is-a-sparse-matrix_ syntax and expressions for derivatives are generated automatically using AD via _source-code-transformation_. CasADi implements the forward and reverse modes of AD and uses a graph coloring approach to construct large-and-sparse Jacobians and Hessians. Generated expressions are encapsulated in function objects that can be evaluated in virtual machines (VMs).

Compared to similar frameworks, CasADi scales well, and offers a rich set of differentiable operations, including common matrix-valued operations, serial or parallel function calls, (non)linear systems of equations, initial-value problems in ODE or DAE and spline-based lookup tables. External code can be embedded with derivative information either user-provided or approximated by finite differences.

### Core self-containment, auto-generated front-ends via SWIG
The symbolic core of CasADi is written in modern C++, with no external dependencies. While C++ offers great interoperability with other tools, high performance and multi-platform support, it lacks the interactivity and ease-of-use associated with scripting languages such as Python or MATLAB/Octave. CasADi was therefore designed to allow front-ends to be generated automatically using the open-source tool SWIG. At the time of this writing, Python, MATLAB and Octave were supported through full-featured and documented front-ends. The tool has also been successfully used from JAVA and Haskell.

### License and availability
CasADi's source code is hosted on Github and released under GNU Lesser General Public License (LGPL). The relatively permissive LGPL allows CasADi to be used royalty-free in commercial and academic software. The code is built and tested on travis-ci, with full-featured binaries available for common Linux, Mac and Windows systems. In addition, the Python interface is available from `pip`. CasADi can also be run from a demo server.

### C code generation, just-in-time compilation
A large subset of expressions can be exported as self-contained C code without memory allocation. This is useful for embedded applications or to speed up computations using just-in-time compilation (JIT).

### Plugin infrastructure
The core of CasADi supports a number of standard problems in numerical optimization, including initial-value problems in ODE or DAE, linear and nonlinear systems of equations, NLPs and QPs. The user specifies such problems in an uniform way and the solution is delegated to a solver _plugin_, loaded as a dynamically linked library (DLL) at runtime. Solver plugins include solvers that are distributed with CasADi and interfaces to third-party software packages. We detail some of these plugins in the following.

### Linear systems of equations
Linear systems of equations can be embedded into symbolic expressions via differentiable `backslash` nodes. Supported plugins include LDLT and QR [^3] as well as interfaces to CSPARSE and LAPACK.

### Nonlinear systems of equations
Nonlinear systems of equations can be formulated and solved by defining `rootfinder` instances in CasADi. Derivatives of such objects are calculated automatically using the implicit function theorem (IFT). Supported plugins include standard Newton methods and KINSOL from the SUNDIALS suite.

### Initial-value problems in ODE/DAE with automatic sensitivity analysis
Initial-value problems in ordinary or differential-algebraic equations (ODE/DAE) can be calculated using explicit or implicit Runge-Kutta methods or interfaces to IDAS/CVODES from the SUNDIALS suite. Derivatives are calculated using automatically generated forward and adjoint sensitivity equations [^2].

### Quadratic programming
Quadratic programs (QPs), possibly with integer variables (MIQP), can be solved using a primal-dual active-set method \cite{Andersson2018b} or interfaces to CPLEX, GUROBI, HPMPC, OOQP or qpOASES.

### Nonlinear programming with automatic sensitivity analysis, Opti stack
Nonlinear programs (NLPs), possibly with integer variables (MINLP), can be solved using block structure or general sparsity exploiting sequential quadratic programming (SQP) or interfaces to IPOPT/BONMIN, BlockSQP, WORHP, KNITRO and SNOPT. Solution sensitivities can be calculated analytically [^3].

Opti stack, a simple but powerful abstraction layer can be used for convenience.
It manages the creation and optimal-value retrieval of decision variables, allows a mathematical notation to specify constraints, and may identify problematic constraints when a solver reports infeasibity.

### References

[^1] Andersson, J.: A General-Purpose Software Framework for Dynamic Optimization. PhD thesis, Arenberg Doctoral School, KU Leuven (2013)
[^2] Andersson, J.A.E., Gillis, J., Horn, G., Rawlings, J.B., Diehl, M.: CasADi – A software framework for nonlinear optimization and optimal control. Math. Prog. Comp. (Accepted for publication, 2018)
[^3] Andersson, J.A.E., Rawlings, J.B.: Sensitivity Analysis for Nonlinear Programming in CasADi (2018). URL www.optimization-online.org/DB_HTML/2018/05/6642.html. Submitted to NMPC 2018
