/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: main.c
 *
 * MATLAB Coder version            : 25.1
 * C/C++ source code generated on  : 07-Sep-2025 00:38:53
 */

/*************************************************************************/
/* This automatically generated example C main file shows how to call    */
/* entry-point functions that MATLAB Coder generated. You must customize */
/* this file for your application. Do not modify this file directly.     */
/* Instead, make a copy of this file, modify it, and integrate it into   */
/* your development environment.                                         */
/*                                                                       */
/* This file initializes entry-point function arguments to a default     */
/* size and value before calling the entry-point functions. It does      */
/* not store or use any values returned from the entry-point functions.  */
/* If necessary, it does pre-allocate memory for returned values.        */
/* You can use this file as a starting point for a main function that    */
/* you can deploy in your application.                                   */
/*                                                                       */
/* After you copy the file, and before you deploy it, you must make the  */
/* following changes:                                                    */
/* * For variable-size function arguments, change the example sizes to   */
/* the sizes that your application requires.                             */
/* * Change the example values of function arguments to the values that  */
/* your application requires.                                            */
/* * If the entry-point functions return values, store these values or   */
/* otherwise use them as required by your application.                   */
/*                                                                       */
/*************************************************************************/

/* Include Files */
#include "main.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_emxAPI.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_initialize.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_terminate.h"
#include "discretize_error_dynamics_FOH_kepler_fixedtf_types.h"
#include "rt_nonfinite.h"

/* Function Declarations */
static void argInit_1x2_real_T(double result[2]);

static void argInit_3x15_real_T(double result[45]);

static void argInit_7x15_real_T(double result[105]);

static double argInit_real_T(void);

/* Function Definitions */
/*
 * Arguments    : double result[2]
 * Return Type  : void
 */
static void argInit_1x2_real_T(double result[2])
{
  int idx1;
  /* Loop over the array to initialize each element. */
  for (idx1 = 0; idx1 < 2; idx1++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[idx1] = argInit_real_T();
  }
}

/*
 * Arguments    : double result[45]
 * Return Type  : void
 */
static void argInit_3x15_real_T(double result[45])
{
  int i;
  /* Loop over the array to initialize each element. */
  for (i = 0; i < 45; i++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[i] = argInit_real_T();
  }
}

/*
 * Arguments    : double result[105]
 * Return Type  : void
 */
static void argInit_7x15_real_T(double result[105])
{
  int i;
  /* Loop over the array to initialize each element. */
  for (i = 0; i < 105; i++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[i] = argInit_real_T();
  }
}

/*
 * Arguments    : void
 * Return Type  : double
 */
static double argInit_real_T(void)
{
  return 0.0;
}

/*
 * Arguments    : int argc
 *                char **argv
 * Return Type  : int
 */
int main(int argc, char **argv)
{
  (void)argc;
  (void)argv;
  /* Initialize the application.
You do not need to do this more than one time. */
  discretize_error_dynamics_FOH_kepler_fixedtf_initialize();
  /* Invoke the entry-point functions.
You can call entry-point functions multiple times. */
  main_discretize_error_dynamics_FOH_kepler_fixedtf();
  /* Terminate the application.
You do not need to do this more than one time. */
  discretize_error_dynamics_FOH_kepler_fixedtf_terminate();
  return 0;
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void main_discretize_error_dynamics_FOH_kepler_fixedtf(void)
{
  emxArray_real_T *A_k;
  emxArray_real_T *B_k_minus;
  emxArray_real_T *B_k_plus;
  emxArray_real_T *Delta;
  emxArray_real_T *S_k;
  emxArray_real_T *d_k;
  double dv1[105];
  double dv2[45];
  double dv[2];
  /* Initialize function 'discretize_error_dynamics_FOH_kepler_fixedtf' input
   * arguments. */
  /* Initialize function input argument 'tspan'. */
  /* Initialize function input argument 'x_ref'. */
  /* Initialize function input argument 'u_ref'. */
  /* Initialize function input argument 's_ref'. */
  /* Call the entry-point 'discretize_error_dynamics_FOH_kepler_fixedtf'. */
  emxInitArray_real_T(&A_k, 3);
  emxInitArray_real_T(&B_k_plus, 3);
  emxInitArray_real_T(&B_k_minus, 3);
  emxInitArray_real_T(&S_k, 3);
  emxInitArray_real_T(&d_k, 3);
  emxInitArray_real_T(&Delta, 2);
  argInit_1x2_real_T(dv);
  argInit_7x15_real_T(dv1);
  argInit_3x15_real_T(dv2);
  discretize_error_dynamics_FOH_kepler_fixedtf(argInit_real_T(), dv, dv1, dv2,
                                               A_k, B_k_plus, B_k_minus, S_k,
                                               d_k, Delta);
  emxDestroyArray_real_T(A_k);
  emxDestroyArray_real_T(B_k_plus);
  emxDestroyArray_real_T(B_k_minus);
  emxDestroyArray_real_T(S_k);
  emxDestroyArray_real_T(d_k);
  emxDestroyArray_real_T(Delta);
}

/*
 * File trailer for main.c
 *
 * [EOF]
 */
