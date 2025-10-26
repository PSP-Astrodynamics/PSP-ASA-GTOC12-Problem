/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: discretize_error_dynamics_FOH_kepler_fixedtf_emxAPI.h
 *
 * MATLAB Coder version            : 25.1
 * C/C++ source code generated on  : 07-Sep-2025 00:38:53
 */

#ifndef DISCRETIZE_ERROR_DYNAMICS_FOH_KEPLER_FIXEDTF_EMXAPI_H
#define DISCRETIZE_ERROR_DYNAMICS_FOH_KEPLER_FIXEDTF_EMXAPI_H

/* Include Files */
#include "discretize_error_dynamics_FOH_kepler_fixedtf_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern emxArray_real_T *emxCreateND_real_T(int numDimensions, const int *size);

extern emxArray_real_T *
emxCreateWrapperND_real_T(double *data, int numDimensions, const int *size);

extern emxArray_real_T *emxCreateWrapper_real_T(double *data, int rows,
                                                int cols);

extern emxArray_real_T *emxCreate_real_T(int rows, int cols);

extern void emxDestroyArray_real_T(emxArray_real_T *emxArray);

extern void emxInitArray_real_T(emxArray_real_T **pEmxArray, int numDimensions);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for discretize_error_dynamics_FOH_kepler_fixedtf_emxAPI.h
 *
 * [EOF]
 */
