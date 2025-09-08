/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_discretize_error_dynamics_FOH_kepler_fixedtf_mex.c
 *
 * Code generation for function
 * '_coder_discretize_error_dynamics_FOH_kepler_fixedtf_mex'
 *
 */

/* Include files */
#include "_coder_discretize_error_dynamics_FOH_kepler_fixedtf_mex.h"
#include "_coder_discretize_error_dynamics_FOH_kepler_fixedtf_api.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_data.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_initialize.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_terminate.h"
#include "rt_nonfinite.h"
#include "omp.h"

/* Function Definitions */
void discretize_error_dynamics_FOH_kepler_fixedtf_mexFunction(
    int32_T nlhs, mxArray *plhs[6], int32_T nrhs, const mxArray *prhs[5])
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  const mxArray *outputs[6];
  int32_T i;
  st.tls = emlrtRootTLSGlobal;
  /* Check for proper number of arguments. */
  if (nrhs != 5) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:WrongNumberOfInputs", 5, 12, 5, 4,
                        44, "discretize_error_dynamics_FOH_kepler_fixedtf");
  }
  if (nlhs > 6) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:TooManyOutputArguments", 3, 4, 44,
                        "discretize_error_dynamics_FOH_kepler_fixedtf");
  }
  /* Call the function. */
  c_discretize_error_dynamics_FOH(prhs, nlhs, outputs);
  /* Copy over outputs to the caller. */
  if (nlhs < 1) {
    i = 1;
  } else {
    i = nlhs;
  }
  emlrtReturnArrays(i, &plhs[0], &outputs[0]);
}

void mexFunction(int32_T nlhs, mxArray *plhs[], int32_T nrhs,
                 const mxArray *prhs[])
{
  static jmp_buf emlrtJBEnviron;
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  mexAtExit(&discretize_error_dynamics_FOH_kepler_fixedtf_atexit);
  emlrtLoadLibrary("C:\\ProgramData\\MATLAB\\SupportPackages\\R2025a\\3P."
                   "instrset\\mingw_w64.instrset\\bin\\libgomp-1.dll");
  /* Initialize the memory manager. */
  omp_init_lock(&emlrtLockGlobal);
  omp_init_nest_lock(
      &discretize_error_dynamics_FOH_kepler_fixedtf_nestLockGlobal);
  discretize_error_dynamics_FOH_kepler_fixedtf_initialize();
  st.tls = emlrtRootTLSGlobal;
  emlrtSetJmpBuf(&st, &emlrtJBEnviron);
  if (setjmp(emlrtJBEnviron) == 0) {
    discretize_error_dynamics_FOH_kepler_fixedtf_mexFunction(nlhs, plhs, nrhs,
                                                             prhs);
    discretize_error_dynamics_FOH_kepler_fixedtf_terminate();
    omp_destroy_lock(&emlrtLockGlobal);
    omp_destroy_nest_lock(
        &discretize_error_dynamics_FOH_kepler_fixedtf_nestLockGlobal);
  } else {
    omp_destroy_lock(&emlrtLockGlobal);
    omp_destroy_nest_lock(
        &discretize_error_dynamics_FOH_kepler_fixedtf_nestLockGlobal);
    emlrtReportParallelRunTimeError(&st);
  }
}

emlrtCTX mexFunctionCreateRootTLS(void)
{
  emlrtCreateRootTLSR2022a(&emlrtRootTLSGlobal, &emlrtContextGlobal,
                           &emlrtLockerFunction, omp_get_num_procs(), NULL,
                           "windows-1252", true);
  return emlrtRootTLSGlobal;
}

/* End of code generation
 * (_coder_discretize_error_dynamics_FOH_kepler_fixedtf_mex.c) */
