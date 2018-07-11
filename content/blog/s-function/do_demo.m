import casadi.*

x = MX.sym('x',2);
y = MX.sym('y');

w = dot(x,y*x);
z = sin(x)+y+w;

% CasADi function with two inputs and two outputs
f = Function('f',{x,y},{w,z});

% Use the numeric types from simulink to codegenerate
cg_options = struct;
cg_options.casadi_real = 'real_T';
cg_options.casadi_int = 'int_T';
cg_options.with_header = true;
cg = CodeGenerator('f',cg_options);
cg.add_include('simstruc.h');
cg.add(f);
cg.generate();

disp('CasADi codegen completed: created f.c')

%%
pause(1)

disp('Compiling S function')
mex s_function.c f.c

%%
open_system('demo')

