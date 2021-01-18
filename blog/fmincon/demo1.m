%   Solve
% 
%   min  sin(x)^2
%    x


% Pure Matlab
fminunc(@(x) sin(x)^2, 0.1)

% With CasADi objective
import casadi.*
x = MX.sym('x');
y = sin(x)^2;

f = Function('f',{x},{y});

fminunc(@(x) full(f(x)), 0.1)

% With CasADi objective and gradient
fg = Function('fg',{x},{y,gradient(y,x)});
fg_full = returntypes('full',fg);

options = optimoptions('fminunc','SpecifyObjectiveGradient',true);
fminunc(@(x) fg_full(x), 0.1, options)