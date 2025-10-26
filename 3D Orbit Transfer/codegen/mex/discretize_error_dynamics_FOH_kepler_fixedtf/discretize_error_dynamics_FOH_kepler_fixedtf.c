/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * discretize_error_dynamics_FOH_kepler_fixedtf.c
 *
 * Code generation for function 'discretize_error_dynamics_FOH_kepler_fixedtf'
 *
 */

/* Include files */
#include "discretize_error_dynamics_FOH_kepler_fixedtf.h"
#include "A_kepler_fixedtf.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_data.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_emxutil.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_types.h"
#include "f_kepler_fixedtf.h"
#include "integrate_error_discrete_FOH_kepler_fixedtf.h"
#include "rt_nonfinite.h"
#include "mwmathutil.h"
#include "omp.h"
#include <emmintrin.h>
#include <string.h>

/* Variable Definitions */
static emlrtRSInfo emlrtRSI = {
    9,                                              /* lineNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fcnName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m" /* pathName */
};

static emlrtRSInfo b_emlrtRSI = {
    19,                                             /* lineNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fcnName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m" /* pathName */
};

static emlrtRTEInfo emlrtRTEI = {
    17,                                             /* lineNo */
    13,                                             /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m" /* pName */
};

static emlrtBCInfo emlrtBCI = {
    1,                                              /* iFirst */
    15,                                             /* iLast */
    18,                                             /* lineNo */
    29,                                             /* colNo */
    "u_ref",                                        /* aName */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    0      /* checkKind */
};

static emlrtBCInfo b_emlrtBCI = {
    1,                                              /* iFirst */
    15,                                             /* iLast */
    18,                                             /* lineNo */
    42,                                             /* colNo */
    "u_ref",                                        /* aName */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    0      /* checkKind */
};

static emlrtBCInfo c_emlrtBCI = {
    1,                                              /* iFirst */
    15,                                             /* iLast */
    20,                                             /* lineNo */
    40,                                             /* colNo */
    "x_ref",                                        /* aName */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    0      /* checkKind */
};

static emlrtBCInfo d_emlrtBCI = {
    -1,                                             /* iFirst */
    -1,                                             /* iLast */
    19,                                             /* lineNo */
    20,                                             /* colNo */
    "A_k",                                          /* aName */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    0      /* checkKind */
};

static emlrtBCInfo e_emlrtBCI = {
    -1,                                             /* iFirst */
    -1,                                             /* iLast */
    19,                                             /* lineNo */
    73,                                             /* colNo */
    "S_k",                                          /* aName */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    0      /* checkKind */
};

static emlrtBCInfo f_emlrtBCI = {
    -1,                                             /* iFirst */
    -1,                                             /* iLast */
    20,                                             /* lineNo */
    18,                                             /* colNo */
    "Delta",                                        /* aName */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    0      /* checkKind */
};

static emlrtRTEInfo b_emlrtRTEI = {
    31,         /* lineNo */
    33,         /* colNo */
    "linspace", /* fName */
    "C:\\Program "
    "Files\\MATLAB\\R2025a\\toolbox\\eml\\lib\\matlab\\elmat\\linspace.m" /* pName
                                                                           */
};

static emlrtDCInfo emlrtDCI = {
    14,                                             /* lineNo */
    17,                                             /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    1      /* checkKind */
};

static emlrtDCInfo b_emlrtDCI = {
    10,                                             /* lineNo */
    17,                                             /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    4      /* checkKind */
};

static emlrtDCInfo c_emlrtDCI = {
    10,                                             /* lineNo */
    17,                                             /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    1      /* checkKind */
};

static emlrtDCInfo d_emlrtDCI = {
    11,                                             /* lineNo */
    22,                                             /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    1      /* checkKind */
};

static emlrtDCInfo e_emlrtDCI = {
    12,                                             /* lineNo */
    23,                                             /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    1      /* checkKind */
};

static emlrtDCInfo f_emlrtDCI = {
    13,                                             /* lineNo */
    17,                                             /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    1      /* checkKind */
};

static emlrtDCInfo g_emlrtDCI = {
    15,                                             /* lineNo */
    19,                                             /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    1      /* checkKind */
};

static emlrtBCInfo g_emlrtBCI = {
    -1,                                             /* iFirst */
    -1,                                             /* iLast */
    19,                                             /* lineNo */
    174,                                            /* colNo */
    "t_k",                                          /* aName */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    0      /* checkKind */
};

static emlrtBCInfo h_emlrtBCI = {
    -1,                                             /* iFirst */
    -1,                                             /* iLast */
    19,                                             /* lineNo */
    182,                                            /* colNo */
    "t_k",                                          /* aName */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m", /* pName */
    0      /* checkKind */
};

static emlrtRTEInfo c_emlrtRTEI = {
    45,         /* lineNo */
    20,         /* colNo */
    "linspace", /* fName */
    "C:\\Program "
    "Files\\MATLAB\\R2025a\\toolbox\\eml\\lib\\matlab\\elmat\\linspace.m" /* pName
                                                                           */
};

static emlrtRTEInfo d_emlrtRTEI = {
    10,                                             /* lineNo */
    5,                                              /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m" /* pName */
};

static emlrtRTEInfo e_emlrtRTEI = {
    11,                                             /* lineNo */
    5,                                              /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m" /* pName */
};

static emlrtRTEInfo f_emlrtRTEI = {
    12,                                             /* lineNo */
    5,                                              /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m" /* pName */
};

static emlrtRTEInfo g_emlrtRTEI = {
    14,                                             /* lineNo */
    5,                                              /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m" /* pName */
};

static emlrtRTEInfo h_emlrtRTEI = {
    15,                                             /* lineNo */
    5,                                              /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m" /* pName */
};

static emlrtRTEInfo i_emlrtRTEI = {
    9,                                              /* lineNo */
    5,                                              /* colNo */
    "discretize_error_dynamics_FOH_kepler_fixedtf", /* fName */
    "C:\\Users\\thatf\\OneDrive\\Documents\\ASA\\PSP-ASA-GTOC12-"
    "Problem\\Asteroid Mining\\discretize_error_dynamics_FOH_kepler_fixedt"
    "f.m" /* pName */
};

/* Function Definitions */
void discretize_error_dynamics_FOH_kepler_fixedtf(
    const emlrtStack *sp, real_T N, const real_T tspan[2],
    const real_T x_ref[105], const real_T u_ref[45], emxArray_real_T *A_k,
    emxArray_real_T *B_k_plus, emxArray_real_T *B_k_minus, emxArray_real_T *S_k,
    emxArray_real_T *d_k, emxArray_real_T *Delta)
{
  static const int8_T iv[49] = {
      1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1};
  __m128d r;
  __m128d r1;
  jmp_buf *volatile emlrtJBStack;
  emlrtStack st;
  emxArray_real_T *t_k;
  real_T F[392];
  real_T b_Y[196];
  real_T Y[98];
  real_T A_t[49];
  real_T b_A_t[49];
  real_T c_Y[49];
  real_T d_Y[21];
  real_T b_y[7];
  real_T xdot[7];
  real_T u_ref_k[6];
  real_T u[3];
  real_T dv[2];
  real_T hi;
  real_T t7;
  real_T t8;
  real_T *A_k_data;
  real_T *B_k_minus_data;
  real_T *B_k_plus_data;
  real_T *Delta_data;
  real_T *d_k_data;
  real_T *t_k_data;
  int32_T b_k;
  int32_T b_loop_ub;
  int32_T c_k;
  int32_T discretize_error_dynamics_FOH_kepler_fixedtf_numThreads;
  int32_T i;
  int32_T i1;
  int32_T i2;
  int32_T k;
  int32_T loop_ub;
  int32_T nm1;
  st.prev = sp;
  st.tls = sp->tls;
  emlrtHeapReferenceStackEnterFcnR2012b((emlrtConstCTX)sp);
  /*  Discretization of the devition from a reference trajectory for a dynamical
   * system assuming FOH control */
  /*  Make c optional? c = f - Ax - Bu */
  st.site = &emlrtRSI;
  t8 = tspan[0];
  if (muDoubleScalarIsNaN(N)) {
    emlrtErrorWithMessageIdR2018a(&st, &b_emlrtRTEI,
                                  "Coder:toolbox:MustNotBeNaN",
                                  "Coder:toolbox:MustNotBeNaN", 3, 4, 1, "N");
  }
  emxInit_real_T(&st, &t_k, 2, &i_emlrtRTEI);
  t_k_data = t_k->data;
  if (N < 1.0) {
    t_k->size[0] = 1;
    t_k->size[1] = 0;
  } else {
    loop_ub = t_k->size[0] * t_k->size[1];
    t_k->size[0] = 1;
    nm1 = (int32_T)muDoubleScalarFloor(N);
    t_k->size[1] = nm1;
    emxEnsureCapacity_real_T(&st, t_k, loop_ub, &c_emlrtRTEI);
    t_k_data = t_k->data;
    t_k_data[nm1 - 1] = tspan[1];
    if (t_k->size[1] >= 2) {
      t_k_data[0] = tspan[0];
      if (t_k->size[1] >= 3) {
        if (tspan[0] == -tspan[1]) {
          t8 = tspan[1] / ((real_T)t_k->size[1] - 1.0);
          if (t_k->size[1] - 2 < 1600) {
            for (k = 2; k < nm1; k++) {
              t_k_data[k - 1] = (real_T)(((k << 1) - t_k->size[1]) - 1) * t8;
            }
          } else {
            emlrtEnterParallelRegion(&st, omp_in_parallel());
            emlrtPushJmpBuf(&st, &emlrtJBStack);
            discretize_error_dynamics_FOH_kepler_fixedtf_numThreads =
                emlrtAllocRegionTLSs(st.tls, omp_in_parallel(),
                                     omp_get_max_threads(),
                                     omp_get_num_procs());
#pragma omp parallel for num_threads(                                          \
        discretize_error_dynamics_FOH_kepler_fixedtf_numThreads)

            for (k = 2; k < nm1; k++) {
              t_k_data[k - 1] = (real_T)(((k << 1) - t_k->size[1]) - 1) * t8;
            }
            emlrtPopJmpBuf(&st, &emlrtJBStack);
            emlrtExitParallelRegion(&st, omp_in_parallel());
          }
          if (((uint32_T)t_k->size[1] & 1U) == 1U) {
            t_k_data[t_k->size[1] >> 1] = 0.0;
          }
        } else if (((tspan[0] < 0.0) != (tspan[1] < 0.0)) &&
                   ((muDoubleScalarAbs(tspan[0]) > 8.9884656743115785E+307) ||
                    (muDoubleScalarAbs(tspan[1]) > 8.9884656743115785E+307))) {
          t7 = tspan[0] / ((real_T)t_k->size[1] - 1.0);
          hi = tspan[1] / ((real_T)t_k->size[1] - 1.0);
          loop_ub = ((t_k->size[1] - 2) / 2) << 1;
          b_loop_ub = loop_ub - 2;
          for (b_k = 0; b_k <= b_loop_ub; b_k += 2) {
            dv[0] = b_k + 1;
            dv[1] = b_k + 2;
            r = _mm_loadu_pd(&dv[0]);
            dv[0] = b_k + 1;
            dv[1] = b_k + 2;
            r1 = _mm_loadu_pd(&dv[0]);
            _mm_storeu_pd(&t_k_data[b_k + 1],
                          _mm_sub_pd(_mm_add_pd(_mm_set1_pd(t8),
                                                _mm_mul_pd(_mm_set1_pd(hi), r)),
                                     _mm_mul_pd(_mm_set1_pd(t7), r1)));
          }
          for (b_k = loop_ub; b_k <= nm1 - 3; b_k++) {
            t_k_data[b_k + 1] =
                (t8 + hi * (real_T)(b_k + 1)) - t7 * (real_T)(b_k + 1);
          }
        } else {
          t7 = (tspan[1] - tspan[0]) / ((real_T)t_k->size[1] - 1.0);
          loop_ub = ((t_k->size[1] - 2) / 2) << 1;
          b_loop_ub = loop_ub - 2;
          for (b_k = 0; b_k <= b_loop_ub; b_k += 2) {
            dv[0] = b_k + 1;
            dv[1] = b_k + 2;
            r = _mm_loadu_pd(&dv[0]);
            _mm_storeu_pd(
                &t_k_data[b_k + 1],
                _mm_add_pd(_mm_set1_pd(t8), _mm_mul_pd(r, _mm_set1_pd(t7))));
          }
          for (b_k = loop_ub; b_k <= nm1 - 3; b_k++) {
            t_k_data[b_k + 1] = t8 + (real_T)(b_k + 1) * t7;
          }
        }
      }
    }
  }
  if (!(N - 1.0 >= 0.0)) {
    emlrtNonNegativeCheckR2012b(N - 1.0, &b_emlrtDCI, (emlrtConstCTX)sp);
  }
  nm1 = (int32_T)muDoubleScalarFloor(N - 1.0);
  if (N - 1.0 != nm1) {
    emlrtIntegerCheckR2012b(N - 1.0, &c_emlrtDCI, (emlrtConstCTX)sp);
  }
  loop_ub = A_k->size[0] * A_k->size[1] * A_k->size[2];
  A_k->size[0] = 7;
  A_k->size[1] = 7;
  i = (int32_T)(N - 1.0);
  A_k->size[2] = (int32_T)(N - 1.0);
  emxEnsureCapacity_real_T(sp, A_k, loop_ub, &d_emlrtRTEI);
  A_k_data = A_k->data;
  loop_ub = 49 * (int32_T)(N - 1.0);
  for (b_k = 0; b_k < loop_ub; b_k++) {
    A_k_data[b_k] = 0.0;
  }
  if (N - 1.0 != nm1) {
    emlrtIntegerCheckR2012b(N - 1.0, &d_emlrtDCI, (emlrtConstCTX)sp);
  }
  loop_ub = B_k_plus->size[0] * B_k_plus->size[1] * B_k_plus->size[2];
  B_k_plus->size[0] = 7;
  B_k_plus->size[1] = 3;
  B_k_plus->size[2] = (int32_T)(N - 1.0);
  emxEnsureCapacity_real_T(sp, B_k_plus, loop_ub, &e_emlrtRTEI);
  B_k_plus_data = B_k_plus->data;
  b_loop_ub = 21 * (int32_T)(N - 1.0);
  for (b_k = 0; b_k < b_loop_ub; b_k++) {
    B_k_plus_data[b_k] = 0.0;
  }
  if (N - 1.0 != nm1) {
    emlrtIntegerCheckR2012b(N - 1.0, &e_emlrtDCI, (emlrtConstCTX)sp);
  }
  loop_ub = B_k_minus->size[0] * B_k_minus->size[1] * B_k_minus->size[2];
  B_k_minus->size[0] = 7;
  B_k_minus->size[1] = 3;
  B_k_minus->size[2] = (int32_T)(N - 1.0);
  emxEnsureCapacity_real_T(sp, B_k_minus, loop_ub, &f_emlrtRTEI);
  B_k_minus_data = B_k_minus->data;
  for (b_k = 0; b_k < b_loop_ub; b_k++) {
    B_k_minus_data[b_k] = 0.0;
  }
  if (N - 1.0 != nm1) {
    emlrtIntegerCheckR2012b(N - 1.0, &f_emlrtDCI, (emlrtConstCTX)sp);
  }
  S_k->size[0] = 7;
  S_k->size[1] = 0;
  S_k->size[2] = (int32_T)(N - 1.0);
  if (N - 1.0 != nm1) {
    emlrtIntegerCheckR2012b(N - 1.0, &emlrtDCI, (emlrtConstCTX)sp);
  }
  loop_ub = d_k->size[0] * d_k->size[1] * d_k->size[2];
  d_k->size[0] = 7;
  d_k->size[1] = 1;
  d_k->size[2] = (int32_T)(N - 1.0);
  emxEnsureCapacity_real_T(sp, d_k, loop_ub, &g_emlrtRTEI);
  d_k_data = d_k->data;
  b_loop_ub = 7 * (int32_T)(N - 1.0);
  for (b_k = 0; b_k < b_loop_ub; b_k++) {
    d_k_data[b_k] = 0.0;
  }
  if (N - 1.0 != nm1) {
    emlrtIntegerCheckR2012b(N - 1.0, &g_emlrtDCI, (emlrtConstCTX)sp);
  }
  loop_ub = Delta->size[0] * Delta->size[1];
  Delta->size[0] = 7;
  Delta->size[1] = (int32_T)(N - 1.0);
  emxEnsureCapacity_real_T(sp, Delta, loop_ub, &h_emlrtRTEI);
  Delta_data = Delta->data;
  for (b_k = 0; b_k < b_loop_ub; b_k++) {
    Delta_data[b_k] = 0.0;
  }
  emlrtForLoopVectorCheckR2021a(1.0, 1.0, N - 1.0, mxDOUBLE_CLASS,
                                (int32_T)(N - 1.0), &emlrtRTEI,
                                (emlrtConstCTX)sp);
  if ((int32_T)(N - 1.0) - 1 >= 0) {
  }
  for (c_k = 0; c_k < i; c_k++) {
    __m128d r2;
    __m128d r3;
    real_T y[196];
    real_T B_t[21];
    real_T c_A_t[21];
    real_T d_A_t[21];
    boolean_T b;
    if (((int32_T)((uint32_T)c_k + 1U) < 1) ||
        ((int32_T)((uint32_T)c_k + 1U) > 15)) {
      emlrtDynamicBoundsCheckR2012b((int32_T)((uint32_T)c_k + 1U), 1, 15,
                                    &emlrtBCI, (emlrtConstCTX)sp);
    }
    b = (((int32_T)((uint32_T)c_k + 2U) < 1) ||
         ((int32_T)((uint32_T)c_k + 2U) > 15));
    if (b) {
      emlrtDynamicBoundsCheckR2012b((int32_T)((uint32_T)c_k + 2U), 1, 15,
                                    &b_emlrtBCI, (emlrtConstCTX)sp);
    }
    loop_ub = 3 * c_k;
    u_ref_k[0] = u_ref[loop_ub];
    b_loop_ub = 3 * (c_k + 1);
    u_ref_k[3] = u_ref[b_loop_ub];
    u_ref_k[1] = u_ref[loop_ub + 1];
    u_ref_k[4] = u_ref[b_loop_ub + 1];
    u_ref_k[2] = u_ref[loop_ub + 2];
    u_ref_k[5] = u_ref[b_loop_ub + 2];
    st.site = &b_emlrtRSI;
    if (((int32_T)((uint32_T)c_k + 1U) < 1) ||
        ((int32_T)((uint32_T)c_k + 1U) > t_k->size[1])) {
      emlrtDynamicBoundsCheckR2012b((int32_T)((uint32_T)c_k + 1U), 1,
                                    t_k->size[1], &g_emlrtBCI, &st);
    }
    if (((int32_T)((uint32_T)c_k + 2U) < 1) ||
        ((int32_T)((uint32_T)c_k + 2U) > t_k->size[1])) {
      emlrtDynamicBoundsCheckR2012b((int32_T)((uint32_T)c_k + 2U), 1,
                                    t_k->size[1], &h_emlrtBCI, &st);
    }
    /*  Integrates STM and state with Bk+, Bk-, and ck */
    /*    Uses RK4 to integrate the State Transition Matrix and the state using
     */
    /*    the given A matrix and dynamics f over the time period in tspan */
    /*  Create initial condition */
    /*  Simulate     */
    memset(&b_Y[0], 0, 196U * sizeof(real_T));
    memset(&F[0], 0, 392U * sizeof(real_T));
    for (b_k = 0; b_k < 7; b_k++) {
      b_Y[b_k] = x_ref[b_k + 7 * c_k];
    }
    for (b_k = 0; b_k < 49; b_k++) {
      b_Y[b_k + 7] = iv[b_k];
    }
    for (b_k = 0; b_k < 21; b_k++) {
      b_Y[b_k + 56] = 0.0;
      b_Y[b_k + 77] = 0.0;
    }
    hi = t_k_data[c_k + 1] - t_k_data[c_k];
    r = _mm_loadu_pd(&u_ref_k[3]);
    r1 = _mm_loadu_pd(&u_ref_k[0]);
    r2 = _mm_set1_pd(0.0);
    _mm_storeu_pd(&u[0], _mm_add_pd(r1, _mm_mul_pd(r, r2)));
    u[2] = u_ref_k[2] + u_ref_k[5] * 0.0;
    A_kepler_fixedtf(&b_Y[0], u, A_t);
    /* B_kepler_fixedtf */
    /*     J_B = B_kepler_fixedtf(T,IN2,IN3,IN4) */
    /*     This function was generated by the Symbolic Math Toolbox
     * version 25.1. */
    /*     07-Sep-2025 00:01:12 */
    t8 = 1.0 / b_Y[6] * 0.056196496465355988;
    t7 = 1.0 / muDoubleScalarSqrt((u[0] * u[0] + u[1] * u[1]) + u[2] * u[2]);
    B_t[0] = 0.0;
    B_t[1] = 0.0;
    B_t[2] = 0.0;
    B_t[3] = t8;
    B_t[4] = 0.0;
    B_t[5] = 0.0;
    B_t[6] = t7 * u[0] * -0.0426725757873853;
    B_t[7] = 0.0;
    B_t[8] = 0.0;
    B_t[9] = 0.0;
    B_t[10] = 0.0;
    B_t[11] = t8;
    B_t[12] = 0.0;
    B_t[13] = t7 * u[1] * -0.0426725757873853;
    B_t[14] = 0.0;
    B_t[15] = 0.0;
    B_t[16] = 0.0;
    B_t[17] = 0.0;
    B_t[18] = 0.0;
    B_t[19] = t8;
    B_t[20] = t7 * u[2] * -0.0426725757873853;
    f_kepler_fixedtf(&b_Y[0], u, xdot);
    memcpy(&c_Y[0], &b_Y[7], 49U * sizeof(real_T));
    memset(&b_A_t[0], 0, 49U * sizeof(real_T));
    for (b_k = 0; b_k < 7; b_k++) {
      loop_ub = 7 * b_k + 2;
      b_loop_ub = 7 * b_k + 4;
      nm1 = 7 * b_k + 6;
      for (i1 = 0; i1 < 7; i1++) {
        t8 = c_Y[i1 + 7 * b_k];
        r = _mm_loadu_pd(&A_t[7 * i1]);
        r1 = _mm_loadu_pd(&b_A_t[7 * b_k]);
        r3 = _mm_set1_pd(t8);
        _mm_storeu_pd(&b_A_t[7 * b_k], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i1 + 2]);
        r1 = _mm_loadu_pd(&b_A_t[loop_ub]);
        _mm_storeu_pd(&b_A_t[loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i1 + 4]);
        r1 = _mm_loadu_pd(&b_A_t[b_loop_ub]);
        _mm_storeu_pd(&b_A_t[b_loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        b_A_t[nm1] += A_t[7 * i1 + 6] * t8;
      }
    }
    memcpy(&d_Y[0], &b_Y[56], 21U * sizeof(real_T));
    for (i1 = 0; i1 < 7; i1++) {
      for (i2 = 0; i2 < 3; i2++) {
        t8 = 0.0;
        for (b_k = 0; b_k < 7; b_k++) {
          t8 += A_t[i1 + 7 * b_k] * d_Y[b_k + 7 * i2];
        }
        loop_ub = i1 + 7 * i2;
        c_A_t[loop_ub] = t8 + B_t[loop_ub] * 0.0;
      }
    }
    memcpy(&d_Y[0], &b_Y[77], 21U * sizeof(real_T));
    for (i1 = 0; i1 < 7; i1++) {
      for (i2 = 0; i2 < 3; i2++) {
        t8 = 0.0;
        for (b_k = 0; b_k < 7; b_k++) {
          t8 += A_t[i1 + 7 * b_k] * d_Y[b_k + 7 * i2];
        }
        loop_ub = i1 + 7 * i2;
        d_A_t[loop_ub] = t8 + B_t[loop_ub];
      }
      F[i1] = xdot[i1];
    }
    memcpy(&F[7], &b_A_t[0], 49U * sizeof(real_T));
    for (b_k = 0; b_k < 21; b_k++) {
      F[b_k + 56] = c_A_t[b_k];
      F[b_k + 77] = d_A_t[b_k];
    }
    t8 = 0.5 * hi;
    for (b_k = 0; b_k <= 96; b_k += 2) {
      r = _mm_loadu_pd(&F[b_k]);
      r1 = _mm_loadu_pd(&b_Y[b_k]);
      _mm_storeu_pd(&Y[b_k], _mm_add_pd(r1, _mm_mul_pd(_mm_set1_pd(t8), r)));
    }
    STM_diff_eq_FOH(Y, u_ref_k, &F[98]);
    for (b_k = 0; b_k <= 96; b_k += 2) {
      r = _mm_loadu_pd(&F[b_k + 98]);
      r1 = _mm_loadu_pd(&b_Y[b_k]);
      _mm_storeu_pd(&Y[b_k], _mm_add_pd(r1, _mm_mul_pd(_mm_set1_pd(t8), r)));
    }
    STM_diff_eq_FOH(Y, u_ref_k, &F[196]);
    for (b_k = 0; b_k <= 96; b_k += 2) {
      r = _mm_loadu_pd(&F[b_k + 196]);
      r1 = _mm_loadu_pd(&b_Y[b_k]);
      _mm_storeu_pd(&Y[b_k], _mm_add_pd(r1, _mm_mul_pd(_mm_set1_pd(hi), r)));
    }
    r = _mm_loadu_pd(&u_ref_k[0]);
    r1 = _mm_loadu_pd(&u_ref_k[3]);
    _mm_storeu_pd(&u[0], _mm_add_pd(_mm_mul_pd(r, r2), r1));
    u[2] = u_ref_k[2] * 0.0 + u_ref_k[5];
    A_kepler_fixedtf(&Y[0], u, A_t);
    /* B_kepler_fixedtf */
    /*     J_B = B_kepler_fixedtf(T,IN2,IN3,IN4) */
    /*     This function was generated by the Symbolic Math Toolbox
     * version 25.1. */
    /*     07-Sep-2025 00:01:12 */
    t8 = 1.0 / Y[6] * 0.056196496465355988;
    t7 = 1.0 / muDoubleScalarSqrt((u[0] * u[0] + u[1] * u[1]) + u[2] * u[2]);
    B_t[0] = 0.0;
    B_t[1] = 0.0;
    B_t[2] = 0.0;
    B_t[3] = t8;
    B_t[4] = 0.0;
    B_t[5] = 0.0;
    B_t[6] = t7 * u[0] * -0.0426725757873853;
    B_t[7] = 0.0;
    B_t[8] = 0.0;
    B_t[9] = 0.0;
    B_t[10] = 0.0;
    B_t[11] = t8;
    B_t[12] = 0.0;
    B_t[13] = t7 * u[1] * -0.0426725757873853;
    B_t[14] = 0.0;
    B_t[15] = 0.0;
    B_t[16] = 0.0;
    B_t[17] = 0.0;
    B_t[18] = 0.0;
    B_t[19] = t8;
    B_t[20] = t7 * u[2] * -0.0426725757873853;
    f_kepler_fixedtf(&Y[0], u, xdot);
    memcpy(&c_Y[0], &Y[7], 49U * sizeof(real_T));
    memset(&b_A_t[0], 0, 49U * sizeof(real_T));
    for (b_k = 0; b_k < 7; b_k++) {
      loop_ub = 7 * b_k + 2;
      b_loop_ub = 7 * b_k + 4;
      nm1 = 7 * b_k + 6;
      for (i2 = 0; i2 < 7; i2++) {
        t8 = c_Y[i2 + 7 * b_k];
        r = _mm_loadu_pd(&A_t[7 * i2]);
        r1 = _mm_loadu_pd(&b_A_t[7 * b_k]);
        r3 = _mm_set1_pd(t8);
        _mm_storeu_pd(&b_A_t[7 * b_k], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i2 + 2]);
        r1 = _mm_loadu_pd(&b_A_t[loop_ub]);
        _mm_storeu_pd(&b_A_t[loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        r = _mm_loadu_pd(&A_t[7 * i2 + 4]);
        r1 = _mm_loadu_pd(&b_A_t[b_loop_ub]);
        _mm_storeu_pd(&b_A_t[b_loop_ub], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
        b_A_t[nm1] += A_t[7 * i2 + 6] * t8;
      }
    }
    memcpy(&d_Y[0], &Y[56], 21U * sizeof(real_T));
    for (i1 = 0; i1 < 7; i1++) {
      for (i2 = 0; i2 < 3; i2++) {
        t8 = 0.0;
        for (b_k = 0; b_k < 7; b_k++) {
          t8 += A_t[i1 + 7 * b_k] * d_Y[b_k + 7 * i2];
        }
        loop_ub = i1 + 7 * i2;
        c_A_t[loop_ub] = t8 + B_t[loop_ub];
      }
    }
    memcpy(&d_Y[0], &Y[77], 21U * sizeof(real_T));
    for (i1 = 0; i1 < 7; i1++) {
      for (i2 = 0; i2 < 3; i2++) {
        t8 = 0.0;
        for (b_k = 0; b_k < 7; b_k++) {
          t8 += A_t[i1 + 7 * b_k] * d_Y[b_k + 7 * i2];
        }
        loop_ub = i1 + 7 * i2;
        d_A_t[loop_ub] = t8 + B_t[loop_ub] * 0.0;
      }
      F[i1 + 294] = xdot[i1];
    }
    memcpy(&F[301], &b_A_t[0], 49U * sizeof(real_T));
    for (b_k = 0; b_k < 21; b_k++) {
      F[b_k + 350] = c_A_t[b_k];
      F[b_k + 371] = d_A_t[b_k];
    }
    t8 = hi / 6.0;
    for (b_k = 0; b_k < 98; b_k++) {
      t7 = b_Y[b_k];
      hi = t7 + t8 * (((F[b_k] + 2.0 * F[b_k + 98]) + 2.0 * F[b_k + 196]) +
                      F[b_k + 294]);
      b_Y[b_k + 98] = hi;
      loop_ub = b_k << 1;
      y[loop_ub] = t7;
      y[loop_ub + 1] = hi;
    }
    /*  not necessary but it is what ODE45 does and code for extracting outputs
     * was made for that */
    /*  Unpack solution */
    /* ZERO_IF_EMPTY Summary of this function goes here */
    /*    Detailed explanation goes here */
    /* v(isempty(v)) = 0; */
    for (b_k = 0; b_k < 49; b_k++) {
      c_Y[b_k] = y[((b_k + 7) << 1) + 1];
    }
    if (((int32_T)((uint32_T)c_k + 1U) < 1) ||
        ((int32_T)((uint32_T)c_k + 1U) > (int32_T)(N - 1.0))) {
      emlrtDynamicBoundsCheckR2012b((int32_T)((uint32_T)c_k + 1U), 1,
                                    (int32_T)(N - 1.0), &d_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    for (b_k = 0; b_k < 49; b_k++) {
      A_k_data[b_k + c_k * 49] = c_Y[b_k];
    }
    for (b_k = 0; b_k < 21; b_k++) {
      d_Y[b_k] = y[((b_k + 56) << 1) + 1];
    }
    for (b_k = 0; b_k < 21; b_k++) {
      B_k_plus_data[b_k + c_k * 21] = d_Y[b_k];
    }
    for (b_k = 0; b_k < 21; b_k++) {
      d_Y[b_k] = y[((b_k + 77) << 1) + 1];
    }
    for (b_k = 0; b_k < 21; b_k++) {
      B_k_minus_data[b_k + c_k * 21] = d_Y[b_k];
    }
    if ((c_k + 1 < 1) || (c_k + 1 > (int32_T)(N - 1.0))) {
      emlrtDynamicBoundsCheckR2012b(c_k + 1, 1, (int32_T)(N - 1.0), &e_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    for (b_k = 0; b_k < 49; b_k++) {
      c_Y[b_k] = y[((b_k + 7) << 1) + 1];
    }
    for (b_k = 0; b_k < 21; b_k++) {
      d_Y[b_k] = y[((b_k + 77) << 1) + 1];
    }
    memset(&xdot[0], 0, 7U * sizeof(real_T));
    for (b_k = 0; b_k < 7; b_k++) {
      t8 = x_ref[b_k + 7 * c_k];
      r = _mm_loadu_pd(&c_Y[7 * b_k]);
      r1 = _mm_loadu_pd(&xdot[0]);
      r3 = _mm_set1_pd(t8);
      _mm_storeu_pd(&xdot[0], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      r = _mm_loadu_pd(&c_Y[7 * b_k + 2]);
      r1 = _mm_loadu_pd(&xdot[2]);
      _mm_storeu_pd(&xdot[2], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      r = _mm_loadu_pd(&c_Y[7 * b_k + 4]);
      r1 = _mm_loadu_pd(&xdot[4]);
      _mm_storeu_pd(&xdot[4], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      xdot[6] += c_Y[7 * b_k + 6] * t8;
    }
    memset(&b_y[0], 0, 7U * sizeof(real_T));
    for (b_k = 0; b_k < 3; b_k++) {
      r = _mm_loadu_pd(&d_Y[7 * b_k]);
      r1 = _mm_loadu_pd(&b_y[0]);
      t8 = u_ref_k[b_k];
      r3 = _mm_set1_pd(t8);
      _mm_storeu_pd(&b_y[0], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      r = _mm_loadu_pd(&d_Y[7 * b_k + 2]);
      r1 = _mm_loadu_pd(&b_y[2]);
      _mm_storeu_pd(&b_y[2], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      r = _mm_loadu_pd(&d_Y[7 * b_k + 4]);
      r1 = _mm_loadu_pd(&b_y[4]);
      _mm_storeu_pd(&b_y[4], _mm_add_pd(r1, _mm_mul_pd(r, r3)));
      b_y[6] += d_Y[7 * b_k + 6] * t8;
    }
    for (b_k = 0; b_k < 21; b_k++) {
      d_Y[b_k] = y[((b_k + 56) << 1) + 1];
    }
    t8 = u_ref_k[3];
    t7 = u_ref_k[4];
    hi = u_ref_k[5];
    for (b_k = 0; b_k < 7; b_k++) {
      d_k_data[b_k + 7 * c_k] =
          y[(b_k << 1) + 1] -
          ((xdot[b_k] + b_y[b_k]) +
           ((d_Y[b_k] * t8 + d_Y[b_k + 7] * t7) + d_Y[b_k + 14] * hi));
    }
    if (b) {
      emlrtDynamicBoundsCheckR2012b((int32_T)((uint32_T)c_k + 2U), 1, 15,
                                    &c_emlrtBCI, (emlrtConstCTX)sp);
    }
    if (((int32_T)((uint32_T)c_k + 1U) < 1) ||
        ((int32_T)((uint32_T)c_k + 1U) > Delta->size[1])) {
      emlrtDynamicBoundsCheckR2012b((int32_T)((uint32_T)c_k + 1U), 1,
                                    Delta->size[1], &f_emlrtBCI,
                                    (emlrtConstCTX)sp);
    }
    r = _mm_loadu_pd(&b_Y[98]);
    loop_ub = 7 * (c_k + 1);
    _mm_storeu_pd(&Delta_data[7 * c_k],
                  _mm_sub_pd(r, _mm_loadu_pd(&x_ref[loop_ub])));
    r = _mm_loadu_pd(&b_Y[100]);
    _mm_storeu_pd(&Delta_data[7 * c_k + 2],
                  _mm_sub_pd(r, _mm_loadu_pd(&x_ref[loop_ub + 2])));
    r = _mm_loadu_pd(&b_Y[102]);
    _mm_storeu_pd(&Delta_data[7 * c_k + 4],
                  _mm_sub_pd(r, _mm_loadu_pd(&x_ref[loop_ub + 4])));
    Delta_data[7 * c_k + 6] = b_Y[104] - x_ref[loop_ub + 6];
    if (*emlrtBreakCheckR2012bFlagVar != 0) {
      emlrtBreakCheckR2012b((emlrtConstCTX)sp);
    }
  }
  emxFree_real_T(sp, &t_k);
  emlrtHeapReferenceStackLeaveFcnR2012b((emlrtConstCTX)sp);
}

emlrtCTX emlrtGetRootTLSGlobal(void)
{
  return emlrtRootTLSGlobal;
}

void emlrtLockerFunction(EmlrtLockeeFunction aLockee, emlrtConstCTX aTLS,
                         void *aData)
{
  omp_set_lock(&emlrtLockGlobal);
  emlrtCallLockeeFunction(aLockee, aTLS, aData);
  omp_unset_lock(&emlrtLockGlobal);
}

/* End of code generation (discretize_error_dynamics_FOH_kepler_fixedtf.c) */
