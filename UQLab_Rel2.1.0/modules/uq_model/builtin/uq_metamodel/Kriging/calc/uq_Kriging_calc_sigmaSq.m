function sigmaSq = uq_Kriging_calc_sigmaSq(KrgParameters,estimMethod)
%UQ_KRIGING_CALC_SIGMASQ computes the variance of the Gaussian process.
%
%   sigmaSq = UQ_KRIGING_CALC_SIGMASQ(KrgParameters,estimMethod) returns
%   the variance of the Gaussian process (GP) for a given Kriging
%   parameters in KrgParameters and depending on the estimation method
%   given in estimMethod. In the case of Maximum-likelihood estimation,
%   the computation also depends on the condition of the correlation
%   matrix R.
%
%   estimMethod is a string with the following possible values:
%       'cv'               : Cross-validation (CV) estimation
%       'ml_chol'          : Maximum-likelihood (ML) estimation, with
%                            chol(R)-related results available
%       'ml_nochol'        : ML estimation, without chol(R)
%       'ml_bypass_chol'   : ML estimation, bypass explicit computation of
%                            the Kriging trend coefficients beta 
%       'ml_bypass_nochol' : ML estimation, try to bypass but w/o chol(R),
%                            it follows the same procedure as 'ml_no_chol'
%
%   The required Kriging parameters differed for each estimMethod.
%
%   See also UQ_KRIGING_CALCULATE, UQ_KRIGING_EVAL_J_OF_THETA_ML.

%% Verify inputs
[KrgParameters,estimMethod] = verify_inputs(KrgParameters,estimMethod);

%% Compute the GP variance
switch lower(estimMethod)
    case 'cv'
        sigmaSq = calc_sigmaSqCV(KrgParameters);
    case 'ml_chol'
        sigmaSq = calc_sigmaSqMLWithCholesky(KrgParameters);
    case 'ml_nochol'
        sigmaSq = calc_sigmaSqMLWithoutCholesky(KrgParameters);
    case 'ml_bypass_chol'
        % bypass the computation of the regression coefficients
        sigmaSq = calc_sigmaSqMLBypass(KrgParameters);
    case 'ml_bypass_nochol'
        % without cholesky decomposition of R, can't bypass beta computation
        sigmaSq = calc_sigmaSqMLWithoutCholesky(KrgParameters);
end

end

function [KrgParameters,estimMethod] = verify_inputs(KrgParameters,estimMethod)
%VERIFY_INPUTS verifies the inputs of the function to compute the GP var.

% Supported estimation method
validEstimMethod = {'cv', 'ml_chol', 'ml_nochol',...
    'ml_bypass_chol', 'ml_bypass_nochol'};

% Verify inputs
if ~isstruct(KrgParameters)
    error('Invalid Kriging parameters. Expect structure.')
end

if ~any(strcmpi(estimMethod,validEstimMethod))
    error('Invalid Kriging estimation method.')
end

end

%% ------------------------------------------------------------------------
function sigmaSq = calc_sigmaSqCV(KrgParameters)
%CALC_SIGMASQCV computes GP variance from CV estimation.
%
%   Reference:
%
%   - Bachoc, F. (2013). Cross-validation and maximum likelihood estimations 
%     of hyper-parameters of Gaussian processes with model misspecification.
%     Computational Statistics and Data Analysis. 66, pp. 55-69.

cvErrors = cell2mat(KrgParameters.CVErrors);
cvSigma2 = cell2mat(KrgParameters.CVSigma2);

sigmaSq =  mean(cvErrors./cvSigma2); 

end

%% ------------------------------------------------------------------------
function sigmaSq = calc_sigmaSqMLWithCholesky(KrgParameters)
%CALC_SIGMASQMLWITHCHOLESKY computes GP variance from ML estim. w/ chol(R).
%
%   If Cholesky decomposition of the correlation matrix R is available,
%   the GP variance sigmaSq then reads
%       sigmaSq = 1/N * (z^T * z)
%   where:
%       z = Ytilde - Ftilde*beta
%       Ytilde = transpose(L)^(-1) * Y
%       Ftilde = transpose(L)^(-1) * F
%   and:
%       N    : Number of observed points
%       beta : Kriging trend coefficients (P-by-1, P # of trend functions)
%       L    : chol(R) = L^T * L (N-by-N)
%       Y    : Observed responses or output (N-by-1)
%       F    : Observation (design) matrix (N-by-P)
        
N = KrgParameters.N;
beta = KrgParameters.beta;
Ytilde = KrgParameters.Ytilde;
Ftilde = KrgParameters.Ftilde;

z = Ytilde - Ftilde*beta;

sigmaSq = 1/N * (transpose(z) * z); 

end

%% ------------------------------------------------------------------------
function sigmaSq = calc_sigmaSqMLWithoutCholesky(KrgParameters)
%CALC_SIGMASQWITHOUTCHOLESKY computes GP var. from ML estim. w/o chol(R).
%
%   If Cholesky decomposition of the correlation matrix R is not available,
%   the GP variance sigmaSq then reads
%       sigmaSq = 1/N * (z^T * R^(-1) * z)
%   where:
%       z = Y - F*beta
%   and:
%       N    : Number of observed points
%       R    : Correlation matrix on observed points (N-by-N)
%       Y    : Observed responses or outputs (N-by-1)
%       F    : Observation (design) matrix (N-by-P, P # of trend functions)
%       beta : Kriging trend coefficients (P-by-1)

N = KrgParameters.N;
Y = KrgParameters.Y;
F = KrgParameters.F;
Rinv = KrgParameters.Rinv; % Pseudo-inverse of R
beta = KrgParameters.beta;

z = Y - F*beta;

sigmaSq = 1/N * (transpose(z) * Rinv * z);

end

%% ------------------------------------------------------------------------
function sigmaSq = calc_sigmaSqMLBypass(KrgParameters)
%CALC_SIGMASQMLBYPASS computes the GP variance from ML estim. wihout beta.
%
%   If Cholesky decomposition of the correlation matrix is available,
%   then explicit computation of beta (the trend coefficients) is not
%   required. This is useful during the optimization process.
%   The procedure makes use of QR factorization of Ftilde.
%   The GP variance sigmaSq then reads
%       sigmaSq = 1/N * (z^T * z)
%   where:
%       z = Ytilde - Q1*Q1^T*Ytilde
%       Ytilde = transpose(L)^(-1) * Y
%   and:
%       N  : Number of observed points
%       L  : chol(R) = L^T * L (N-by-N)
%       Y  : Observed responses or outputs (N-by-1)
%       Q1 : qr(transpose(L)^(-1) * F) = Q1.G (N-by-N)

N = KrgParameters.N;
Q1 = KrgParameters.Q1;
Ytilde = KrgParameters.Ytilde;

z = Ytilde - Q1*transpose(Q1)*Ytilde;

sigmaSq = 1/N * (transpose(z) * z);

end
