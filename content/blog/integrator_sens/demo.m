close all
clear all
import casadi.*

% Trebuchet

a = 1;    % Front beam length [m]
b = 1;    % Back beam length [m]
h = 1;    % Pivot height [m]
M = 100;  % Counterweight mass [kg]
m = 1;    % Projectile mass [kg]
I = 1;    % Rotational inertia
mb = 1;
l = 0.7;
L = 0.2;

g = 9.81;

% States
p = SX.sym('p',2);
dp = SX.sym('dp',2);
phi = SX.sym('phi');
dphi = SX.sym('dphi');
theta = SX.sym('theta');
dtheta = SX.sym('dtheta');


q = [p;phi;theta];
dq = [dp;dphi;dtheta];
ddq = SX.sym('ddq',4);

pA = [0;h]-a*[cos(phi);sin(phi)];
pB = [0;h]+b*[cos(phi);sin(phi)];
pM = pB + L*[cos(theta);sin(theta)];


vM = jtimes(pM,q,dq);


pC = (pA+pB)/2;



E_kin = 0.5*m*dp'*dp+0.5*M*vM'*vM+0.5*I*dtheta^2;
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

dae3 = struct('x',[q;dq], 'p',T,  'ode',T*[dq;ddqsol]);

theta0 = 3*pi/4;

% Find consistent initial equations
rf = rootfinder('rf','newton',struct('x',p,'p',phi,'g',constr));
res = rf('x0',[0;0],'p',theta0);

p0 = res.x;

opts = struct('tf',1);
intg1 = integrator('intg1','collocation', dae1, struct('number_of_finite_elements',20));
intg2 = integrator('intg2','collocation', dae2, struct('number_of_finite_elements',100));
intg3 = integrator('intg3','collocation', dae3, struct('number_of_finite_elements',20));
x0 = [p0;theta0;-pi/2;0;0;0;0];
res = intg1('x0',x0,'p',0.2);

T = MX.sym('T');
res = intg1('x0',x0,'p',T);
rf = rootfinder('rf','newton',struct('x',T,'g',res.zf(2)));
res = rf('x0',0.2);
T12 = res.x;

%%

x1 = getfield(intg1('x0',x0,'p',T12),'xf');

x2 = getfield(intg2('x0',x1,'p',0.2),'xf')

x3 = getfield(intg3('x0',x2,'p',0.1),'xf');

%%
opti = casadi.Opti();

T23 = opti.variable();
Tf  = opti.variable();

x1 = getfield(intg1('x0',[p0;theta0;-pi/2;0;0;0;0],'p',T12),'xf');

x2 = getfield(intg2('x0',x1,'p',T23-T12),'xf');

x3 = getfield(intg3('x0',x2,'p',Tf-T23),'xf');

opti.minimize(-x3(1));
opti.subject_to(x3(2)==0);
opti.subject_to(T23>=T12);
opti.subject_to(Tf>=T23);

opti.solver('ipopt');

sol = opti.solve();


