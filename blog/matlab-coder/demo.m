% Interpreted pass (side effect of performing CasADi codegen)
fun_codable(0.5)

% Perform Matlab Coder step (links to CasADi generated code)
codegen fun_codable -args {zeros(1,1)}

% Call the geneated mex function
fun_codable_mex(0.5)