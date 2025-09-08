/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: discretize_error_dynamics_FOH_kepler_fixedtf.c
 *
 * MATLAB Coder version            : 25.1
 * C/C++ source code generated on  : 07-Sep-2025 00:38:53
 */

/* Include Files */
#include "discretize_error_dynamics_FOH_kepler_fixedtf.h"
#include "A_kepler_fixedtf.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_data.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_emxutil.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_initialize.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_rtwutil.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_types.h"
#include "linspace.h"
#include "rt_nonfinite.h"
#include <emmintrin.h>
#include <math.h>
#include <string.h>

/* Function Definitions */
/*
 * Discretization of the devition from a reference trajectory for a dynamical
 * system assuming FOH control Make c optional? c = f - Ax - Bu
 *
 * Arguments    : double N
 *                const double tspan[2]
 *                const double x_ref[105]
 *                const double u_ref[45]
 *                emxArray_real_T *A_k
 *                emxArray_real_T *B_k_plus
 *                emxArray_real_T *B_k_minus
 *                emxArray_real_T *S_k
 *                emxArray_real_T *d_k
 *                emxArray_real_T *Delta
 * Return Type  : void
 */
void discretize_error_dynamics_FOH_kepler_fixedtf(
    double N, const double tspan[2], const double x_ref[105],
    const double u_ref[45], emxArray_real_T *A_k, emxArray_real_T *B_k_plus,
    emxArray_real_T *B_k_minus, emxArray_real_T *S_k, emxArray_real_T *d_k,
    emxArray_real_T *Delta)
{
  static const signed char iv[49] = {
      1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1};
  emxArray_real_T *t_k;
  double F[392];
  double Y[196];
  double y[98];
  double A_t[49];
  double b_A_t[49];
  double b_Y[49];
  double B_t[21];
  double c_Y[21];
  double dv[21];
  double c_y[7];
  double d_y[7];
  double u_ref_k[6];
  double u[3];
  double *A_k_data;
  double *B_k_minus_data;
  double *B_k_plus_data;
  double *Delta_data;
  double *d_k_data;
  double *t_k_data;
  int b_loop_ub;
  int i;
  int i1;
  int i2;
  int i3;
  int k;
  int loop_ub;
  if (!isInitialized_discretize_error_dynamics_FOH_kepler_fixedtf) {
    discretize_error_dynamics_FOH_kepler_fixedtf_initialize();
  }
  emxInit_real_T(&t_k, 2);
  linspace(tspan[0], tspan[1], N, t_k);
  t_k_data = t_k->data;
  loop_ub = A_k->size[0] * A_k->size[1] * A_k->size[2];
  A_k->size[0] = 7;
  A_k->size[1] = 7;
  i = (int)(N - 1.0);
  A_k->size[2] = (int)(N - 1.0);
  emxEnsureCapacity_real_T(A_k, loop_ub);
  A_k_data = A_k->data;
  loop_ub = 49 * (int)(N - 1.0);
  for (i1 = 0; i1 < loop_ub; i1++) {
    A_k_data[i1] = 0.0;
  }
  loop_ub = B_k_plus->size[0] * B_k_plus->size[1] * B_k_plus->size[2];
  B_k_plus->size[0] = 7;
  B_k_plus->size[1] = 3;
  B_k_plus->size[2] = (int)(N - 1.0);
  emxEnsureCapacity_real_T(B_k_plus, loop_ub);
  B_k_plus_data = B_k_plus->data;
  b_loop_ub = 21 * (int)(N - 1.0);
  for (i1 = 0; i1 < b_loop_ub; i1++) {
    B_k_plus_data[i1] = 0.0;
  }
  loop_ub = B_k_minus->size[0] * B_k_minus->size[1] * B_k_minus->size[2];
  B_k_minus->size[0] = 7;
  B_k_minus->size[1] = 3;
  B_k_minus->size[2] = (int)(N - 1.0);
  emxEnsureCapacity_real_T(B_k_minus, loop_ub);
  B_k_minus_data = B_k_minus->data;
  for (i1 = 0; i1 < b_loop_ub; i1++) {
    B_k_minus_data[i1] = 0.0;
  }
  S_k->size[0] = 7;
  S_k->size[1] = 0;
  S_k->size[2] = (int)(N - 1.0);
  loop_ub = d_k->size[0] * d_k->size[1] * d_k->size[2];
  d_k->size[0] = 7;
  d_k->size[1] = 1;
  d_k->size[2] = (int)(N - 1.0);
  emxEnsureCapacity_real_T(d_k, loop_ub);
  d_k_data = d_k->data;
  b_loop_ub = 7 * (int)(N - 1.0);
  for (i1 = 0; i1 < b_loop_ub; i1++) {
    d_k_data[i1] = 0.0;
  }
  loop_ub = Delta->size[0] * Delta->size[1];
  Delta->size[0] = 7;
  Delta->size[1] = (int)(N - 1.0);
  emxEnsureCapacity_real_T(Delta, loop_ub);
  Delta_data = Delta->data;
  for (i1 = 0; i1 < b_loop_ub; i1++) {
    Delta_data[i1] = 0.0;
  }
  if ((int)(N - 1.0) - 1 >= 0) {
  }
  for (k = 0; k < i; k++) {
    __m128d r;
    __m128d r1;
    __m128d r2;
    __m128d r3;
    __m128d r4;
    double b_y[196];
    double c_A_t[21];
    double d_A_t[21];
    double b_t7_tmp;
    double hi;
    double t7;
    double t7_tmp;
    double t7_tmp_tmp;
    double t8;
    double t8_tmp;
    double u_tmp;
    int A_t_tmp;
    u_ref_k[0] = u_ref[3 * k];
    loop_ub = 3 * (k + 1);
    u_ref_k[3] = u_ref[loop_ub];
    u_ref_k[1] = u_ref[3 * k + 1];
    u_ref_k[4] = u_ref[loop_ub + 1];
    u_ref_k[2] = u_ref[3 * k + 2];
    u_ref_k[5] = u_ref[loop_ub + 2];
    /*  Integrates STM and state with Bk+, Bk-, and ck */
    /*    Uses RK4 to integrate the State Transition Matrix and the state using
     */
    /*    the given A matrix and dynamics f over the time period in tspan */
    /*  Create initial condition */
    /*  Simulate     */
    memset(&Y[0], 0, 196U * sizeof(double));
    memset(&F[0], 0, 392U * sizeof(double));
    for (i1 = 0; i1 < 7; i1++) {
      Y[i1] = x_ref[i1 + 7 * k];
    }
    for (i1 = 0; i1 < 49; i1++) {
      Y[i1 + 7] = iv[i1];
    }
    for (i1 = 0; i1 < 21; i1++) {
      Y[i1 + 56] = 0.0;
      Y[i1 + 77] = 0.0;
    }
    hi = t_k_data[k + 1] - t_k_data[k];
    r = _mm_loadu_pd(&u_ref_k[3]);
    r1 = _mm_loadu_pd(&u_ref_k[0]);
    r2 = _mm_set1_pd(0.0);
    _mm_storeu_pd(&u[0], _mm_add_pd(r1, _mm_mul_pd(r, r2)));
    u[2] = u_ref_k[2] + u_ref_k[5] * 0.0;
    A_kepler_fixedtf(&Y[0], u, A_t);
    /* B_kepler_fixedtf */
    /*     J_B = B_kepler_fixedtf(T,IN2,IN3,IN4) */
    /*     This function was generated by the Symbolic Math Toolbox
     * version 25.1. */
    /*     07-Sep-2025 00:01:12 */
    t8_tmp = 1.0 / Y[6];
    t8 = t8_tmp * 0.056196496465355988;
    t7_tmp = sqrt((u[0] * u[0] + u[1] * u[1]) + u[2] * u[2]);
    t7 = 1.0 / t7_tmp;
    dv[0] = 0.0;
    dv[1] = 0.0;
    dv[2] = 0.0;
    dv[3] = t8;
    dv[4] = 0.0;
    dv[5] = 0.0;
    dv[6] = t7 * u[0] * -0.0426725757873853;
    dv[7] = 0.0;
    dv[8] = 0.0;
    dv[9] = 0.0;
    dv[10] = 0.0;
    dv[11] = t8;
    dv[12] = 0.0;
    dv[13] = t7 * u[1] * -0.0426725757873853;
    dv[14] = 0.0;
    dv[15] = 0.0;
    dv[16] = 0.0;
    dv[17] = 0.0;
    dv[18] = 0.0;
    dv[19] = t8;
    dv[20] = t7 * u[2] * -0.0426725757873853;
    /* F_KEPLER_FIXEDTF */
    /*     XDOT = F_KEPLER_FIXEDTF(T,IN2,IN3,IN4) */
    /*     This function was generated by the Symbolic Math Toolbox
     * version 25.1. */
    /*     07-Sep-2025 00:01:12 */
    t7 = 1.0 / rt_powd_snf((Y[0] * Y[0] + Y[1] * Y[1]) + Y[2] * Y[2], 1.5);
    memcpy(&b_Y[0], &Y[7], 49U * sizeof(double));
    memset(&b_A_t[0], 0, 49U * sizeof(double));
    for (i1 = 0; i1 < 7; i1++) {
      loop_ub = 7 * i1 + 2;
      b_loop_ub = 7 * i1 + 4;
      A_t_tmp = 7 * i1 + 6;
      for (i2 = 0; i2 < 7; i2++) {
        b_t7_tmp = b_Y[i2 + 7 * i1];
        r = _mm_loadu_pd(&A_t[7 * i2]);
        r1 = _mm_loadu_pd(&b_A_t[7 * i1]);
        r3 = _mm_set1_pd(b_t7_tmp);
        _mm_storeu_pd(&b_A_t[7 * i1], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i2 + 2]);
        r1 = _mm_loadu_pd(&b_A_t[loop_ub]);
        _mm_storeu_pd(&b_A_t[loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i2 + 4]);
        r1 = _mm_loadu_pd(&b_A_t[b_loop_ub]);
        _mm_storeu_pd(&b_A_t[b_loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        b_A_t[A_t_tmp] += A_t[7 * i2 + 6] * b_t7_tmp;
      }
    }
    memcpy(&c_Y[0], &Y[56], 21U * sizeof(double));
    for (i2 = 0; i2 < 7; i2++) {
      for (i3 = 0; i3 < 3; i3++) {
        t8 = 0.0;
        for (i1 = 0; i1 < 7; i1++) {
          t8 += A_t[i2 + 7 * i1] * c_Y[i1 + 7 * i3];
        }
        loop_ub = i2 + 7 * i3;
        c_A_t[loop_ub] = t8 + dv[loop_ub] * 0.0;
      }
    }
    memcpy(&c_Y[0], &Y[77], 21U * sizeof(double));
    for (i2 = 0; i2 < 7; i2++) {
      for (i3 = 0; i3 < 3; i3++) {
        t8 = 0.0;
        for (i1 = 0; i1 < 7; i1++) {
          t8 += A_t[i2 + 7 * i1] * c_Y[i1 + 7 * i3];
        }
        loop_ub = i2 + 7 * i3;
        d_A_t[loop_ub] = t8 + dv[loop_ub];
      }
    }
    F[0] = Y[3];
    F[1] = Y[4];
    F[2] = Y[5];
    F[3] = -Y[0] * t7 + t8_tmp * u[0] * 0.056196496465355988;
    F[4] = -Y[1] * t7 + t8_tmp * u[1] * 0.056196496465355988;
    F[5] = -Y[2] * t7 + t8_tmp * u[2] * 0.056196496465355988;
    F[6] = t7_tmp * -0.0426725757873853;
    memcpy(&F[7], &b_A_t[0], 49U * sizeof(double));
    for (i1 = 0; i1 < 21; i1++) {
      F[i1 + 56] = c_A_t[i1];
      F[i1 + 77] = d_A_t[i1];
    }
    t8_tmp = 0.5 * hi;
    for (i1 = 0; i1 <= 96; i1 += 2) {
      r = _mm_loadu_pd(&F[i1]);
      r1 = _mm_loadu_pd(&Y[i1]);
      _mm_storeu_pd(&y[i1], _mm_add_pd(r1, _mm_mul_pd(_mm_set1_pd(t8_tmp), r)));
    }
    r = _mm_loadu_pd(&u_ref_k[0]);
    r1 = _mm_loadu_pd(&u_ref_k[3]);
    r4 = _mm_set1_pd(0.5);
    _mm_storeu_pd(&u[0], _mm_add_pd(_mm_mul_pd(r, r4), _mm_mul_pd(r1, r4)));
    u_tmp = u_ref_k[2] * 0.5 + u_ref_k[5] * 0.5;
    u[2] = u_tmp;
    A_kepler_fixedtf(&y[0], u, A_t);
    /* B_kepler_fixedtf */
    /*     J_B = B_kepler_fixedtf(T,IN2,IN3,IN4) */
    /*     This function was generated by the Symbolic Math Toolbox
     * version 25.1. */
    /*     07-Sep-2025 00:01:12 */
    t7_tmp = 1.0 / y[6];
    t8 = t7_tmp * 0.056196496465355988;
    t7_tmp_tmp = u_tmp * u_tmp;
    b_t7_tmp = sqrt((u[0] * u[0] + u[1] * u[1]) + t7_tmp_tmp);
    t7 = 1.0 / b_t7_tmp;
    dv[0] = 0.0;
    dv[1] = 0.0;
    dv[2] = 0.0;
    dv[3] = t8;
    dv[4] = 0.0;
    dv[5] = 0.0;
    dv[6] = t7 * u[0] * -0.0426725757873853;
    dv[7] = 0.0;
    dv[8] = 0.0;
    dv[9] = 0.0;
    dv[10] = 0.0;
    dv[11] = t8;
    dv[12] = 0.0;
    dv[13] = t7 * u[1] * -0.0426725757873853;
    dv[14] = 0.0;
    dv[15] = 0.0;
    dv[16] = 0.0;
    dv[17] = 0.0;
    dv[18] = 0.0;
    dv[19] = t8;
    dv[20] = t7 * u_tmp * -0.0426725757873853;
    for (i1 = 0; i1 <= 18; i1 += 2) {
      r = _mm_loadu_pd(&dv[i1]);
      _mm_storeu_pd(&B_t[i1], _mm_mul_pd(r, r4));
    }
    B_t[20] = dv[20] * 0.5;
    /* F_KEPLER_FIXEDTF */
    /*     XDOT = F_KEPLER_FIXEDTF(T,IN2,IN3,IN4) */
    /*     This function was generated by the Symbolic Math Toolbox
     * version 25.1. */
    /*     07-Sep-2025 00:01:12 */
    t7 = 1.0 / rt_powd_snf((y[0] * y[0] + y[1] * y[1]) + y[2] * y[2], 1.5);
    memcpy(&b_Y[0], &y[7], 49U * sizeof(double));
    memset(&b_A_t[0], 0, 49U * sizeof(double));
    for (i1 = 0; i1 < 7; i1++) {
      loop_ub = 7 * i1 + 2;
      b_loop_ub = 7 * i1 + 4;
      A_t_tmp = 7 * i1 + 6;
      for (i3 = 0; i3 < 7; i3++) {
        t8 = b_Y[i3 + 7 * i1];
        r = _mm_loadu_pd(&A_t[7 * i3]);
        r1 = _mm_loadu_pd(&b_A_t[7 * i1]);
        r3 = _mm_set1_pd(t8);
        _mm_storeu_pd(&b_A_t[7 * i1], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i3 + 2]);
        r1 = _mm_loadu_pd(&b_A_t[loop_ub]);
        _mm_storeu_pd(&b_A_t[loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i3 + 4]);
        r1 = _mm_loadu_pd(&b_A_t[b_loop_ub]);
        _mm_storeu_pd(&b_A_t[b_loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        b_A_t[A_t_tmp] += A_t[7 * i3 + 6] * t8;
      }
    }
    memcpy(&c_Y[0], &y[56], 21U * sizeof(double));
    for (i2 = 0; i2 < 7; i2++) {
      for (i3 = 0; i3 < 3; i3++) {
        t8 = 0.0;
        for (i1 = 0; i1 < 7; i1++) {
          t8 += A_t[i2 + 7 * i1] * c_Y[i1 + 7 * i3];
        }
        loop_ub = i2 + 7 * i3;
        c_A_t[loop_ub] = t8 + B_t[loop_ub];
      }
    }
    memcpy(&c_Y[0], &y[77], 21U * sizeof(double));
    for (i2 = 0; i2 < 7; i2++) {
      for (i3 = 0; i3 < 3; i3++) {
        t8 = 0.0;
        for (i1 = 0; i1 < 7; i1++) {
          t8 += A_t[i2 + 7 * i1] * c_Y[i1 + 7 * i3];
        }
        loop_ub = i2 + 7 * i3;
        d_A_t[loop_ub] = t8 + B_t[loop_ub];
      }
    }
    F[98] = y[3];
    F[99] = y[4];
    F[100] = y[5];
    F[101] = -y[0] * t7 + t7_tmp * u[0] * 0.056196496465355988;
    F[102] = -y[1] * t7 + t7_tmp * u[1] * 0.056196496465355988;
    F[103] = -y[2] * t7 + t7_tmp * u_tmp * 0.056196496465355988;
    F[104] = b_t7_tmp * -0.0426725757873853;
    memcpy(&F[105], &b_A_t[0], 49U * sizeof(double));
    for (i1 = 0; i1 < 21; i1++) {
      F[i1 + 154] = c_A_t[i1];
      F[i1 + 175] = d_A_t[i1];
    }
    for (i1 = 0; i1 <= 96; i1 += 2) {
      r = _mm_loadu_pd(&F[i1 + 98]);
      r1 = _mm_loadu_pd(&Y[i1]);
      _mm_storeu_pd(&y[i1], _mm_add_pd(r1, _mm_mul_pd(_mm_set1_pd(t8_tmp), r)));
    }
    r = _mm_loadu_pd(&u_ref_k[0]);
    r1 = _mm_loadu_pd(&u_ref_k[3]);
    _mm_storeu_pd(&u[0], _mm_add_pd(_mm_mul_pd(r, r4), _mm_mul_pd(r1, r4)));
    u[2] = u_tmp;
    A_kepler_fixedtf(&y[0], u, A_t);
    /* B_kepler_fixedtf */
    /*     J_B = B_kepler_fixedtf(T,IN2,IN3,IN4) */
    /*     This function was generated by the Symbolic Math Toolbox
     * version 25.1. */
    /*     07-Sep-2025 00:01:12 */
    t7_tmp = 1.0 / y[6];
    t7 = t7_tmp * 0.056196496465355988;
    t8_tmp = sqrt((u[0] * u[0] + u[1] * u[1]) + t7_tmp_tmp);
    t8 = 1.0 / t8_tmp;
    dv[0] = 0.0;
    dv[1] = 0.0;
    dv[2] = 0.0;
    dv[3] = t7;
    dv[4] = 0.0;
    dv[5] = 0.0;
    dv[6] = t8 * u[0] * -0.0426725757873853;
    dv[7] = 0.0;
    dv[8] = 0.0;
    dv[9] = 0.0;
    dv[10] = 0.0;
    dv[11] = t7;
    dv[12] = 0.0;
    dv[13] = t8 * u[1] * -0.0426725757873853;
    dv[14] = 0.0;
    dv[15] = 0.0;
    dv[16] = 0.0;
    dv[17] = 0.0;
    dv[18] = 0.0;
    dv[19] = t7;
    dv[20] = t8 * u_tmp * -0.0426725757873853;
    for (i1 = 0; i1 <= 18; i1 += 2) {
      r = _mm_loadu_pd(&dv[i1]);
      _mm_storeu_pd(&B_t[i1], _mm_mul_pd(r, r4));
    }
    B_t[20] = dv[20] * 0.5;
    /* F_KEPLER_FIXEDTF */
    /*     XDOT = F_KEPLER_FIXEDTF(T,IN2,IN3,IN4) */
    /*     This function was generated by the Symbolic Math Toolbox
     * version 25.1. */
    /*     07-Sep-2025 00:01:12 */
    t7 = 1.0 / rt_powd_snf((y[0] * y[0] + y[1] * y[1]) + y[2] * y[2], 1.5);
    memcpy(&b_Y[0], &y[7], 49U * sizeof(double));
    memset(&b_A_t[0], 0, 49U * sizeof(double));
    for (i1 = 0; i1 < 7; i1++) {
      loop_ub = 7 * i1 + 2;
      b_loop_ub = 7 * i1 + 4;
      A_t_tmp = 7 * i1 + 6;
      for (i3 = 0; i3 < 7; i3++) {
        t8 = b_Y[i3 + 7 * i1];
        r = _mm_loadu_pd(&A_t[7 * i3]);
        r1 = _mm_loadu_pd(&b_A_t[7 * i1]);
        r3 = _mm_set1_pd(t8);
        _mm_storeu_pd(&b_A_t[7 * i1], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i3 + 2]);
        r1 = _mm_loadu_pd(&b_A_t[loop_ub]);
        _mm_storeu_pd(&b_A_t[loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i3 + 4]);
        r1 = _mm_loadu_pd(&b_A_t[b_loop_ub]);
        _mm_storeu_pd(&b_A_t[b_loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        b_A_t[A_t_tmp] += A_t[7 * i3 + 6] * t8;
      }
    }
    memcpy(&c_Y[0], &y[56], 21U * sizeof(double));
    for (i2 = 0; i2 < 7; i2++) {
      for (i3 = 0; i3 < 3; i3++) {
        t8 = 0.0;
        for (i1 = 0; i1 < 7; i1++) {
          t8 += A_t[i2 + 7 * i1] * c_Y[i1 + 7 * i3];
        }
        loop_ub = i2 + 7 * i3;
        c_A_t[loop_ub] = t8 + B_t[loop_ub];
      }
    }
    memcpy(&c_Y[0], &y[77], 21U * sizeof(double));
    for (i2 = 0; i2 < 7; i2++) {
      for (i3 = 0; i3 < 3; i3++) {
        t8 = 0.0;
        for (i1 = 0; i1 < 7; i1++) {
          t8 += A_t[i2 + 7 * i1] * c_Y[i1 + 7 * i3];
        }
        loop_ub = i2 + 7 * i3;
        d_A_t[loop_ub] = t8 + B_t[loop_ub];
      }
    }
    F[196] = y[3];
    F[197] = y[4];
    F[198] = y[5];
    F[199] = -y[0] * t7 + t7_tmp * u[0] * 0.056196496465355988;
    F[200] = -y[1] * t7 + t7_tmp * u[1] * 0.056196496465355988;
    F[201] = -y[2] * t7 + t7_tmp * u_tmp * 0.056196496465355988;
    F[202] = t8_tmp * -0.0426725757873853;
    memcpy(&F[203], &b_A_t[0], 49U * sizeof(double));
    for (i1 = 0; i1 < 21; i1++) {
      F[i1 + 252] = c_A_t[i1];
      F[i1 + 273] = d_A_t[i1];
    }
    for (i1 = 0; i1 <= 96; i1 += 2) {
      r = _mm_loadu_pd(&F[i1 + 196]);
      r1 = _mm_loadu_pd(&Y[i1]);
      _mm_storeu_pd(&y[i1], _mm_add_pd(r1, _mm_mul_pd(_mm_set1_pd(hi), r)));
    }
    r = _mm_loadu_pd(&u_ref_k[0]);
    r1 = _mm_loadu_pd(&u_ref_k[3]);
    _mm_storeu_pd(&u[0], _mm_add_pd(_mm_mul_pd(r, r2), r1));
    u[2] = u_ref_k[2] * 0.0 + u_ref_k[5];
    A_kepler_fixedtf(&y[0], u, A_t);
    /* B_kepler_fixedtf */
    /*     J_B = B_kepler_fixedtf(T,IN2,IN3,IN4) */
    /*     This function was generated by the Symbolic Math Toolbox
     * version 25.1. */
    /*     07-Sep-2025 00:01:12 */
    b_t7_tmp = 1.0 / y[6];
    t8 = b_t7_tmp * 0.056196496465355988;
    t8_tmp = sqrt((u[0] * u[0] + u[1] * u[1]) + u[2] * u[2]);
    t7 = 1.0 / t8_tmp;
    dv[0] = 0.0;
    dv[1] = 0.0;
    dv[2] = 0.0;
    dv[3] = t8;
    dv[4] = 0.0;
    dv[5] = 0.0;
    dv[6] = t7 * u[0] * -0.0426725757873853;
    dv[7] = 0.0;
    dv[8] = 0.0;
    dv[9] = 0.0;
    dv[10] = 0.0;
    dv[11] = t8;
    dv[12] = 0.0;
    dv[13] = t7 * u[1] * -0.0426725757873853;
    dv[14] = 0.0;
    dv[15] = 0.0;
    dv[16] = 0.0;
    dv[17] = 0.0;
    dv[18] = 0.0;
    dv[19] = t8;
    dv[20] = t7 * u[2] * -0.0426725757873853;
    /* F_KEPLER_FIXEDTF */
    /*     XDOT = F_KEPLER_FIXEDTF(T,IN2,IN3,IN4) */
    /*     This function was generated by the Symbolic Math Toolbox
     * version 25.1. */
    /*     07-Sep-2025 00:01:12 */
    t7 = 1.0 / rt_powd_snf((y[0] * y[0] + y[1] * y[1]) + y[2] * y[2], 1.5);
    memcpy(&b_Y[0], &y[7], 49U * sizeof(double));
    memset(&b_A_t[0], 0, 49U * sizeof(double));
    for (i1 = 0; i1 < 7; i1++) {
      loop_ub = 7 * i1 + 2;
      b_loop_ub = 7 * i1 + 4;
      A_t_tmp = 7 * i1 + 6;
      for (i3 = 0; i3 < 7; i3++) {
        t8 = b_Y[i3 + 7 * i1];
        r = _mm_loadu_pd(&A_t[7 * i3]);
        r1 = _mm_loadu_pd(&b_A_t[7 * i1]);
        r3 = _mm_set1_pd(t8);
        _mm_storeu_pd(&b_A_t[7 * i1], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i3 + 2]);
        r1 = _mm_loadu_pd(&b_A_t[loop_ub]);
        _mm_storeu_pd(&b_A_t[loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i3 + 4]);
        r1 = _mm_loadu_pd(&b_A_t[b_loop_ub]);
        _mm_storeu_pd(&b_A_t[b_loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        b_A_t[A_t_tmp] += A_t[7 * i3 + 6] * t8;
      }
    }
    memcpy(&c_Y[0], &y[56], 21U * sizeof(double));
    for (i2 = 0; i2 < 7; i2++) {
      for (i3 = 0; i3 < 3; i3++) {
        t8 = 0.0;
        for (i1 = 0; i1 < 7; i1++) {
          t8 += A_t[i2 + 7 * i1] * c_Y[i1 + 7 * i3];
        }
        loop_ub = i2 + 7 * i3;
        c_A_t[loop_ub] = t8 + dv[loop_ub];
      }
    }
    memcpy(&c_Y[0], &y[77], 21U * sizeof(double));
    for (i2 = 0; i2 < 7; i2++) {
      for (i3 = 0; i3 < 3; i3++) {
        t8 = 0.0;
        for (i1 = 0; i1 < 7; i1++) {
          t8 += A_t[i2 + 7 * i1] * c_Y[i1 + 7 * i3];
        }
        loop_ub = i2 + 7 * i3;
        d_A_t[loop_ub] = t8 + dv[loop_ub] * 0.0;
      }
    }
    F[294] = y[3];
    F[295] = y[4];
    F[296] = y[5];
    F[297] = -y[0] * t7 + b_t7_tmp * u[0] * 0.056196496465355988;
    F[298] = -y[1] * t7 + b_t7_tmp * u[1] * 0.056196496465355988;
    F[299] = -y[2] * t7 + b_t7_tmp * u[2] * 0.056196496465355988;
    F[300] = t8_tmp * -0.0426725757873853;
    memcpy(&F[301], &b_A_t[0], 49U * sizeof(double));
    for (i1 = 0; i1 < 21; i1++) {
      F[i1 + 350] = c_A_t[i1];
      F[i1 + 371] = d_A_t[i1];
    }
    t8 = hi / 6.0;
    for (i1 = 0; i1 < 98; i1++) {
      t7 = Y[i1];
      b_t7_tmp = t7 + t8 * (((F[i1] + 2.0 * F[i1 + 98]) + 2.0 * F[i1 + 196]) +
                            F[i1 + 294]);
      Y[i1 + 98] = b_t7_tmp;
      loop_ub = i1 << 1;
      b_y[loop_ub] = t7;
      b_y[loop_ub + 1] = b_t7_tmp;
    }
    /*  not necessary but it is what ODE45 does and code for extracting outputs
     * was made for that */
    /*  Unpack solution */
    /* ZERO_IF_EMPTY Summary of this function goes here */
    /*    Detailed explanation goes here */
    /* v(isempty(v)) = 0; */
    for (i1 = 0; i1 < 49; i1++) {
      b_Y[i1] = b_y[((i1 + 7) << 1) + 1];
    }
    for (i1 = 0; i1 < 49; i1++) {
      A_k_data[i1 + k * 49] = b_Y[i1];
    }
    for (i1 = 0; i1 < 21; i1++) {
      c_Y[i1] = b_y[((i1 + 56) << 1) + 1];
    }
    for (i1 = 0; i1 < 21; i1++) {
      B_k_plus_data[i1 + k * 21] = c_Y[i1];
    }
    for (i1 = 0; i1 < 21; i1++) {
      c_Y[i1] = b_y[((i1 + 77) << 1) + 1];
    }
    for (i1 = 0; i1 < 21; i1++) {
      B_k_minus_data[i1 + k * 21] = c_Y[i1];
    }
    for (i1 = 0; i1 < 49; i1++) {
      b_Y[i1] = b_y[((i1 + 7) << 1) + 1];
    }
    for (i1 = 0; i1 < 21; i1++) {
      c_Y[i1] = b_y[((i1 + 77) << 1) + 1];
    }
    memset(&c_y[0], 0, 7U * sizeof(double));
    for (i1 = 0; i1 < 7; i1++) {
      t8 = x_ref[i1 + 7 * k];
      r = _mm_loadu_pd(&b_Y[7 * i1]);
      r1 = _mm_loadu_pd(&c_y[0]);
      r3 = _mm_set1_pd(t8);
      _mm_storeu_pd(&c_y[0], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      r = _mm_loadu_pd(&b_Y[7 * i1 + 2]);
      r1 = _mm_loadu_pd(&c_y[2]);
      _mm_storeu_pd(&c_y[2], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      r = _mm_loadu_pd(&b_Y[7 * i1 + 4]);
      r1 = _mm_loadu_pd(&c_y[4]);
      _mm_storeu_pd(&c_y[4], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      c_y[6] += b_Y[7 * i1 + 6] * t8;
    }
    memset(&d_y[0], 0, 7U * sizeof(double));
    for (i1 = 0; i1 < 3; i1++) {
      r = _mm_loadu_pd(&c_Y[7 * i1]);
      r1 = _mm_loadu_pd(&d_y[0]);
      t8 = u_ref_k[i1];
      r3 = _mm_set1_pd(t8);
      _mm_storeu_pd(&d_y[0], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      r = _mm_loadu_pd(&c_Y[7 * i1 + 2]);
      r1 = _mm_loadu_pd(&d_y[2]);
      _mm_storeu_pd(&d_y[2], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      r = _mm_loadu_pd(&c_Y[7 * i1 + 4]);
      r1 = _mm_loadu_pd(&d_y[4]);
      _mm_storeu_pd(&d_y[4], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      d_y[6] += c_Y[7 * i1 + 6] * t8;
    }
    for (i1 = 0; i1 < 21; i1++) {
      c_Y[i1] = b_y[((i1 + 56) << 1) + 1];
    }
    t8 = u_ref_k[3];
    t7 = u_ref_k[4];
    b_t7_tmp = u_ref_k[5];
    for (i1 = 0; i1 < 7; i1++) {
      loop_ub = i1 + 7 * k;
      d_k_data[loop_ub] =
          b_y[(i1 << 1) + 1] -
          ((c_y[i1] + d_y[i1]) +
           ((c_Y[i1] * t8 + c_Y[i1 + 7] * t7) + c_Y[i1 + 14] * b_t7_tmp));
      Delta_data[loop_ub] = Y[i1 + 98] - x_ref[i1 + 7 * (k + 1)];
    }
  }
  emxFree_real_T(&t_k);
}

/*
 * File trailer for discretize_error_dynamics_FOH_kepler_fixedtf.c
 *
 * [EOF]
 */
