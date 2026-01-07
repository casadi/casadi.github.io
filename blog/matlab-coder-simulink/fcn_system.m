classdef fcn_system < matlab.System

    properties (Access = private, Nontunable)
        name
        src_name
    end

    properties (Access = private)
        F
    end

    methods (Access = protected)

        function num = getNumInputsImpl(obj)
                obj.name = 'foo';
                obj.src_name = 'bar';
                obj.F = 0;
                if coder.target('MATLAB')
                    
                    sol = 0;
                    % Anything CasADi related goes here
                    % Normal CasADi usage + CasADi codegen
                
                    disp('target = MATLAB')
                     
                    opti   = casadi.Opti();
                
                    x = opti.variable();
                
                    p = opti.parameter();
                
                    opti.minimize((x-p).^2);
                
                    opti.subject_to(-10<=x<=10);
                
                    opti.solver('fatrop');
                
                    % Codegen via a CasADi Function
                    F = opti.to_function(obj.name,{p},{x});

                    obj.F = F;
                
                    % Generate C code
                    F.generate([obj.src_name '.c'],struct('unroll_args',true,'with_header',true,'thread_safe',true));
                
                    % Generate meta-data
                    config = struct;
                    config.sz_arg = F.sz_arg();
                    config.sz_res = F.sz_res();
                    config.sz_iw = F.sz_iw();
                    config.sz_w = F.sz_w();
                    config.include_path = casadi.GlobalOptions.getCasadiIncludePath;
                    config.path = casadi.GlobalOptions.getCasadiPath;
                    if ismac
                      config.link_library_suffix = '.dylib';
                      config.link_library_prefix = 'lib';
                    elseif isunix
                      config.link_library_suffix = '.so';
                      config.link_library_prefix = 'lib';
                    elseif ispc
                      config.link_library_suffix = '.lib';
                      config.link_library_prefix = '';
                    end
                    save([obj.src_name '_config.mat'],'-struct','config');
            end

            num = 1;
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
            disp('setupImpl')


            if coder.target('MATLAB')
               
            else
                coder.ceval([obj.name '_incref']);
            end

        end

        function u = stepImpl(obj,x,t)
            disp('stepImpl')
            if coder.target('MATLAB')
                F = obj.F;
                u = full(F(x));
            else
                u = 0.0;
                disp(['target2 = ' coder.target])
                % This gets executed when Matlab Coder is parsing the file
                % Hooks up Matlab Coder with CasADi generated C code
            
                % Connect .c and .h file
                coder.cinclude([obj.src_name '.h']);
                coder.updateBuildInfo('addSourceFiles',[obj.src_name '.c']);
                
                % Set link and include path
                config = coder.load([obj.src_name '_config.mat']);
                coder.updateBuildInfo('addIncludePaths',config.include_path)
                
                % Link with IPOPT
                coder.updateBuildInfo('addLinkObjects', [config.link_library_prefix 'fatrop' config.link_library_suffix], config.path, 1000, true, true);
                coder.updateBuildInfo('addLinkObjects', [config.link_library_prefix 'blasfeo' config.link_library_suffix], config.path, 1000, true, true);
                coder.updateBuildInfo('addLinkFlags', ['-Wl,-rpath,' config.path]);

                coder.updateBuildInfo('addDefines','CASADI_MAX_NUM_THREADS=2');
                coder.updateBuildInfo('addDefines','CASADI_THREAD_TYPE=CASADI_THREAD_TYPE_POSIX');

                % Setting up working space
                arg = coder.opaque('const casadi_real*');
                res = coder.opaque('casadi_real*');
                iw = coder.opaque('casadi_int');
                w = coder.opaque('casadi_real');
            
                arg = coder.nullcopy(cast(zeros(config.sz_arg,1),'like',arg));
                res = coder.nullcopy(cast(zeros(config.sz_res,1),'like',res));
                iw  = coder.nullcopy(cast(zeros(config.sz_iw,1),'like',iw));
                w   = coder.nullcopy(cast(zeros(config.sz_w,1),'like',w));
            
                mem = int32(0);
                flag= int32(0);
                mem = coder.ceval([obj.name '_checkout']);
                
                % Call the generated CasADi code
                flag=coder.ceval([obj.name '_unrolled'],...
                    coder.rref(x), ... % Adapt to as many inputs arguments as your CasADi Function has
                    coder.wref(u), ... % Adapt to as many outputs as your CasADi Function has
                    arg, res, iw, w, mem); % 
                coder.ceval([obj.name '_release'], mem);
            end
        end

        function releaseImpl(obj)
            disp('releaseImpl')
            if coder.target('MATLAB')

            else
                coder.ceval([obj.name '_decref']);
            end
        end
    end
end
