function J = uq_Kriging_eval_J_of_theta_CV(theta,KrgModelParameters)
%UQ_KRIGING_EVAL_J_OF_THETA_CV computes the obj.fun. of CV estimation.
%
%   J = UQ_KRIGING_EVAL_J_OF_THETA_CV(THETA, KRGMODELPARAMETERS) evaluates
%   the k-fold cross-validation (CV) estimation objective function of a
%   Kriging model at given values of hyperparameters THETA and other 
%   Kriging model parameters stored in KRGMODELPARAMETERS.
%
%   See also UQ_KRIGING_OPTIMIZER, UQ_KRIGING_EVAL_J_OF_THETA_ML,
%   UQ_KRIGING_CALCULATE, UQ_KRIGING_CALC_KFOLD.

%% Check inputs
narginchk(2,2)

%% Get relevant parameters from input
%
X = KrgModelParameters.X;  % Experimental design, inputs
Y = KrgModelParameters.Y;  % Experimental design, outputs
N = KrgModelParameters.N;  % Experimental design, size
F = KrgModelParameters.F;  % Trend/information matrix

CorrOptions = KrgModelParameters.CorrOptions;  % Correlation options
evalR_handle = CorrOptions.Handle;   % Correlation function

% The folds in K-fold CV, each contains indices of the experimental design
randIdx = KrgModelParameters.RandIdx;

isRegression = KrgModelParameters.IsRegression;  % Regression model
estimNoise = KrgModelParameters.EstimNoise;      % Estimate noise
if isfield(KrgModelParameters,'sigmaNSQ')
    sigmaNSQ = KrgModelParameters.sigmaNSQ;      % Noise variance, if any
end

%% Evaluate the objective function

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
    % Compute the required auxiliary matrices
    auxMatrices = uq_Kriging_calc_auxMatrices(R, F, Y, 'default');
    % Compute the point-wise cross-validation errors
    cvErrors = uq_Kriging_calc_KFold(randIdx, Y, F, auxMatrices);

    % Compute the average of the cross-validation errors
    J = mean(cell2mat(cvErrors));
    
catch 
    % If something goes wrong (typically due to ill-conditioned R),
    % return a "large" value
    J = realmax; 
end

end