/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: discretize_error_dynamics_FOH_kepler_fixedtf.h
 *
 * MATLAB Coder version            : 25.1
 * C/C++ source code generated on  : 07-Sep-2025 00:38:53
 */

#ifndef DISCRETIZE_ERROR_DYNAMICS_FOH_KEPLER_FIXEDTF_H
#define DISCRETIZE_ERROR_DYNAMICS_FOH_KEPLER_FIXEDTF_H

/* Include Files */
#include "discretize_error_dynamics_FOH_kepler_fixedtf_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern void discretize_error_dynamics_FOH_kepler_fixedtf(
    double N, const double tspan[2], const double x_ref[105],
    const double u_ref[45], emxArray_real_T *A_k, emxArray_real_T *B_k_plus,
    emxArray_real_T *B_k_minus, emxArray_real_T *S_k, emxArray_real_T *d_k,
    emxArray_real_T *Delta);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for discretize_error_dynamics_FOH_kepler_fixedtf.h
 *
 * [EOF]
 */
