import casadi.*

%https://www.sciencedirect.com/science/article/pii/S2405896318327137

clear all
close all
opti = Opti();

x = opti.variable();
y = opti.variable();
xy = [x;y];

a = 0.2;
p = opti.parameter();

opti.minimize((1-x)^2 + a*(y-x^2)^2);
opti.subject_to(x>=0);
opti.subject_to((p/2)^2 <= (x+0.5)^2+y^2 <= p^2);

p_lins = [1.25,1.4,2];
c = {'r','g','b'};
n_lin = numel(p_lins);

% Use IPOPT to solve the nonlinear optimization
opts = struct;
opts.ipopt.print_level = 0;
opts.print_time = false;
opti.solver('ipopt',opts);

M = opti.to_function('M',{p},{xy});

figure
for i=1:3
    p_lin = p_lins(i);
    subplot(1,n_lin,i)
    plot_nlp([a,p_lin],M(p_lin))
    title(['p = ' num2str(p_lin)])
end
print('nlp_1d','-dpng')

z = @(xy) xy(2,:)-xy(1,:);

% How does the optimal solution vary along p?
pvec = linspace(1,2,100);
S = full(M(pvec));

figure
plot(pvec,z(S),'k.','MarkerSize',12);
ylabel('z')
xlabel('p')

print('nlp_sampled_1d','-dpng')
hold on

% Use SQPmethod + QRQP for accurate multipliers
opts = struct;
opts.qpsol = 'qrqp';
opts.qpsol_options.print_iter = false;
opts.print_status = false;
opts.print_iteration = false;
opts.print_time = false;
opti.solver('sqpmethod',opts);


Z = opti.to_function('Z',{p,xy},{z(xy)});


zp = Z(p,xy);
j = jacobian(zp,p);
h = hessian(zp,p);

Z_taylor = Function('Z_taylor',{p,xy},{zp,j,h});

t = linspace(1,2,1000);

for i=1:n_lin
    p0 = p_lins(i);
    [F,J,H] = Z_taylor(p0,M(p0));
    plot(p0,full(F),'x','linewidth',3,'color',c{i},'MarkerSize',16);
    plot(t,full(F+J*(t-p0)+1/2*H*(t-p0).^2),'linewidth',2,'color',c{i},'MarkerSize',16);
end



ylim([-0.6 0.2])

print('nlp_sens_1d','-dpng')




