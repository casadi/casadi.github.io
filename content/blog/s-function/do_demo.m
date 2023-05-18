import casadi.*

x = MX.sym('x',2);
y = MX.sym('y');

w = dot(x,y*x);
z = sin(x)+y+w;

solver = nlpsol('solver','sqpmethod',struct('x',y,'f',y^2),struct('qpsol','qrqp'));

res = solver('x0',y);
% CasADi function with two inputs and two outputs
f = Function('f',{x,y},{w,z+res.x});

% Use the numeric types from simulink to codegenerate
cg_options = struct;
cg_options.casadi_real = 'real_T';
cg_options.real_min    = num2str(realmin); % Needed if you code-generate sqpmethod method  
cg_options.casadi_int  = 'int_T';
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

