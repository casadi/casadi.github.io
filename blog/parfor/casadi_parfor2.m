N = 250;

fsol = zeros(1,N);
rs = linspace(1,3,N);

x = casadi.SX.sym('x');
y = casadi.SX.sym('y');

v = [x;y];
f = (1-x)^2+(y-x^2)^2;
g = x^2+y^2;
nlp = struct('x', v, 'f', f, 'g', g);

% Create IPOPT solver object
options = struct;
options.print_time = false;
options.ipopt.print_level = 0;
solver = casadi.nlpsol('solver', 'ipopt', nlp,options);

tic
parfor i=1:N
  % Solve the NLP
  res = solver('x0' , [2.5 3.0],...      % solution guess
               'lbx', -inf,...           % lower bound on x
               'ubx',  inf,...           % upper bound on x
               'lbg', -inf,...           % lower bound on g
               'ubg',  rs(i));           % upper bound on g
   
  
  % Store the solution
  fsol(i) = full(res.f);
end
toc

plot(rs,fsol,'o')