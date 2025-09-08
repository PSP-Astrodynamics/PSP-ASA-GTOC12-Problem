/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: linspace.c
 *
 * MATLAB Coder version            : 25.1
 * C/C++ source code generated on  : 07-Sep-2025 00:38:53
 */

/* Include Files */
#include "linspace.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_emxutil.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_types.h"
#include "rt_nonfinite.h"
#include "omp.h"
#include <emmintrin.h>
#include <math.h>

/* Function Definitions */
/*
 * Arguments    : double d1
 *                double d2
 *                double N
 *                emxArray_real_T *y
 * Return Type  : void
 */
void linspace(double d1, double d2, double N, emxArray_real_T *y)
{
  double dv[2];
  double *y_data;
  int b_k;
  int k;
  if (N < 1.0) {
    y->size[0] = 1;
    y->size[1] = 0;
  } else {
    int nm1;
    int scalarLB;
    scalarLB = y->size[0] * y->size[1];
    y->size[0] = 1;
    nm1 = (int)floor(N);
    y->size[1] = nm1;
    emxEnsureCapacity_real_T(y, scalarLB);
    y_data = y->data;
    y_data[nm1 - 1] = d2;
    if (y->size[1] >= 2) {
      y_data[0] = d1;
      if (y->size[1] >= 3) {
        if (d1 == -d2) {
          double d2scaled;
          d2scaled = d2 / ((double)y->size[1] - 1.0);
          if (y->size[1] - 2 < 1600) {
            for (k = 2; k < nm1; k++) {
              y_data[k - 1] = (double)(((k << 1) - y->size[1]) - 1) * d2scaled;
            }
          } else {
#pragma omp parallel for num_threads(omp_get_max_threads())

            for (k = 2; k < nm1; k++) {
              y_data[k - 1] = (double)(((k << 1) - y->size[1]) - 1) * d2scaled;
            }
          }
          if (((unsigned int)y->size[1] & 1U) == 1U) {
            y_data[y->size[1] >> 1] = 0.0;
          }
        } else if (((d1 < 0.0) != (d2 < 0.0)) &&
                   ((fabs(d1) > 8.9884656743115785E+307) ||
                    (fabs(d2) > 8.9884656743115785E+307))) {
          double d2scaled;
          double delta2;
          int vectorUB;
          d2scaled = d1 / ((double)y->size[1] - 1.0);
          delta2 = d2 / ((double)y->size[1] - 1.0);
          scalarLB = ((y->size[1] - 2) / 2) << 1;
          vectorUB = scalarLB - 2;
          for (b_k = 0; b_k <= vectorUB; b_k += 2) {
            __m128d r;
            __m128d r1;
            dv[0] = b_k + 1;
            dv[1] = b_k + 2;
            r = _mm_loadu_pd(&dv[0]);
            dv[0] = b_k + 1;
            dv[1] = b_k + 2;
            r1 = _mm_loadu_pd(&dv[0]);
            _mm_storeu_pd(
                &y_data[b_k + 1],
                _mm_sub_pd(_mm_add_pd(_mm_set1_pd(d1),
                                      _mm_mul_pd(_mm_set1_pd(delta2), r)),
                           _mm_mul_pd(_mm_set1_pd(d2scaled), r1)));
          }
          for (b_k = scalarLB; b_k <= nm1 - 3; b_k++) {
            y_data[b_k + 1] = (d1 + delta2 * (double)(b_k + 1)) -
                              d2scaled * (double)(b_k + 1);
          }
        } else {
          double d2scaled;
          int vectorUB;
          d2scaled = (d2 - d1) / ((double)y->size[1] - 1.0);
          scalarLB = ((y->size[1] - 2) / 2) << 1;
          vectorUB = scalarLB - 2;
          for (b_k = 0; b_k <= vectorUB; b_k += 2) {
            __m128d r;
            dv[0] = b_k + 1;
            dv[1] = b_k + 2;
            r = _mm_loadu_pd(&dv[0]);
            _mm_storeu_pd(&y_data[b_k + 1],
                          _mm_add_pd(_mm_set1_pd(d1),
                                     _mm_mul_pd(r, _mm_set1_pd(d2scaled))));
          }
          for (b_k = scalarLB; b_k <= nm1 - 3; b_k++) {
            y_data[b_k + 1] = d1 + (double)(b_k + 1) * d2scaled;
          }
        }
      }
    }
  }
}

/*
 * File trailer for linspace.c
 *
 * [EOF]
 */
