---
title: "What is CasADi"
description: "no description"
type: singles
<!-- layout: whatiscasadi -->
---

CasADi is a symbolic framework for algorithmic (a.k.a. automatic) differentiation and numeric optimization. Using the syntax of computer algebra systems, it allows users to construct symbolic expressions consisting of either scalar- or (sparse) matrix-valued operations. These expressions can then be efficiently differentiated using state-of-the-art algorithms for algorithmic differentiation in forward and reverse modes and graph coloring techniques for generating complete, large and sparse Jacobians and Hessians.

The main purpose of the tool is to be a low-level tool for quick, yet highly efficient implementation of algorithms for nonlinear numerical optimization. Of particular interest is dynamic optimization, using either a collocation approach, or a shooting-based approach using embedded ODE/DAE-integrators. In either case, CasADi relieves the user from the work of efficiently calculating the relevant derivative or ODE/DAE sensitivity information to an arbitrary degree, as needed by the NLP solver. This together with a full-featured Python front end, as well as back ends to state-of-the-art codes such as Sundials (CVODES, IDAS and KINSOL), IPOPT, WORHP, SNOPT and KNITRO, drastically reduces the effort of implementing the methods compared to a pure C/C++/Fortran approach.

Every feature of CasADi (with very few exceptions) is available in C++ and Python with little to no difference in performance, so the user has the possibility of working completely in C++, Python or mixing the languages. We recommend new users to try out the Python version first, since it allows interactivity and is better documented than the C++ front-end.

CasADi is an open-source tool, written in self-contained C++ code, depending only on the C++ Standard Library. It is developed by Joel Andersson and Joris Gillis at the Optimization in Engineering Center, OPTEC of the K.U. Leuven under supervision of Moritz Diehl. CasADi is distributed under the LGPL license, meaning the code can be used royalty-free even in commercial applications.
