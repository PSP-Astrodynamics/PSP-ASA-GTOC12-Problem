/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * discretize_error_dynamics_FOH_kepler_fixedtf_terminate.c
 *
 * Code generation for function
 * 'discretize_error_dynamics_FOH_kepler_fixedtf_terminate'
 *
 */

/* Include files */
#include "discretize_error_dynamics_FOH_kepler_fixedtf_terminate.h"
#include "_coder_discretize_error_dynamics_FOH_kepler_fixedtf_mex.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_data.h"
#include "rt_nonfinite.h"
#include "omp.h"

/* Function Declarations */
static void emlrtExitTimeCleanupDtorFcn(const void *r);

/* Function Definitions */
static void emlrtExitTimeCleanupDtorFcn(const void *r)
{
  emlrtExitTimeCleanup(&emlrtContextGlobal);
}

void discretize_error_dynamics_FOH_kepler_fixedtf_atexit(void)
{
  static jmp_buf emlrtJBEnviron;
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  mexFunctionCreateRootTLS();
  emlrtLoadLibrary("C:\\ProgramData\\MATLAB\\SupportPackages\\R2025a\\3P."
                   "instrset\\mingw_w64.instrset\\bin\\libgomp-1.dll");
  /* Initialize the memory manager. */
  omp_init_lock(&emlrtLockGlobal);
  omp_init_nest_lock(
      &discretize_error_dynamics_FOH_kepler_fixedtf_nestLockGlobal);
  st.tls = emlrtRootTLSGlobal;
  emlrtSetJmpBuf(&st, &emlrtJBEnviron);
  if (setjmp(emlrtJBEnviron) == 0) {
    emlrtPushHeapReferenceStackR2021a(&st, false, NULL,
                                      (void *)&emlrtExitTimeCleanupDtorFcn,
                                      NULL, NULL, NULL);
    emlrtEnterRtStackR2012b(&st);
    emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
    emlrtExitTimeCleanup(&emlrtContextGlobal);
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

void discretize_error_dynamics_FOH_kepler_fixedtf_terminate(void)
{
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation
 * (discretize_error_dynamics_FOH_kepler_fixedtf_terminate.c) */
