classdef casadi_block < matlab.System & matlab.system.mixin.Propagates
    % untitled Add summary here
    %
    % This template includes the minimum set of functions required
    % to define a System object with discrete state.

    properties
        % Public, tunable properties.

    end

    properties (DiscreteState)
    end

    properties (Access = private)
        % Pre-computed constants.
        casadi_solver
        x0
        lbx
        ubx
        lbg
        ubg
        name
    end

    methods (Access = protected)
        function num = getNumInputsImpl(~)
            num = 2;
        end
        function num = getNumOutputsImpl(~)
            num = 1;
        end
        function dt1 = getOutputDataTypeImpl(~)
        	dt1 = 'double';
        end
        function dt1 = getInputDataTypeImpl(~)
        	dt1 = 'double';
        end
        function sz1 = getOutputSizeImpl(~)
        	sz1 = [1,1];
        end
        function sz1 = getInputSizeImpl(~)
        	sz1 = [1,1];
        end
        function cp1 = isInputComplexImpl(~)
        	cp1 = false;
        end
        function cp1 = isOutputComplexImpl(~)
        	cp1 = false;
        end
        function fz1 = isInputFixedSizeImpl(~)
        	fz1 = true;
        end
        function fz1 = isOutputFixedSizeImpl(~)
        	fz1 = true;
        end
        function setupImpl(obj,~,~)
            % Implement tasks that need to be performed only once, 
            % such as pre-computed constants.
            
            import casadi.*

            T = 10; % Time horizon
            N = 20; % number of control intervals

            % Declare model variables
            x1 = SX.sym('x1');
            x2 = SX.sym('x2');
            x = [x1; x2];
            u = SX.sym('u');

            % Model equations
            xdot = [(1-x2^2)*x1 - x2 + u; x1];

            % Objective term
            L = x1^2 + x2^2 + u^2;

            % Continuous time dynamics
            f = casadi.Function('f', {x, u}, {xdot, L});

            % Formulate discrete time dynamics
            % Fixed step Runge-Kutta 4 integrator
            M = 4; % RK4 steps per interval
            DT = T/N/M;
            f = Function('f', {x, u}, {xdot, L});
            X0 = MX.sym('X0', 2);
            U = MX.sym('U');
            X = X0;
            Q = 0;
            for j=1:M
               [k1, k1_q] = f(X, U);
               [k2, k2_q] = f(X + DT/2 * k1, U);
               [k3, k3_q] = f(X + DT/2 * k2, U);
               [k4, k4_q] = f(X + DT * k3, U);
               X=X+DT/6*(k1 +2*k2 +2*k3 +k4);
               Q = Q + DT/6*(k1_q + 2*k2_q + 2*k3_q + k4_q);
            end
            F = Function('F', {X0, U}, {X, Q}, {'x0','p'}, {'xf', 'qf'});

            % Start with an empty NLP
            w={};
            w0 = [];
            lbw = [];
            ubw = [];
            J = 0;
            g={};
            lbg = [];
            ubg = [];

            % "Lift" initial conditions
            X0 = MX.sym('X0', 2);
            w = {w{:}, X0};
            lbw = [lbw; 0; 1];
            ubw = [ubw; 0; 1];
            w0 = [w0; 0; 1];

            % Formulate the NLP
            Xk = X0;
            for k=0:N-1
                % New NLP variable for the control
                Uk = MX.sym(['U_' num2str(k)]);
                w = {w{:}, Uk};
                lbw = [lbw; -1];
                ubw = [ubw;  1];
                w0 = [w0;  0];

                % Integrate till the end of the interval
                Fk = F('x0', Xk, 'p', Uk);
                Xk_end = Fk.xf;
                J=J+Fk.qf;

                % New NLP variable for state at end of interval
                Xk = MX.sym(['X_' num2str(k+1)], 2);
                w = {w{:}, Xk};
                lbw = [lbw; -0.25; -inf];
                ubw = [ubw;  inf;  inf];
                w0 = [w0; 0; 0];

                % Add equality constraint
                g = {g{:}, Xk_end-Xk};
                lbg = [lbg; 0; 0];
                ubg = [ubg; 0; 0];
            end

            % Create an NLP solver
            prob = struct('f', J, 'x', vertcat(w{:}), 'g', vertcat(g{:}));
            options = struct('ipopt',struct('print_level',0),'print_time',false);
            
            obj.name = 'solver';
            solver = nlpsol(obj.name, 'ipopt', prob, options);

            % Generate C code
            solver.generate([obj.name '.c'],struct('unroll_args',true,'with_header',true));
	
            % Generate meta-data
            config = struct;
            config.sz_arg = solver.sz_arg();
            config.sz_res = solver.sz_res();
            config.sz_iw = solver.sz_iw();
            config.sz_w = solver.sz_w()+1;
            config.include_path = casadi.GlobalOptions.getCasadiIncludePath;
            config.path = casadi.GlobalOptions.getCasadiPath;
            if ismac
              config.link_library_suffix = '.dylib';
            elseif isunix
              config.link_library_suffix = '.so';
            elseif ispc
              config.link_library_suffix = '.lib';
            end
            save([obj.name '_config.mat'],'-struct','config');

            obj.casadi_solver = solver;
            obj.x0 = w0;
            obj.lbx = lbw;
            obj.ubx = ubw;
            obj.lbg = lbg;
            obj.ubg = ubg;
        end

        function u = stepImpl(obj,x,t)
            disp(t)
            tic
            w0 = obj.x0;
            lbw = obj.lbx;
            ubw = obj.ubx;

            lbw(1:2) = x;
            ubw(1:2) = x;

            lam_x0 = zeros(numel(obj.lbx),1);
            lam_g0 = zeros(numel(obj.lbg),1);
            sol_x = zeros(numel(obj.lbx),1);
            sol_f = 0;
            sol_g = zeros(numel(obj.lbg),1);
            sol_lam_x = zeros(numel(obj.lbx),1);
            sol_lam_g = zeros(numel(obj.lbg),1);
            sol_lam_p = zeros(numel(p),1);
            p = 0;

            if coder.target('MATLAB')
            	solver = obj.casadi_solver;
            	sol = solver('x0', w0, 'lbx', lbw, 'ubx', ubw,...
                        'lbg', obj.lbg, 'ubg', obj.ubg);
              sol_x = full(sol.x);
            else
              config = coder.load([obj.name '_config.mat']);
              coder.cinclude([obj.name '.h']);

              coder.updateBuildInfo('addSourceFiles',[obj.name '.c']);
              coder.updateBuildInfo('addIncludePaths',config.include_path)
              coder.updateBuildInfo('addLinkObjects', ['ipopt' config.link_library_suffix], config.path, '', true, true);
              
              arg = coder.opaque('const casadi_real*');
              res = coder.opaque('casadi_real*');
              iw = coder.opaque('casadi_int');
              w = coder.opaque('casadi_real');
              
              arg = coder.nullcopy(cast(zeros(conf.sz_arg,1),'like',arg));
              res = coder.nullcopy(cast(zeros(conf.sz_res,1),'like',res));
              iw  = coder.nullcopy(cast(zeros(conf.sz_iw,1),'like',iw));
              w   = coder.nullcopy(cast(zeros(conf.sz_w,1),'like',w));

              mem = int32(0);
              flag= int32(0);
              mem = coder.ceval([obj.name '_checkout']);
              
              flag=coder.ceval([obj.name '_unrolled'],...
                coder.rref(w0), coder.rref(p),...
                coder.rref(lbw), coder.rref(ubw), coder.rref(obj.lbg), coder.rref(obj.ubg),...
                coder.rref(lam_x0), coder.rref(lam_g0),...
                coder.wref(sol_x), coder.wref(sol_f), coder.wref(sol_g),...
                coder.wref(sol_lam_x), coder.wref(sol_lam_g), coder.wref(sol_lam_p), arg, res, iw, w, mem);
              coder.ceval([obj.name '_release'], mem);
              
              printf("ipopt return flag %d \n", flag);
            end
  
            u = sol_x(3);
            toc
        end

        function resetImpl(obj)
            % Initialize discrete-state properties.
        end
    end
end
