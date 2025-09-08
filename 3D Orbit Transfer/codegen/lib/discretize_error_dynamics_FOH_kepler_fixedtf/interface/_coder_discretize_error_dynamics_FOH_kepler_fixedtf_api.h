/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: _coder_discretize_error_dynamics_FOH_kepler_fixedtf_api.h
 *
 * MATLAB Coder version            : 25.1
 * C/C++ source code generated on  : 07-Sep-2025 00:38:53
 */

#ifndef _CODER_DISCRETIZE_ERROR_DYNAMICS_FOH_KEPLER_FIXEDTF_API_H
#define _CODER_DISCRETIZE_ERROR_DYNAMICS_FOH_KEPLER_FIXEDTF_API_H

/* Include Files */
#include "emlrt.h"
#include "mex.h"
#include "tmwtypes.h"
#include <string.h>

/* Type Definitions */
#ifndef struct_emxArray_real_T
#define struct_emxArray_real_T
struct emxArray_real_T {
  real_T *data;
  int32_T *size;
  int32_T allocatedSize;
  int32_T numDimensions;
  boolean_T canFreeData;
};
#endif /* struct_emxArray_real_T */
#ifndef typedef_emxArray_real_T
#define typedef_emxArray_real_T
typedef struct emxArray_real_T emxArray_real_T;
#endif /* typedef_emxArray_real_T */

/* Variable Declarations */
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
void c_discretize_error_dynamics_FOH(const mxArray *const prhs[5], int32_T nlhs,
                                     const mxArray *plhs[6]);

void discretize_error_dynamics_FOH_kepler_fixedtf(
    real_T N, real_T tspan[2], real_T x_ref[105], real_T u_ref[45],
    emxArray_real_T *A_k, emxArray_real_T *B_k_plus, emxArray_real_T *B_k_minus,
    emxArray_real_T *S_k, emxArray_real_T *d_k, emxArray_real_T *Delta);

void discretize_error_dynamics_FOH_kepler_fixedtf_atexit(void);

void discretize_error_dynamics_FOH_kepler_fixedtf_initialize(void);

void discretize_error_dynamics_FOH_kepler_fixedtf_terminate(void);

void discretize_error_dynamics_FOH_kepler_fixedtf_xil_shutdown(void);

void discretize_error_dynamics_FOH_kepler_fixedtf_xil_terminate(void);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for _coder_discretize_error_dynamics_FOH_kepler_fixedtf_api.h
 *
 * [EOF]
 */
