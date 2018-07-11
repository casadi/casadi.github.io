#define S_FUNCTION_NAME  s_function
#define S_FUNCTION_LEVEL 2

#include "simstruc.h"
#include "f.h"

static void mdlInitializeSizes(SimStruct *S)
{
    ssSetNumSFcnParams(S, 0);
    if (ssGetNumSFcnParams(S) != ssGetSFcnParamsCount(S)) {
        return; /* Parameter mismatch will be reported by Simulink */
    }

    /* Read in CasADi function dimensions */
    int_T n_in  = f_n_in();
    int_T n_out = f_n_out();
    int_T sz_arg, sz_res, sz_iw, sz_w;
    f_work(&sz_arg, &sz_res, &sz_iw, &sz_w);
    
    /* Set up simulink input/output ports */
    int_T i;
    if (!ssSetNumInputPorts(S, n_in)) return;
    for (i=0;i<n_in;++i) {
      const int_T* sp = f_sparsity_in(i);
      /* Dense vector inputs assumed here */
      ssSetInputPortWidth(S, i, sp[0]);
      ssSetInputPortDirectFeedThrough(S, i, 1);
    }

    if (!ssSetNumOutputPorts(S, n_out)) return;
    for (i=0;i<n_out;++i) {
      const int_T* sp = f_sparsity_out(i);
      /* Dense vector outputs assumed here */
      ssSetOutputPortWidth(S, i, sp[0]);
    }

    ssSetNumSampleTimes(S, 1);
    
    /* Set up CasADi function work vector sizes */
    ssSetNumRWork(S, sz_w);
    ssSetNumIWork(S, sz_iw);
    ssSetNumPWork(S, sz_arg+sz_res);
    ssSetNumNonsampledZCs(S, 0);

    /* specify the sim state compliance to be same as a built-in block */
    ssSetSimStateCompliance(S, USE_DEFAULT_SIM_STATE);

    ssSetOptions(S,
                 SS_OPTION_WORKS_WITH_CODE_REUSE |
                 SS_OPTION_EXCEPTION_FREE_CODE |
                 SS_OPTION_USE_TLC_WITH_ACCELERATOR);
}


/* Function: mdlInitializeSampleTimes =========================================
 * Abstract:
 *    Specifiy that we inherit our sample time from the driving block.
 */
static void mdlInitializeSampleTimes(SimStruct *S)
{
    ssSetSampleTime(S, 0, INHERITED_SAMPLE_TIME);
    ssSetOffsetTime(S, 0, 0.0);
    ssSetModelReferenceSampleTimeDefaultInheritance(S); 
}

static void mdlOutputs(SimStruct *S, int_T tid)
{
    
    /* Read in CasADi function dimensions */
    int_T n_in  = f_n_in();
    int_T n_out = f_n_out();
    int_T sz_arg, sz_res, sz_iw, sz_w;
    f_work(&sz_arg, &sz_res, &sz_iw, &sz_w);
    
    /* Set up CasADi function work vectors */
    void** p = ssGetPWork(S);
    const real_T** arg = (const real_T**) p;
    p += sz_arg;
    real_T** res = (real_T**) p;
    real_T* w = ssGetRWork(S);
    int_T* iw = ssGetIWork(S);
    
    
    /* Point to input and output buffers */
    int_T i;   
    for (i=0; i<n_in;++i) {
      arg[i] = *ssGetInputPortRealSignalPtrs(S,i);
    }
    for (i=0; i<n_out;++i) {
      res[i] = ssGetOutputPortRealSignal(S,i);
    }
    /* Run the CasADi function */
    f(arg,res,iw,w,0);
}

static void mdlTerminate(SimStruct *S) {}


#ifdef  MATLAB_MEX_FILE    /* Is this file being compiled as a MEX-file? */
#include "simulink.c"      /* MEX-file interface mechanism */
#else
#include "cg_sfun.h"       /* Code generation registration function */
#endif
