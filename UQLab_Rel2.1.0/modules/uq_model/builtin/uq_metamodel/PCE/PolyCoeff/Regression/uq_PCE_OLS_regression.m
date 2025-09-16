function results = uq_PCE_OLS_regression(Psi, Y, options)
% UQ_PCE_OLS_REGRESSION(PSI, Y,OPTIONS): calculates the Ordinary Least Squares 
%     regression on the design matrix Psi for a set of observations Y. 
%     Additional options can be added in the OPTIONS input structure. 
%     The results structure contains the regression coefficients and several
%     error measures (e.g. normalized empirical error and loo-cross-validation.
%
% See also: UQ_PCE_LOO_ERROR, UQ_LAR, UQ_PCE_CALCULATE_COEFFICIENTS_PROJECTION

COVFLAG = false;
modified_loo = false;

if exist('options', 'var')
    if isfield(options,'CY')
        COVFLAG = true;
        CY = options.CY;
    end
    
    if isfield(options,'modified_loo')
        modified_loo = options.modified_loo;
    end
end



% ok, now let's invert the linear system PsiTPsi a = PsiT Y
if COVFLAG
    % decorrelate the outputs
    CYinv = CY \ eye(size(CY));
    L = chol(CYinv);
    Psi = L*Psi;
    Y = L*Y;
end

PsiTPsi = transpose(Psi)*Psi;

if rcond(PsiTPsi) > 1e-12
    % faster
    results.coefficients = PsiTPsi\(transpose(Psi)*Y);
    M = PsiTPsi\speye(size(PsiTPsi));
else
    % stabler
    results.coefficients = pinv(PsiTPsi) * transpose(Psi) * Y;
    M = pinv(PsiTPsi); 
end

% in any case, this is when we should calculate the LOO

[LOO, normEmpErr, optErrorParams] = uq_PCE_loo_error(Psi, M, Y, results.coefficients, modified_loo);

% and save it for later use
results.LOO = LOO;
results.normEmpErr = normEmpErr;
results.optErrorParams = optErrorParams;