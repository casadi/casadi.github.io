function [area_sol, center_sol] = fun_codable(a)

% Any pre-processing using pure Matlab operations can go here
p_value = interp1([0,1,2],[0,3,9],a);

% Make sure data-types and sizes are known
radius_sol = 0;
center_sol = zeros(2,1);

% Anything CasADi related goes here
if coder.target('MATLAB')
    % Normal CasADi usage + CasADi codegen
     
    opti   = casadi.Opti();

    center = opti.variable(2);
    radius = opti.variable();

    p = opti.parameter();

    opti.minimize(-radius);

    % Sample edge vertices
    ts = linspace(0, 2*pi, 1000);
    v_x = radius*cos(ts)+center(1);
    v_y = radius*sin(ts)+center(2);

    opti.subject_to(v_x>=0);
    opti.subject_to(v_y>=p*sqrt(v_x));
    opti.subject_to(v_x.^2+v_y.^2<=1);

    opti.set_initial(center, [0.5, 0.5]);

    opti.solver('ipopt');

    % Codegen via a CasADi Function
    F = opti.to_function('F',{p},{radius, center});
    [radius_sol,center_sol] = F(p_value);

    % Generate C code
    F.generate('F.c',struct('unroll_args',true,'with_header',true));

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
    save('F_config.mat','-struct','config');
else
    % This gets executed when Matlab Coder is parsing the file
    % Hooks up Matlab Coder with CasADi generated C code

    % Connect .c and .h file
    coder.cinclude('F.h');
    coder.updateBuildInfo('addSourceFiles','F.c');
    
    % Set link and include path
    config = coder.load('F_config.mat');
    coder.updateBuildInfo('addIncludePaths',config.include_path)
    
    % Link with IPOPT
    coder.updateBuildInfo('addLinkObjects', [config.link_library_prefix 'ipopt' config.link_library_suffix], config.path, '', true, true);

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
    mem = coder.ceval('F_checkout');
    
    % Call the generated CasADi code
    flag=coder.ceval('F_unrolled',...
        coder.rref(p_value), ... % Adapt to as many inputs arguments as your CasADi Function has
        coder.wref(radius_sol), coder.wref(center_sol), ... % Adapt to as many outputs as your CasADi Function has
        arg, res, iw, w, mem); % 
    coder.ceval('F_release', mem);
end

% Any post-processing using pure Matlab operations can go here
area_sol = pi*radius_sol^2;

end
