N = 100; % number of control intervals
T = 100; % Time horizon [s]
dt = T/N;
m0 = 500000; % start mass [kg]
yT = 100000; % final height [m]
g = 9.81; % gravity 9.81 [m/s^2]
alpha = 1/(300*g); % kg/(N*s);

opti = casadi.Opti();

% Decision variables [height;velocity;mass]
x =  repmat([1e5;2000;300e3],1,N+1).*opti.variable(3,N+1);
y = x(1,:); % height
v = x(2,:); % velocity
m = x(3,:); % mass
u = 1e8*opti.variable(1,N); % Control vector

% Dynamic constraints
rocket_ode = @(x,u) [x(2);u/x(3)-g;-alpha*u];

for k = 1:N
    opti.subject_to(x(:,k+1) == x(:,k) + rocket_ode(x(:,k),u(:,k))*dt);
end

% Boundary conditions
opti.subject_to(x(:,1) == [0;0;m0]);
opti.subject_to(y(N+1) == yT);

% Path constranits
opti.subject_to(m >= 0); % Mass must be positive
opti.subject_to(u >= 0); % Control must remain positive

% Objective
opti.minimize(m(1)-m(N+1)); % minimize fuel consumption

% Solve
opti.set_initial(x(3,:),100000); % Initial guess for mass
opti.solver('ipopt');

sol = opti.solve();

% Post-processing
t = linspace(0,T,N+1);

figure
stairs(t(1:end-1),sol.value(u))
xlabel('Time [s]')
ylabel('Thrust F [N]')
title('Controls')
print('controls','-dpng')

figure
subplot(311)
plot(t,sol.value(y)')
xlabel('Time [s]')
ylabel('Height [m]')
subplot(312)
plot(t,sol.value(v)')
xlabel('Time [s]')
ylabel('Speed [m/s]')
subplot(313)
plot(t,sol.value(m)')
ylabel('Mass [kg]')
xlabel('Time [s]')
title('States')


figure
semilogy(sol.stats.iterations.inf_du)
hold on
semilogy(sol.stats.iterations.inf_pr)

xlabel('Iteration number')
legend('Primal feasibility','Dual feasibility')
print('conv_scaled','-dpng')