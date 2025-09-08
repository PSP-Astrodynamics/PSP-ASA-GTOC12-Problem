/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * discretize_error_dynamics_FOH_kepler_fixedtf_initialize.c
 *
 * Code generation for function
 * 'discretize_error_dynamics_FOH_kepler_fixedtf_initialize'
 *
 */

/* Include files */
#include "discretize_error_dynamics_FOH_kepler_fixedtf_initialize.h"
#include "_coder_discretize_error_dynamics_FOH_kepler_fixedtf_mex.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_data.h"
#include "rt_nonfinite.h"

/* Function Declarations */
static void discretize_error_dynamics_FOH_kepler_fixedtf_once(void);

/* Function Definitions */
static void discretize_error_dynamics_FOH_kepler_fixedtf_once(void)
{
  mex_InitInfAndNan();
}

void discretize_error_dynamics_FOH_kepler_fixedtf_initialize(void)
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  mexFunctionCreateRootTLS();
  st.tls = emlrtRootTLSGlobal;
  emlrtBreakCheckR2012bFlagVar = emlrtGetBreakCheckFlagAddressR2022b(&st);
  emlrtClearAllocCountR2012b(&st, false, 0U, NULL);
  emlrtEnterRtStackR2012b(&st);
  if (emlrtFirstTimeR2012b(emlrtRootTLSGlobal)) {
    discretize_error_dynamics_FOH_kepler_fixedtf_once();
  }
}

/* End of code generation
 * (discretize_error_dynamics_FOH_kepler_fixedtf_initialize.c) */
