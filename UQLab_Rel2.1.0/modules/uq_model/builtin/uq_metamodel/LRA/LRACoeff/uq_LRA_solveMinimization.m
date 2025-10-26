function coeff = uq_LRA_solveMinimization(P, Y, MethodOptions)
% This function evaluates the coefficients of P that minimize the 
% mean-square error w.r.t. Y using the specified method 

switch lower(MethodOptions.Method)
    case 'ols'
        ols_results = uq_LRA_OLS(P,Y, MethodOptions);
        coeff = ols_results.coefficients;
    case 'lars'
        lars_results = uq_LRA_lars(P, Y, MethodOptions);
        coeff = lars_results.coefficients';
end