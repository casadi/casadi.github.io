clc
clear all
close all

N = 40;
m = 40/N;
D = 70*N;
g = 9.81;
L = 1;

% Set up optimization environment
opti = casadi.Opti();


% Problem 1: Simple hanging chain
% Decision variables: positions
p = opti.variable(2,N);
x = p(1,:);
y = p(2,:);

V = 0.5*D*sum((x(1:N-1)-x(2:N)).^2+(y(1:N-1)-y(2:N)).^2);
V = V + g*sum(m*y);

opti.minimize(V);

opti.subject_to(p(:,1)==[-2;1])
opti.subject_to(p(:,end)==[2;1])

opti.solver('ipopt');
sol = opti.solve();

% Plotting the results
plot(sol.value(x),sol.value(y),'-o')
print('chain1','-dpng')

% Problem 2: adding ground constraints

% Add constraint to the already existing problem
opti.subject_to(y>=cos(0.1*x)-0.5);
sol = opti.solve();

% Plotting the results
figure
hold on
plot(sol.value(x),sol.value(y),'-o')
xs = linspace(-2,2,1000);
plot(xs,cos(0.1*xs)-0.5,'--r')
print('chain2','-dpng')


% Problem 2: Rest Length
V = 0.5*sum(D*(sqrt((x(1:N-1)-x(2:N)).^2+(y(1:N-1)-y(2:N)).^2)-L/N).^2);
V = V + g*sum(m*y);

opti.minimize(V);

opti.set_initial(x,linspace(-2,2,N));
opti.set_initial(y,1);

sol = opti.solve();

% Plotting the results
figure
hold on
plot(sol.value(x),sol.value(y),'-o')
xs = linspace(-2,2,1000);
plot(xs,cos(0.1*xs)-0.5,'--r')
print('chain3','-dpng')


figure()
hold on
opti.callback(@(i) plot(opti.debug.value(x),opti.debug.value(y),'DisplayName',num2str(i)))
sol = opti.solve();
title('Intermediate solution for different iterations');
legend('show','Location','north')
print('chain4','-dpng')
