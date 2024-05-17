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
