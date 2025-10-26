function auxMatrices = uq_Kriging_calc_auxMatrices(R, F, Y, runCase)
% UQ_KRIGING_CALC_AUXMATRICES computes several useful auxiliary matrices. 
%
%   auxMatrices = UQ_KRIGING_CALC_AUXMATRICES(R, F, Y, runCase) computes
%   several auxiliary matrices that can be useful to speed up some
%   computations during the calculation of a Kriging metamodel
%   as well as in predictions. Given a correlation matrix R and observation
%   matrix F, the following auxiliary matrices are returned inside
%   the auxMatrices structure depending on the string runCase:
%       'default' : Default auxiliary matrices computation
%           .cholR      : Cholesky decomp. of R if exists, otherwise NaN
%           .Rinv       : Pseudo-inverse of R in the case its Cholesky
%                         decomposition is not available due to R being
%                         ill-conditioned. If the Cholesky decomposition is
%                         available then this is empty.
%           .FTRinv     : F^T * R^(-1)
%           .FTRinvF    : F^T * R^(-1) * F
%           .FTRinvF_inv: Pseudo-inverse (F^T * R^(-1) * F)^(-1) in case 
%                         F^T * R^(-1) * F is ill-conditioned, otherwise
%                         this field is empty.
%
%       'ml_estimation' : 'default' plus the following
%           .Ytilde : transpose(L)^(-1) * Y; 
%           .Ftilde : transpose(L)^(-1) * F;
%           .Q1     : QR decomp. of Ftilde, such that qr(Ftilde) = Q1*G
%           .G      : QR decomp. of Ftilde, such that qr(Ftilde) = Q1*G
%           the above fields are empty in the case of ill-conditioned R.
%
%       'ml_optimization' : 'ml_estimation' but without .FTRinvm, .FTRinvF,
%                           and .FTRinvF_inv because they are not needed in
%                           ML optimization.
%
%   See also UQ_KRIGING_CALCULATE, UQ_KRIGING_CALCULATE,
%   UQ_KRIGING_EVAL_J_OF_THETA_ML.

%% Verify inputs
[R, F, Y, runCase] = verify_inputs(R, F, Y, runCase);

%% Compute the auxiliary matrices
switch lower(runCase)
    case 'default'
        auxMatrices = calc_AuxMatricesDefault(R,F);
    case 'ml_optimization'
        auxMatrices = calc_AuxMatricesMLOptimization(R, F, Y);
    case 'ml_estimation'
        auxMatrices = calc_AuxMatricesMLEstimation(R, F, Y);
end

end

function [R, F, Y, runCase] = verify_inputs(R, F, Y, runCase)
%VERIFY_INPUTS verifies the inputs of the GP variance computation function.

% Supported run cases
validRunCases = {'default', 'ml_optimization', 'ml_estimation'};

% Verify inputs
if ~isreal(R) || diff(size(R))
    error('Correlation matrix R is not real or not symmetric.')
end
if ~isreal(F)
    error('Invalid observation matrix F (not real numbers).')
end
if ~isreal(Y) || ~iscolumn(Y)
    error('Model response vector is not real or not columnar.')
end
if ~any(strcmpi(runCase,validRunCases))
    error('Run case is not supported.')
end

end

function auxMatrices = calc_AuxMatricesDefault(R,F)
%CALC_AUXMATRICESDEFAULT computes the default auxiliary matrices.

[cholR,Rinv] = calc_CholR(R);  % Try to compute the Cholesky decomp. of R

FTRinv = calc_FTRinv(F, cholR, Rinv);

FTRinvF = FTRinv * F;
FTRinvF_inv = calc_FTRinvF_inv(FTRinvF);

% Organize results in a structure
auxMatrices.cholR       = cholR;
auxMatrices.Rinv        = Rinv;
auxMatrices.FTRinv      = FTRinv;
auxMatrices.FTRinvF     = FTRinvF;
auxMatrices.FTRinvF_inv = FTRinvF_inv;

end

function auxMatrices = calc_AuxMatricesMLEstimation(R, F, Y)
%CALC_AUXMATRICESMLESTIMATION computes the aux. matrices for ML estimation.

[cholR,Rinv] = calc_CholR(R);  % Try to compute the Cholesky decomp. of R

FTRinv = calc_FTRinv(F, cholR, Rinv);

[Ytilde,Ftilde,Q1,G] = calc_AuxMatricesQR(cholR, Y, F);

FTRinvF = FTRinv * F;
FTRinvF_inv = calc_FTRinvF_inv(FTRinvF);

% Organize results in a structure
auxMatrices.cholR       = cholR;
auxMatrices.Rinv        = Rinv;
auxMatrices.FTRinv      = FTRinv;
auxMatrices.FTRinvF     = FTRinvF;
auxMatrices.FTRinvF_inv = FTRinvF_inv;
auxMatrices.Ytilde      = Ytilde;
auxMatrices.Ftilde      = Ftilde;
auxMatrices.Q1          = Q1;
auxMatrices.G           = G;

end

function auxMatrices = calc_AuxMatricesMLOptimization(R, F, Y)
%CALC_AUXMATRICESMLOPTIMIZATION computes the aux. matrices for ML opt.

[cholR,Rinv] = calc_CholR(R);  % Try to compute the Cholesky decomp. of R

[Ytilde,Ftilde,Q1,G] = calc_AuxMatricesQR(cholR, Y, F);

% Organize results in a structure
auxMatrices.cholR  = cholR;
auxMatrices.Rinv   = Rinv;
auxMatrices.Ytilde = Ytilde;
auxMatrices.Ftilde = Ftilde;
auxMatrices.Q1     = Q1;
auxMatrices.G      = G;

end

function [cholR,Rinv] = calc_CholR(R)
%CALC_CHOLR computes the Cholesky decomp. and inverse of R, if possible.

try
    % Try to calculate the Cholesky decomposition of R
    L = chol(R);
    cholR = L;
    Rinv = [];
catch
    % The Cholesky decomposition failed
    cholR = nan;    
    Rinv = pinv(R);  % Compute the pseudo-inverse instead
end

end

function FTRinv = calc_FTRinv(F, cholR, Rinv)
%CALC_FTRINV computes the matrix F^T*R^(-1).

if ~isnan(cholR)
    FTRinv = (transpose(F) / cholR) / transpose(cholR);
else
    % Use the pseudo-inverse
    FTRinv = transpose(F) * Rinv;
end

end

function [Ytilde,Ftilde,Q1,G] = calc_AuxMatricesQR(cholR, Y, F)
%CALC_AUXMATRICESQR computes the auxiliary matrices involving QR decomp.

if ~isnan(cholR)
    Ytilde = transpose(cholR) \ Y;
    Ftilde = transpose(cholR) \ F;
    [Q1,G] = qr(Ftilde,0);  % Economy size QR decomposition
else
    Ytilde = [];
    Ftilde = [];
    Q1 = [];
    G = [];
end

end

function FTRinvF_inv = calc_FTRinvF_inv(FTRinvF)
%CALC_FTRINVF_INV computes the inverse of FTRinvF matrix, if possible.

% Check if FTRinvF is not ill-conditioned.
if rcond(FTRinvF) > 1e-10
    FTRinvF_inv = [];
else
    FTRinvF_inv = pinv(FTRinvF);  % Compute the pseudo-inverse
end

end
