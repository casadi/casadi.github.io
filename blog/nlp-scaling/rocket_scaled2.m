N = 100; % number of control intervals
T = 100; % Time horizon [s]
dt = T/N;
m0 = 500000; % start mass [kg]
yT = 100000; % final height [m]
g = 9.81; % gravity 9.81 [m/s^2]
alpha = 1/(300*g); % kg/(N*s);

opti = casadi.Opti();

y_nom = 1e5;
v_nom = 2000;
m_nom = 300e3;
x_nom = [y_nom;v_nom;m_nom];
u_nom = 1e8;

% Decision variables [height;velocity;mass]
x =  repmat(x_nom,1,N+1).*opti.variable(3,N+1);
y = x(1,:); % height
v = x(2,:); % velocity
m = x(3,:); % mass
u = u_nom*opti.variable(1,N); % Control vector

% Dynamic constraints
rocket_ode = @(x,u) [x(2);u/x(3)-g;-alpha*u];

for k = 1:N
    opti.subject_to(x(:,k+1)./x_nom == (x(:,k) + rocket_ode(x(:,k),u(:,k))*dt)./x_nom);
end

% Boundary conditions
opti.subject_to(x(:,1)./x_nom == [0;0;m0]./x_nom);
opti.subject_to(y(N+1)/y_nom==yT/y_nom);

% Path constranits
opti.subject_to(m/m_nom >= 0); % Mass must be positive
opti.subject_to(u/u_nom >= 0); % Control must remain positive

% Objective
opti.minimize((m(1)-m(N+1))/m_nom); % minimize fuel consumption

% Solve
opti.set_initial(x(3,:),100000); % Initial guess for mass
opti.solver('ipopt',struct,struct('nlp_scaling_method','none'));

sol = opti.solve();

diagnostics
