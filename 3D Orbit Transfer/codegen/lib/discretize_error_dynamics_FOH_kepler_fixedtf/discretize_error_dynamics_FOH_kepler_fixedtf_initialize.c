/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: discretize_error_dynamics_FOH_kepler_fixedtf_initialize.c
 *
 * MATLAB Coder version            : 25.1
 * C/C++ source code generated on  : 07-Sep-2025 00:38:53
 */

/* Include Files */
#include "discretize_error_dynamics_FOH_kepler_fixedtf_initialize.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_data.h"
#include "rt_nonfinite.h"
#include "omp.h"

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : void
 */
void discretize_error_dynamics_FOH_kepler_fixedtf_initialize(void)
{
  omp_init_nest_lock(
      &discretize_error_dynamics_FOH_kepler_fixedtf_nestLockGlobal);
  isInitialized_discretize_error_dynamics_FOH_kepler_fixedtf = true;
}

/*
 * File trailer for discretize_error_dynamics_FOH_kepler_fixedtf_initialize.c
 *
 * [EOF]
 */
