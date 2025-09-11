function J = uq_Kriging_eval_J_of_theta_ML(theta,KrgModelParameters)
%UQ_KRIGING_EVAL_J_OF_THETA_ML computes the obj.fun. of max. likelihood estimation.
%
%   J = UQ_KRIGING_EVAL_J_OF_THETA_ML(THETA, KRGMODELPARAMETERS) evaluates
%   the maximum likelihood estimation objective function of a Kriging model
%   at hyperparameters stored in THETA and other Kriging model parameters
%   stored in KRGMODELPARAMETERS.
%
%   See also UQ_KRIGING_OPTIMIZER, UQ_KRIGING_EVAL_J_OF_THETA_CV,
%   UQ_KRIGING_CALCULATE, UQ_KRIGING_CALC_SIGMASQ.

%   Note:
%
%   Depending on the whether R is a correlation or covariance matrix,
%   sigmaSq differs BUT they are computed with the same function,
%   uq_Kriging_calc_sigmaSq and it gives:
%       sigmaSq = 1/N [(Y-F*beta)^T*R^(-1)*(Y-F*beta)^T]
%
%   If R is correlation, sigmaSq is the GP variance for a given theta and
%   used in the objective function as is:
%       J = 0.5*(N*log(2*pi*sigmaSq) + log|R| + N)
%
%   If R is covariance, sigmaSq needs to be multiplied by N because the
%   objective function reads:
%       J = 0.5*(N*log(2*pi) + log|R| + (Y-F*beta)^T*R^(-1)*(Y-F*beta)^T)

%% Check inputs
%
narginchk(2,2)

%% Get relevant parameters from input
%
X = KrgModelParameters.X;  % Experimental design, input
Y = KrgModelParameters.Y;  % Experimental design, output
N = KrgModelParameters.N;  % Experimental design, size
F = KrgModelParameters.F;  % Trend/Information matrix

CorrOptions = KrgModelParameters.CorrOptions;  % Correlation options
evalR_handle = CorrOptions.Handle;  % Correlation function handle

trendType = KrgModelParameters.trend_type;  % Kriging trend type

isRegression = KrgModelParameters.IsRegression;  % Regression model
estimNoise = KrgModelParameters.EstimNoise;      % Estimate noise
if isfield(KrgModelParameters,'sigmaNSQ')
    sigmaNSQ = KrgModelParameters.sigmaNSQ;      % Noise variance, if any
end

%% Evaluate the objective function
%
try
    % Compute R
    if ~isRegression
        % Interpolation
        R = evalR_handle(X, X, theta, CorrOptions);
    elseif estimNoise
        % Regression with Tau parameter
        R = (1-theta(end)) * evalR_handle(X, X, theta(1:end-1),...
            CorrOptions) + theta(end) * eye(N);
    else
        % Regression with known sigmaNSQ, use covariance matrix
        R = theta(end) * evalR_handle(X, X, theta(1:end-1), CorrOptions)...
            + sigmaNSQ;
    end
    % Compute auxiliary matrices
    auxMatrices = uq_Kriging_calc_auxMatrices(R, F, Y, 'ml_optimization');
    % Compute logDetR
    logDetR = calc_LogDetR(R,auxMatrices.cholR);
    % Compute sigmaSq
    sigmaSq = calc_SigmaSq(auxMatrices, N, trendType);

    if ~isRegression || estimNoise
        J = 0.5 * (N * log(2*pi*sigmaSq) + logDetR + N);
    else
        J = 0.5 * (N * log(2*pi) + logDetR + N * sigmaSq);
    end

catch 
    J = realmax;
end

end

function sigmaSq = calc_SigmaSq(auxMatrices, N, trendType)
%CALC_SIGMASQ computes the GP variance depending on chol(R).

KrgParameters.N = N;

if ~isnan(auxMatrices.cholR)
    % Use QR factorization to compute sigmaSq 
    KrgParameters.Ytilde = auxMatrices.Ytilde;
    KrgParameters.Q1 = auxMatrices.Q1;
    estimMethod = 'ml_bypass_chol';
else
    % sigmaSq requires the trend coefficients beta
    KrgParameters.beta = uq_Kriging_calc_beta(F, trendType, Y,...
        'standard', auxMatrices);
    KrgParameters.Rinv = auxMatrices.Rinv;
    estimMethod = 'ml_bypass_nochol';
end

sigmaSq = uq_Kriging_calc_sigmaSq(KrgParameters,estimMethod);

end

function logDetR = calc_LogDetR(R,cholR)
%CALC_LOGDETR computes the log of determinant of R depending on chol(R).

if ~isnan(cholR)
    % Cholesky decomposition available, use it to compute log det(R)
    logDetR = 2 * sum(log(diag(cholR)));
else
   % Compute log det(R) directly
    eps = 1e-320; 
    logDetR = log(max(det(R),eps));    
end

end
