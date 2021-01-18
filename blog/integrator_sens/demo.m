close all
clear all
import casadi.*

% Trebuchet

a = 1;    % Front beam length [m]
b = 0.25;    % Back beam length [m]
h = 1;    % Pivot height [m]
M = 100;  % Counterweight mass [kg]
m = 1;    % Projectile mass [kg]
I = 1;    % Rotational inertia
mb = 1;
l = 0.7;
L = 0.5;

g = 9.81;

% States
p = SX.sym('p',2);
dp = SX.sym('dp',2);
phi = SX.sym('phi'); % Main beam angle
dphi = SX.sym('dphi');
theta = SX.sym('theta');
dtheta = SX.sym('dtheta');


q = [p;phi;theta];
dq = [dp;dphi;dtheta];
ddq = SX.sym('ddq',4);

pA = [0;h]-a*[cos(phi);sin(phi)];
pB = [0;h]+b*[cos(phi);sin(phi)];
pM = pB + L*[cos(theta);sin(theta)];

nx = 8;

vM = jtimes(pM,q,dq);


pC = (pA+pB)/2;



E_kin = 0.5*m*dp'*dp+0.5*M*vM'*vM+1e-8*0.5*I*dtheta^2;
E_pot = m*p(2)*g+M*pM(2)*g+mb*pC(2)*g;


constr = [sumsqr(pA-p)-l^2;p(2)];
lam = SX.sym('lam',2);

Lag = E_kin - E_pot;

eq = jtimes(gradient(Lag,dq),[q;dq],[dq;ddq]) - gradient(Lag,q) - jtimes(constr,q,lam,true);

% Write ddq as function of q,dq,u
ddqsol = -jacobian(eq,ddq)\substitute(eq,ddq,0);

T = SX.sym('T');

dae1 = struct('x',[q;dq], 'p',T, 'ode',T*[dq;ddqsol], 'z', lam, 'alg', constr);

eq = jtimes(gradient(Lag,dq),[q;dq],[dq;ddq]) - gradient(Lag,q) - jtimes(constr(1),q,lam(1),true);
ddqsol = -jacobian(eq,ddq)\substitute(eq,ddq,0);

dae2 = struct('x',[q;dq], 'p',T, 'ode',T*[dq;ddqsol], 'z', lam(1), 'alg', constr(1));

eq = jtimes(gradient(Lag,dq),[q;dq],[dq;ddq]) - gradient(Lag,q);
ddqsol = -jacobian(eq,ddq)\substitute(eq,ddq,0);

dae3 = struct('x',[q(1:2);dq(1:2)], 'p',T,  'ode',T*[dq(1:2);ddqsol(1:2)]);

theta0 = atan(2);

% Find consistent initial equations
rf = rootfinder('rf','newton',struct('x',p,'p',phi,'g',constr));
res = rf('x0',[0;0],'p',theta0);

p0 = res.x;

%%
opts = struct('tf',1);
intg1 = integrator('intg1','collocation', dae1, struct('number_of_finite_elements',5));
intg2 = integrator('intg2','collocation', dae2, struct('number_of_finite_elements',40));
intg3 = integrator('intg3','collocation', dae3, struct('number_of_finite_elements',1));
x0 = [p0;theta0;-pi/2;0;0;0;0];
res = intg1('x0',x0,'p',0.2);


%%
T = MX.sym('T');
res = intg1('x0',x0,'p',T);
rf = rootfinder('rf','newton',struct('x',T,'g',res.zf(2)));
res = rf('x0',0.2);
T12 = res.x;

T12_guess = T12;
T23_guess = T12_guess+0.3;
Tf_guess = T23_guess+3;
%%

x1 = getfield(intg1('x0',x0,'p',T12),'xf');

x2 = getfield(intg2('x0',x1,'p',0.3),'xf');

x3 = getfield(intg3('x0',[x2(1:2);x2(5:6)],'p',3),'xf');


%%

h = Function('h',{[q;dq]},{p,pA,pB,pM});
h = returntypes('full',h);
Nsim = 20;

figure(2)
clf
xlim([-2 2])
ylim([0 4])
axis equal

lam = zeros(2,Nsim);
x = x0;
states = zeros(nx,Nsim+1);
states(:,1) = full(x0);
for k=1:Nsim
    res = intg1('x0',x,'p',T12/Nsim);
    x = res.xf;
    [p_num,pA_num,pB_num,pM_num] = h(x);
    figure(2)
    hold on
    plot([p_num(1) pA_num(1)],[p_num(2) pA_num(2)],'b')
    plot([pA_num(1) pB_num(1)],[pA_num(2) pB_num(2)],'r')
    plot([pM_num(1) pB_num(1)],[pM_num(2) pB_num(2)],'k')
    states(:,k+1) = full(x);
    lam(:,k) = full(res.zf);
end
states(:,Nsim+1) = full(x);

figure(1)
plot(states(1:4,:)')

for k=1:Nsim
    res = intg2('x0',x,'p',(T23_guess-T12_guess)/Nsim);
    x = res.xf;
    [p_num,pA_num,pB_num,pM_num] = h(x);
    figure(2)
    hold on
    plot([p_num(1) pA_num(1)],[p_num(2) pA_num(2)],'b')
    plot([pA_num(1) pB_num(1)],[pA_num(2) pB_num(2)],'r')
    plot([pM_num(1) pB_num(1)],[pM_num(2) pB_num(2)],'k')
    states(:,k+1) = full(x);
    lam(:,k) = full(res.zf);
end

figure(3)
hold on

x = [x(1:2);x(5:6)];
for k=1:Nsim
    p_prev = full(x(1:2));
    res = intg3('x0',x,'p',(Tf_guess-T23_guess)/Nsim);
    x = res.xf;
    p_num = full(x(1:2));
    hold on
    plot([p_prev(1) p_num(1)],[p_prev(2) p_num(2)],'-ok')
end
axis equal

legend('px','py','phi','theta')
%%
opti = casadi.Opti();

T12 = T12_guess;
%T12 = opti.variable();
%opti.set_initial(T12, T12_guess);
T23 = opti.variable();
opti.set_initial(T23, T23_guess);
Tf  = opti.variable();
opti.set_initial(Tf, Tf_guess);

%opti.subject_to(0.9*T12_guess<=T12<= 1.1*T12_guess);
%opti.subject_to(0.9*T23_guess<=T23<= 1.1*T23_guess);
%opti.subject_to(0.9*Tf_guess<=Tf<= 1.1*Tf_guess);

res = intg1('x0',x0,'p',T12);
%opti.subject_to(res.zf(2)==0);
%opti.subject_to(res.zf(1)<=0);
x1 = res.xf;

res = intg2('x0',x1,'p',T23-T12);
opti.subject_to(res.zf<=0);
x2 = res.xf;

opti.subject_to(x2(5:6)>=0);

x3 = getfield(intg3('x0',[x2(1:2);x2(5:6)],'p',Tf-T23),'xf');

opti.minimize(-x3(1));
%opti.subject_to(T12>=0);
opti.subject_to(x3(2)==0);
opti.subject_to(T23>=T12);
opti.subject_to(10>=Tf>=T23);



%opti.solver('ipopt',struct('expand',false,'monitor',{'nlp_f'}),struct('hessian_approximation','limited-memory'));
opti.solver('ipopt',struct('expand',false));
sol = opti.solve(); 



%T12 = sol.value(T12);
T23 = sol.value(T23);
Tf = sol.value(Tf);
%%
h = Function('h',{[q;dq]},{p,pA,pB,pM});
h = returntypes('full',h);
Nsim = 20;

figure(2)
clf
xlim([-2 2])
ylim([0 4])
axis equal

lam = zeros(2,Nsim);
x = x0;
states = zeros(nx,Nsim+1);
states(:,1) = full(x0);
for k=1:Nsim
    res = intg1('x0',x,'p',T12/Nsim);
    x = res.xf;
    [p_num,pA_num,pB_num,pM_num] = h(x);
    figure(2)
    hold on
    plot([p_num(1) pA_num(1)],[p_num(2) pA_num(2)],'b')
    plot([pA_num(1) pB_num(1)],[pA_num(2) pB_num(2)],'r')
    plot([pM_num(1) pB_num(1)],[pM_num(2) pB_num(2)],'k')
    states(:,k+1) = full(x);
    lam(:,k) = full(res.zf);
end
states(:,Nsim+1) = full(x);

figure(1)
plot(states(1:4,:)')

for k=1:Nsim
    res = intg2('x0',x,'p',(T23-T12)/Nsim);
    x = res.xf;
    [p_num,pA_num,pB_num,pM_num] = h(x);
    figure(2)
    hold on
    plot([p_num(1) pA_num(1)],[p_num(2) pA_num(2)],'b')
    plot([pA_num(1) pB_num(1)],[pA_num(2) pB_num(2)],'r')
    plot([pM_num(1) pB_num(1)],[pM_num(2) pB_num(2)],'k')
    states(:,k+1) = full(x);
    lam(:,k) = full(res.zf);
end

figure(3)
hold on

x = [x(1:2);x(5:6)];
for k=1:Nsim
    p_prev = full(x(1:2));
    res = intg3('x0',x,'p',(Tf-T23)/Nsim);
    x = res.xf;
    p_num = full(x(1:2));
    hold on
    plot([p_prev(1) p_num(1)],[p_prev(2) p_num(2)],'-ok')
end
axis equal

legend('px','py','phi','theta')