function beta = uq_Kriging_calc_beta(F, trendType, Y, betaEstimMethod, auxMatrices)
%UQ_KRIGING_CALC_BETA computes the trend coefficients of a Kriging model.
%
%   beta = UQ_KRIGING_CALC_BETA(F, TRENDTYPE, Y, BETAESTIMMETHOD,
%   AUXMATRICES) computes P-dimensional vector of the trend coefficient
%   (where P is the number of basis functions) given:
%       F               : Observation (design) matrix (N-by-P)
%       TRENDTYPE       : Type of Kriging trend, 'simple' or otherwise;
%                         If simple, no estimation of beta (assign 1's)
%       Y               : Output (responses) vector (N-by-1)
%       BETAESTIMMETHOD : Estimation method of beta:
%                           'qr'       : QR-decomp. method, if available
%                           'standard' : Standard formula
%       AUXMATRICES     : Auxiliary matrices (e.g., FTRinv, FTRinvF_inv)
%
%   See also UQ_KRIGING_CALCULATE, UQ_KRIGING_EVAL_J_OF_THETA_ML.

%% Check inputs

% Make sure Y is a column vector
if isrow(Y)
    Y = transpose(Y);
end

% In case of QR method, make sure that all the required matrices
% are available, otherwise switch to standard method
isQR = strcmpi(betaEstimMethod, 'qr'); 
isNoQ1 = ~isfield(auxMatrices,'Q1') || isempty(auxMatrices.Q1);
if strcmpi(trendType,'simple')
    betaEstimMethod = 'no_estimation';
elseif isQR && isNoQ1
    betaEstimMethod = 'standard';
end

%% Compute beta with different approaches
switch lower(betaEstimMethod)
    case 'qr'
        % If the QR decomposition is available, use it to find beta
        beta = calc_BetaQR(auxMatrices);
    case 'standard'
        % Calculate beta using the standard approach
        beta = calc_BetaStandard(auxMatrices,Y);
    case 'no_estimation'
        % No estimation of the trend coefficients (simple Kriging)
        beta = ones(size(F,2),1);
end

end

function beta = calc_BetaQR(auxMatrices)
%CALC_BETAQR computes beta with the QR factorization method.
%
%   beta = G^(-1) * Q1^(T) * Ytilde; Ytilde = L^(-1) * Y
%
%   where:
%       Q1 : the orthogonal matrix part of the QR decomposition of Ftilde,
%            i.e., qr(Ftilde) = Q1 * G, (N-by-N)
%       G  : the upper triangular matrix part of the QR decomp. (N-by-P)
%       L  : the inverse of (lower-triangular) Cholesky factor (N-by-N)
%       Y  : the observed responses (output) vector (N-by-1)
%   
%   Note that G is used here, instead of R,
%   because R already refers to correlation matrix.

Q1 = auxMatrices.Q1;
G  = auxMatrices.G;
Ytilde = auxMatrices.Ytilde;

if size(G,1) ~= size(G,2) || rcond(G) < 1e-10
    % G is not well conditioned, use pseudo-inverse to obtain G^(-1)
    beta = pinv(G) * transpose(Q1) * Ytilde;
else
    beta = G \ transpose(Q1) * Ytilde;
end

end

function beta = calc_BetaStandard(auxMatrices,Y)
%CALC_BETASTANDARD computes beta with the standard OLS formula.
%
%   beta = (F^(T) * R^(-1) * F)^(-1) * F^(T) * R^(-1) * Y
%
%   where:
%       F : the N-by-P observation (design) matrix
%       R : the N-by-N correlation matrix
%       Y : the N-dimensional output vector

FTRinv = auxMatrices.FTRinv;
FTRinvF = auxMatrices.FTRinvF;
FTRinvF_inv = auxMatrices.FTRinvF_inv;

if isempty(FTRinvF_inv)
    % Compute (F^(T) * R^(-1) * F)^(-1) explicitly
    beta = FTRinvF \FTRinv * Y;
else
    % Use stored (F^(T) * R^(-1) * F)^(-1)
    beta = FTRinvF_inv * FTRinv * Y;
end

end
