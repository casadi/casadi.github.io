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
