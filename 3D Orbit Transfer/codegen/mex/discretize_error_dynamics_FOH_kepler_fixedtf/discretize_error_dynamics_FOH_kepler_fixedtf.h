/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * discretize_error_dynamics_FOH_kepler_fixedtf.h
 *
 * Code generation for function 'discretize_error_dynamics_FOH_kepler_fixedtf'
 *
 */

#pragma once

/* Include files */
#include "discretize_error_dynamics_FOH_kepler_fixedtf_types.h"
#include "rtwtypes.h"
#include "emlrt.h"
#include "mex.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Function Declarations */
void discretize_error_dynamics_FOH_kepler_fixedtf(
    const emlrtStack *sp, real_T N, const real_T tspan[2],
    const real_T x_ref[105], const real_T u_ref[45], emxArray_real_T *A_k,
    emxArray_real_T *B_k_plus, emxArray_real_T *B_k_minus, emxArray_real_T *S_k,
    emxArray_real_T *d_k, emxArray_real_T *Delta);

emlrtCTX emlrtGetRootTLSGlobal(void);

void emlrtLockerFunction(EmlrtLockeeFunction aLockee, emlrtConstCTX aTLS,
                         void *aData);

/* End of code generation (discretize_error_dynamics_FOH_kepler_fixedtf.h) */
