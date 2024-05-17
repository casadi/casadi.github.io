---
title: Matlab coder meets CasADi codegen
author: jg
tags: matlab
date: 2024-05-17
image: matlab-coder.png
---

In this post we show how CasADi codegen can be integrated seemlessly with Matlab Coder.
Matlab Coder is capable of transforming a Matlab function into C code.
CasADi codegen is somewhat similar: it generates C code out of a CasADi Function.

# Some context

Running CasADi generated code inside a mex file is nothing new.
Indeed, it has been  [featured in the user guide](https://web.casadi.org/docs/#syntax-for-generating-code) for many years.
Calls to such a mex file would play nicely with Matlab Coder out-of-the-box.

# Rationale

Keeping related pieces of code together one m-script may make your code project more maintainable.
Here is an example piece of code that mixes CasADi and regular matlab operations, inspired by [the Ipopt codegen demo](https://github.com/casadi/micro_demo_ipopt_codegen)
```matlab
function [area_sol, center_sol] = fun_interpreted(a)

opti   = casadi.Opti();

center = opti.variable(2);
radius = opti.variable();

opti.minimize(-radius);

% Sample edge vertices
ts = linspace(0, 2*pi, 1000);
v_x = radius*cos(ts)+center(1);
v_y = radius*sin(ts)+center(2);

opti.subject_to(v_x>=0);
p = interp1([0,1,2],[0,3,9],a);
opti.subject_to(v_y>=p*sqrt(v_x));
opti.subject_to(v_x.^2+v_y.^2<=1);

opti.set_initial(center, [0.5, 0.5]);

opti.solver('ipopt');

sol = opti.solve();

area_sol = sol.value(pi*radius^2);
center_sol = sol.value(center);

end
```

Wouldn't it be nice if we could just ask Matlab Coder to generate the mex file for us?
```matlab
codegen fun_interpreted -args {zeros(1,1)}
```
Unfortunately, we are greeted by a somewhat cryptic error message:

```
??? Diamond-shape inheritance is not supported in code generation. Class 'casadi.Opti' inherits from base class 'SwigRef' via two or more
paths.
Error in ==> Opti Line: 1460 Column: 7
Code generation failed: View Error Report
```
Matlab coder is trying (and failing) to dump the entire CasADi class hierarchy into C.

How do we fix this?

# Step 1

The first step we need to do is to make sure we get our hands on a CasADi Function `F` which we can later code-generate:

```
function [area_sol, center_sol] = fun_intermediate(a)

% Any pre-processing using pure Matlab operations can go here
p_value = interp1([0,1,2],[0,3,9],a);

% Anything CasADi related goes here
opti   = casadi.Opti();

center = opti.variable(2);
radius = opti.variable();

p = opti.parameter();

opti.minimize(-radius);

% Sample edge vertices
ts = linspace(0, 2*pi, 1000);
v_x = radius*cos(ts)+center(1);
v_y = radius*sin(ts)+center(2);

opti.subject_to(v_x>=0);
opti.subject_to(v_y>=p*sqrt(v_x));
opti.subject_to(v_x.^2+v_y.^2<=1);

opti.set_initial(center, [0.5, 0.5]);

opti.solver('ipopt');

% Create a CasADi Function
F = opti.to_function('F',{p},{radius, center});
        
[radius_sol,center_sol] = F(p_value);

% Any post-processing using pure Matlab operations can go here

area_sol = pi*radius_sol^2;

end
```

At the same time, we also moved some code around to get a split-up between pure Matlab portions of code (pre-processing and post-processing) and CasADi portions of code.

# Step 2
In the next step, we introduce a `coder.target('MATLAB')` if-test around any CasADi portion of code.
Most of the code below can just be copy-pasted for your project.
The most important project-specific part is marked with '% Adapt'.
```matlab
function [area_sol, center_sol] = fun_codable(a)

% Any pre-processing using pure Matlab operations can go here
p_value = interp1([0,1,2],[0,3,9],a);

% Make sure data-types and sizes are known
radius_sol = 0;
center_sol = zeros(2,1);

% Anything CasADi related goes here
if coder.target('MATLAB')
    % Normal CasADi usage + CasADi codegen
     
    opti   = casadi.Opti();

    ...

    % Codegen via a CasADi Function
    F = opti.to_function('F',{p},{radius, center});
    [radius_sol,center_sol] = F(p_value);

    % Generate C code
    F.generate('F.c',struct('unroll_args',true,'with_header',true));

    % Generate meta-data
    config = struct;
    config.sz_arg = F.sz_arg();
    config.sz_res = F.sz_res();
    config.sz_iw = F.sz_iw();
    config.sz_w = F.sz_w();
    config.include_path = casadi.GlobalOptions.getCasadiIncludePath;
    config.path = casadi.GlobalOptions.getCasadiPath;
    if ismac
      config.link_library_suffix = '.dylib';
      config.link_library_prefix = 'lib';
    elseif isunix
      config.link_library_suffix = '.so';
      config.link_library_prefix = 'lib';
    elseif ispc
      config.link_library_suffix = '.lib';
      config.link_library_prefix = '';
    end
    save('F_config.mat','-struct','config');
else
    % This gets executed when Matlab Coder is parsing the file
    % Hooks up Matlab Coder with CasADi generated C code

    % Connect .c and .h file
    coder.cinclude('F.h');
    coder.updateBuildInfo('addSourceFiles','F.c');
    
    % Set link and include path
    config = coder.load('F_config.mat');
    coder.updateBuildInfo('addIncludePaths',config.include_path)
    
    % Link with IPOPT
    coder.updateBuildInfo('addLinkObjects', [config.link_library_prefix 'ipopt' config.link_library_suffix], config.path, '', true, true);

    % Setting up working space
    arg = coder.opaque('const casadi_real*');
    res = coder.opaque('casadi_real*');
    iw = coder.opaque('casadi_int');
    w = coder.opaque('casadi_real');


    arg = coder.nullcopy(cast(zeros(config.sz_arg,1),'like',arg));
    res = coder.nullcopy(cast(zeros(config.sz_res,1),'like',res));
    iw  = coder.nullcopy(cast(zeros(config.sz_iw,1),'like',iw));
    w   = coder.nullcopy(cast(zeros(config.sz_w,1),'like',w));

    mem = int32(0);
    flag= int32(0);
    mem = coder.ceval('F_checkout');
    
    % Call the generated CasADi code
    flag=coder.ceval('F_unrolled',...
        coder.rref(p_value), ... % Adapt to as many inputs arguments as your CasADi Function has
        coder.wref(radius_sol), coder.wref(center_sol), ... % Adapt to as many outputs as your CasADi Function has
        arg, res, iw, w, mem); % 
    coder.ceval('F_release', mem);
end

% Any post-processing using pure Matlab operations can go here
area_sol = pi*radius_sol^2;

end
```
Please see the inline comments for explanations of the various parts.
Note that `F_unrolled` is a variant of `F` added in CasADi 3.6.5 specifically to make the Malab Coder integration easier.

# Results

The result is a Matlab function that can be handled by Matlab Coder:
```matlab
codegen fun_codable -args {zeros(1,1)}

% Call the geneated mex function
fun_codable_mex(0.5)
```

At the same time, the code can stil be run/debugged in interpreted mode and is still close to the original `fun_interpreted.m` file.

Using `coder.target('MATLAB')`, the Simulink system block of [the MPC blog post](https://web.casadi.org/blog/mpc-simulink/) could be modified and made compatible with embedded targets.

Downloads: [demo.m](demo.m), [fun_codable.m](fun_codable.m), [fun_interpreted.m](fun_interpreted.m), [fun_intermediate.m](fun_intermediate.m)


