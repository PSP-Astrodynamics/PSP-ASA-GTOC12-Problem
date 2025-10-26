/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: _coder_discretize_error_dynamics_FOH_kepler_fixedtf_mex.h
 *
 * MATLAB Coder version            : 25.1
 * C/C++ source code generated on  : 07-Sep-2025 00:38:53
 */

#ifndef _CODER_DISCRETIZE_ERROR_DYNAMICS_FOH_KEPLER_FIXEDTF_MEX_H
#define _CODER_DISCRETIZE_ERROR_DYNAMICS_FOH_KEPLER_FIXEDTF_MEX_H

/* Include Files */
#include "emlrt.h"
#include "mex.h"
#include "tmwtypes.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
MEXFUNCTION_LINKAGE void mexFunction(int32_T nlhs, mxArray *plhs[],
                                     int32_T nrhs, const mxArray *prhs[]);

emlrtCTX mexFunctionCreateRootTLS(void);

void unsafe_discretize_error_dynamics_FOH_kepler_fixedtf_mexFunction(
    int32_T nlhs, mxArray *plhs[6], int32_T nrhs, const mxArray *prhs[5]);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for _coder_discretize_error_dynamics_FOH_kepler_fixedtf_mex.h
 *
 * [EOF]
 */
