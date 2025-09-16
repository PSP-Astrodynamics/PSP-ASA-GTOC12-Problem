
#include "mex.h"
#include "cpg_workspace.h"
#include "cpg_solve.h"

// MEX gateway function
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Check number of inputs
    if (nrhs != 47) {
        mexErrMsgIdAndTxt("MATLAB:cpg_solve:nrhs", "47 inputs required.");
    }

    // Check number of outputs
    if (nlhs != 7) {
        mexErrMsgIdAndTxt("MATLAB:cpg_solve:nlhs", "7 outputs required.");
    }
        
    double * Ak_0 = mxGetPr(prhs[0]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_0(i, Ak_0[i]);
    }
            
    double * Bk_minus_0 = mxGetPr(prhs[1]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_0(i, Bk_minus_0[i]);
    }
            
    double * Bk_plus_0 = mxGetPr(prhs[2]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_0(i, Bk_plus_0[i]);
    }
            
    double * ck = mxGetPr(prhs[3]);
    for (int i = 0; i < 98; i++) {
        cpg_update_ck(i, ck[i]);
    }
            
    double * Ak_1 = mxGetPr(prhs[4]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_1(i, Ak_1[i]);
    }
            
    double * Bk_minus_1 = mxGetPr(prhs[5]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_1(i, Bk_minus_1[i]);
    }
            
    double * Bk_plus_1 = mxGetPr(prhs[6]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_1(i, Bk_plus_1[i]);
    }
            
    double * Ak_2 = mxGetPr(prhs[7]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_2(i, Ak_2[i]);
    }
            
    double * Bk_minus_2 = mxGetPr(prhs[8]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_2(i, Bk_minus_2[i]);
    }
            
    double * Bk_plus_2 = mxGetPr(prhs[9]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_2(i, Bk_plus_2[i]);
    }
            
    double * Ak_3 = mxGetPr(prhs[10]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_3(i, Ak_3[i]);
    }
            
    double * Bk_minus_3 = mxGetPr(prhs[11]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_3(i, Bk_minus_3[i]);
    }
            
    double * Bk_plus_3 = mxGetPr(prhs[12]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_3(i, Bk_plus_3[i]);
    }
            
    double * Ak_4 = mxGetPr(prhs[13]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_4(i, Ak_4[i]);
    }
            
    double * Bk_minus_4 = mxGetPr(prhs[14]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_4(i, Bk_minus_4[i]);
    }
            
    double * Bk_plus_4 = mxGetPr(prhs[15]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_4(i, Bk_plus_4[i]);
    }
            
    double * Ak_5 = mxGetPr(prhs[16]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_5(i, Ak_5[i]);
    }
            
    double * Bk_minus_5 = mxGetPr(prhs[17]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_5(i, Bk_minus_5[i]);
    }
            
    double * Bk_plus_5 = mxGetPr(prhs[18]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_5(i, Bk_plus_5[i]);
    }
            
    double * Ak_6 = mxGetPr(prhs[19]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_6(i, Ak_6[i]);
    }
            
    double * Bk_minus_6 = mxGetPr(prhs[20]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_6(i, Bk_minus_6[i]);
    }
            
    double * Bk_plus_6 = mxGetPr(prhs[21]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_6(i, Bk_plus_6[i]);
    }
            
    double * Ak_7 = mxGetPr(prhs[22]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_7(i, Ak_7[i]);
    }
            
    double * Bk_minus_7 = mxGetPr(prhs[23]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_7(i, Bk_minus_7[i]);
    }
            
    double * Bk_plus_7 = mxGetPr(prhs[24]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_7(i, Bk_plus_7[i]);
    }
            
    double * Ak_8 = mxGetPr(prhs[25]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_8(i, Ak_8[i]);
    }
            
    double * Bk_minus_8 = mxGetPr(prhs[26]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_8(i, Bk_minus_8[i]);
    }
            
    double * Bk_plus_8 = mxGetPr(prhs[27]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_8(i, Bk_plus_8[i]);
    }
            
    double * Ak_9 = mxGetPr(prhs[28]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_9(i, Ak_9[i]);
    }
            
    double * Bk_minus_9 = mxGetPr(prhs[29]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_9(i, Bk_minus_9[i]);
    }
            
    double * Bk_plus_9 = mxGetPr(prhs[30]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_9(i, Bk_plus_9[i]);
    }
            
    double * Ak_10 = mxGetPr(prhs[31]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_10(i, Ak_10[i]);
    }
            
    double * Bk_minus_10 = mxGetPr(prhs[32]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_10(i, Bk_minus_10[i]);
    }
            
    double * Bk_plus_10 = mxGetPr(prhs[33]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_10(i, Bk_plus_10[i]);
    }
            
    double * Ak_11 = mxGetPr(prhs[34]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_11(i, Ak_11[i]);
    }
            
    double * Bk_minus_11 = mxGetPr(prhs[35]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_11(i, Bk_minus_11[i]);
    }
            
    double * Bk_plus_11 = mxGetPr(prhs[36]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_11(i, Bk_plus_11[i]);
    }
            
    double * Ak_12 = mxGetPr(prhs[37]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_12(i, Ak_12[i]);
    }
            
    double * Bk_minus_12 = mxGetPr(prhs[38]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_12(i, Bk_minus_12[i]);
    }
            
    double * Bk_plus_12 = mxGetPr(prhs[39]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_12(i, Bk_plus_12[i]);
    }
            
    double * Ak_13 = mxGetPr(prhs[40]);
    for (int i = 0; i < 49; i++) {
        cpg_update_Ak_13(i, Ak_13[i]);
    }
            
    double * Bk_minus_13 = mxGetPr(prhs[41]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_minus_13(i, Bk_minus_13[i]);
    }
            
    double * Bk_plus_13 = mxGetPr(prhs[42]);
    for (int i = 0; i < 21; i++) {
        cpg_update_Bk_plus_13(i, Bk_plus_13[i]);
    }
            
    double * x_0 = mxGetPr(prhs[43]);
    for (int i = 0; i < 7; i++) {
        cpg_update_x_0(i, x_0[i]);
    }
            
    double * x_f = mxGetPr(prhs[44]);
    for (int i = 0; i < 6; i++) {
        cpg_update_x_f(i, x_f[i]);
    }
            
    double * x_ref = mxGetPr(prhs[45]);
    for (int i = 0; i < 105; i++) {
        cpg_update_x_ref(i, x_ref[i]);
    }
            
    double * u_ref = mxGetPr(prhs[46]);
    for (int i = 0; i < 45; i++) {
        cpg_update_u_ref(i, u_ref[i]);
    }
            
    // Solve the problem instance
    cpg_solve();
    plhs[0] = mxCreateDoubleMatrix(3, 15, mxREAL);
    double * U = mxGetPr(plhs[0]);
    for (int i = 0; i < 45; i++) {
        U[i] = CPG_Result.prim->U[i];
    }
            
    plhs[1] = mxCreateDoubleMatrix(7, 14, mxREAL);
    double * V = mxGetPr(plhs[1]);
    for (int i = 0; i < 98; i++) {
        V[i] = CPG_Result.prim->V[i];
    }
            
    plhs[2] = mxCreateDoubleMatrix(7, 1, mxREAL);
    double * v_0 = mxGetPr(plhs[2]);
    for (int i = 0; i < 7; i++) {
        v_0[i] = CPG_Result.prim->v_0[i];
    }
            
    plhs[3] = mxCreateDoubleMatrix(6, 1, mxREAL);
    double * v_N = mxGetPr(plhs[3]);
    for (int i = 0; i < 6; i++) {
        v_N[i] = CPG_Result.prim->v_N[i];
    }
            
    plhs[4] = mxCreateDoubleMatrix(1, 15, mxREAL);
    double * eta = mxGetPr(plhs[4]);
    for (int i = 0; i < 15; i++) {
        eta[i] = CPG_Result.prim->eta[i];
    }
            
    plhs[5] = mxCreateDoubleMatrix(7, 15, mxREAL);
    double * X = mxGetPr(plhs[5]);
    for (int i = 0; i < 105; i++) {
        X[i] = CPG_Result.prim->X[i];
    }

    plhs[6] = mxCreateDoubleMatrix(3, 1, mxREAL);
    double* p = mxGetPr(plhs[6]);
    for (int i = 0; i < 3; i++) {
        p[i] = CPG_Result.prim->p[i];
    }

    // plhs[6] = mxCreateNumericArray(1, 1, mxINT32_CLASS, mxREAL);
    // int * status = mxGetPr(plhs[6]);
    // status[0] = ecos_flag->status[0];
    // 
    // plhs[6] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d0 = mxGetPr(plhs[6]);
    // for (int i = 0; i < 7; i++) {
    //     d0[i] = CPG_Result.dual->d0[i];
    // }
    // 
    // plhs[7] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d1 = mxGetPr(plhs[7]);
    // for (int i = 0; i < 7; i++) {
    //     d1[i] = CPG_Result.dual->d1[i];
    // }
    // 
    // plhs[8] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d2 = mxGetPr(plhs[8]);
    // for (int i = 0; i < 7; i++) {
    //     d2[i] = CPG_Result.dual->d2[i];
    // }
    // 
    // plhs[9] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d3 = mxGetPr(plhs[9]);
    // for (int i = 0; i < 7; i++) {
    //     d3[i] = CPG_Result.dual->d3[i];
    // }
    // 
    // plhs[10] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d4 = mxGetPr(plhs[10]);
    // for (int i = 0; i < 7; i++) {
    //     d4[i] = CPG_Result.dual->d4[i];
    // }
    // 
    // plhs[11] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d5 = mxGetPr(plhs[11]);
    // for (int i = 0; i < 7; i++) {
    //     d5[i] = CPG_Result.dual->d5[i];
    // }
    // 
    // plhs[12] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d6 = mxGetPr(plhs[12]);
    // for (int i = 0; i < 7; i++) {
    //     d6[i] = CPG_Result.dual->d6[i];
    // }
    // 
    // plhs[13] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d7 = mxGetPr(plhs[13]);
    // for (int i = 0; i < 7; i++) {
    //     d7[i] = CPG_Result.dual->d7[i];
    // }
    // 
    // plhs[14] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d8 = mxGetPr(plhs[14]);
    // for (int i = 0; i < 7; i++) {
    //     d8[i] = CPG_Result.dual->d8[i];
    // }
    // 
    // plhs[15] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d9 = mxGetPr(plhs[15]);
    // for (int i = 0; i < 7; i++) {
    //     d9[i] = CPG_Result.dual->d9[i];
    // }
    // 
    // plhs[16] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d10 = mxGetPr(plhs[16]);
    // for (int i = 0; i < 7; i++) {
    //     d10[i] = CPG_Result.dual->d10[i];
    // }
    // 
    // plhs[17] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d11 = mxGetPr(plhs[17]);
    // for (int i = 0; i < 7; i++) {
    //     d11[i] = CPG_Result.dual->d11[i];
    // }
    // 
    // plhs[18] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d12 = mxGetPr(plhs[18]);
    // for (int i = 0; i < 7; i++) {
    //     d12[i] = CPG_Result.dual->d12[i];
    // }
    // 
    // plhs[19] = mxCreateDoubleMatrix(7, 1, mxREAL);
    // double * d13 = mxGetPr(plhs[19]);
    // for (int i = 0; i < 7; i++) {
    //     d13[i] = CPG_Result.dual->d13[i];
    // }
    // 
    // plhs[20] = mxCreateDoubleMatrix(15, 1, mxREAL);
    // double * d14 = mxGetPr(plhs[20]);
    // for (int i = 0; i < 15; i++) {
    //     d14[i] = CPG_Result.dual->d14[i];
    // }
    // 
    // plhs[21] = mxCreateDoubleMatrix(15, 1, mxREAL);
    // double * d15 = mxGetPr(plhs[21]);
    // for (int i = 0; i < 15; i++) {
    //     d15[i] = CPG_Result.dual->d15[i];
    // }
    // 
    // plhs[22] = mxCreateDoubleMatrix(7, 7, mxREAL);
    // double * d16 = mxGetPr(plhs[22]);
    // for (int i = 0; i < 49; i++) {
    //     d16[i] = CPG_Result.dual->d16[i];
    // }
    // 
    // plhs[23] = mxCreateDoubleMatrix(6, 6, mxREAL);
    // double * d17 = mxGetPr(plhs[23]);
    // for (int i = 0; i < 36; i++) {
    //     d17[i] = CPG_Result.dual->d17[i];
    // }
    // 
    // plhs[24] = mxCreateDoubleMatrix(1, 15, mxREAL);
    // double * d18 = mxGetPr(plhs[24]);
    // for (int i = 0; i < 15; i++) {
    //     d18[i] = CPG_Result.dual->d18[i];
    // }
    // 
    //cpg_retrieve_info(){
}
