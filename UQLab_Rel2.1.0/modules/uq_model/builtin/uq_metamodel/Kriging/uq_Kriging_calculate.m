function success = uq_Kriging_calculate(current_model)
%UQ_KRIGING_CALCULATE calculates the Kriging model defined in CURRENT_MODEL.
%
%   SUCCESS = UQ_KRIGING_CALCULATE(CURRENT_MODEL) calculates the Kriging
%   metamodel defined in CURRENT_MODEL and returns the status of the 
%   calculation.
%
%   See also UQ_KRIGING_INITIALIZE, UQ_KRIGING_OPTIMIZER,
%   UQ_KRIGING_EVAL_F.

success = false; 

%% Check arguments
% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type,'uq_metamodel')
    error('Error: uq_metamodel cannot handle objects of type %s',...
        current_model.Type);
end

%% Reporting
%
DisplayLevel = current_model.Internal.Display ;
if DisplayLevel
    fprintf('---   Calculating the Kriging metamodel...                              ---\n')
end

%% Get the number of output dimensions
Nout = current_model.Internal.Runtime.Nout;

%% ----  Kriging entry point
X = current_model.ExpDesign.U;
% Remove the constants, if any
nonConst = current_model.Internal.Runtime.nonConstIdx ;
X = X(:,nonConst);
N = size(X,1);
current_model.Internal.Runtime.N = N;

%% Calculate F and store it
%
current_model.Internal.Runtime.current_output = 1;
evalF_handle = current_model.Internal.Kriging(1).Trend.Handle;
F = evalF_handle(X, current_model);
current_model.Internal.Kriging.Trend.F = F;

%% Get the estimation method
%
estim_method = current_model.Internal.Kriging.GP.EstimMethod;

%% Calculate the Kriging metamodel

% Mimic a persistent variable that keeps track the size of optimization
% parameter array (i.e., bound and initial value) when mix regression and
% interpolation model in a multiple output model is used.
isPrevReg = [];  

% Initialize optimizer options
optim_options = uq_Kriging_initialize_optimizer(current_model);

% Cycle through each output
for oo = 1:Nout
    % Copy the necessary information about the Kriging options
    % to the multiple output dimensions 
    if oo > 1
        current_model.Internal.Kriging(oo) = ...
            current_model.Internal.Kriging(oo-1);
        % Copy only if regression option per output is not given
        if numel(current_model.Internal.Regression) < oo
            current_model.Internal.Regression(oo) = ...
                current_model.Internal.Regression(oo-1);
        end
    end    
    
    % In the case of Kriging regression, move the noise estimation bound
    % and initial value from .Regression to the .Optim
    isPrevReg = uq_Kriging_helper_assign_OptionOptim(...
        current_model, oo, isPrevReg);

    % Get the current Y
    Y = current_model.ExpDesign.Y(:,oo);
    
    % Get the current regression flags
    isRegression = current_model.Internal.Regression(oo).IsRegression;
    estimNoise = current_model.Internal.Regression(oo).EstimNoise;
    isHomoscedastic = current_model.Internal.Regression(oo).IsHomoscedastic;
    
    %% Find optimal theta

    % Store the current output, used inside the optimization function
    current_model.Internal.Runtime.current_output = oo;

    [theta,Jstar,fcount,nIter,exitflag] = ...
        uq_Kriging_optimizer(X, Y, optim_options, current_model);
    
    %% Store optimization results inside current_model

    % Regression-related parameter: Tau parameter or SigmaSQ
    if isRegression
        if estimNoise
            % Tau parameter optimized
            tau = theta(end);
            current_model.Internal.Kriging(oo).Optim.Tau = theta(end);
        else
            % SigmaSQ optimized known sigmaNSQ 
            sigmaSQOptim = theta(end);
            current_model.Internal.Kriging(oo).Optim.SigmaSQ = theta(end);
        end
        theta(end) = [];  % So theta only contains GP hyperparameters
    end
    % optimal theta, the correlation function hyperparameters
    current_model.Internal.Kriging(oo).Optim.Theta = theta;
    % objective function value at optimal theta
    current_model.Internal.Kriging(oo).Optim.ObjFun = Jstar;
    % number of function evaluations
    current_model.Internal.Kriging(oo).Optim.nEval = fcount; 
    % number of iterations
    current_model.Internal.Kriging(oo).Optim.nIter = nIter; 
    % exit flag that describes the exit condition of the optimization
    % process (see uq_Kriging_optimizer for more details)
    current_model.Internal.Kriging(oo).Optim.ExitFlag = exitflag;

    %% Compute correlation at X
    R = calc_R(current_model, X, oo);    
    % Store the matrix in current_model
    current_model.Internal.Kriging(oo).GP.R = R;
    % If sigmaNSQ is known at different responses points,
    % modify the correlation matrix R now as covariance matrix C.
    % NOTE: For compatibility, the variable is still named 'R'.
    if isRegression && ~isHomoscedastic
        R = calc_C(R,current_model,oo);
    end
    
    %% Compute the auxiliary matrices
    switch lower(estim_method)
        case 'cv'
            runCase = 'default';
        case 'ml'
            runCase = 'ml_estimation';
    end
    auxMatrices = uq_Kriging_calc_auxMatrices(R, F, Y, runCase);
 
    %% Compute beta, the trend coefficients
    beta = calc_Beta(current_model, auxMatrices, oo);
    % Store beta in current_model
    current_model.Internal.Kriging(oo).Trend.beta = beta;
    
    %% Compute sigmaSQ, the GP variance
    if isRegression && ~estimNoise
        % Get the (directly) optimized sigmaSQ
        sigmaSQ = sigmaSQOptim;
    elseif strcmpi(estim_method,'cv')
        % Calculate sigmaSQ (the GP variance) based on CV estimation
        randIdx = current_model.Internal.Runtime.CV.RandIdx;  % CV folds
        sigmaSQ = calc_SigmaSQCV(randIdx, Y, F, auxMatrices);
    else
        % Calculate sigmaSQ (the GP variance) based on ML estimation
        sigmaSQ = calc_SigmaSQML(N, Y, F, beta, auxMatrices);
    end
    % Store sigmaSQ in current_model
    % Note that for known sigmaNSQ, sigmaSQ is already directly optimized
    if ~isRegression || estimNoise
        current_model.Internal.Kriging(oo).GP.sigmaSQ = sigmaSQ;
    else
        current_model.Internal.Kriging(oo).GP.sigmaSQ = sigmaSQOptim;
    end

    %% Compute a posteriori CV errors, now N-fold CV, for the LOO CV error
    randIdx = uq_Kriging_helper_create_randIdx(1,N);  % Folds in N-fold CV
    [CVErrors,CVSigma2] = uq_Kriging_calc_KFold(...
        randIdx, Y, F, auxMatrices);
    % Store the error metrics
    varY = var(Y, 1, 1);
    current_model.Error(oo).LOO = mean(cell2mat(CVErrors))/varY;    
    current_model.Internal.Error(oo).varY = varY;
    current_model.Internal.Error(oo).LOOmean = cell2mat(CVErrors);
    current_model.Internal.Error(oo).LOOsd = sqrt(cell2mat(CVSigma2));
    current_model.Internal.Error(oo).sigma_i_Sq = cell2mat(CVSigma2);

    %% Store the cache of all the auxiliary matrices
    %  that can be useful to speed up prediction
    if current_model.Internal.KeepCache
        current_model.Internal.Kriging(oo).Cached.cholR = ...
            auxMatrices.cholR;
        current_model.Internal.Kriging(oo).Cached.Rinv = ...
            auxMatrices.Rinv;
        current_model.Internal.Kriging(oo).Cached.FTRinv = ...
            auxMatrices.FTRinv;
        current_model.Internal.Kriging(oo).Cached.FTRinvF = ...
            auxMatrices.FTRinvF;
    else
        current_model.Internal.Kriging(oo).Cached = [];
    end

    %% Store a copy of the most important Kriging results in current_model
    current_model.Kriging(oo).beta = ...
        current_model.Internal.Kriging(oo).Trend.beta;
    current_model.Kriging(oo).sigmaSQ = ...
        current_model.Internal.Kriging(oo).GP.sigmaSQ;
    current_model.Kriging(oo).theta = ...
        current_model.Internal.Kriging(oo).Optim.Theta;
    
    %% Store the noise and GP variance depending on noise variance
    if isRegression
        if estimNoise
            % Compute the noise variance from tau (only for regression)
            % Update the Kriging sigmaNSQ
            current_model.Kriging(oo).sigmaNSQ = ...
                tau * current_model.Internal.Kriging(oo).GP.sigmaSQ;
            % Update the Internal Kriging sigmaNSQ
            current_model.Internal.Kriging(oo).sigmaNSQ = ...
                current_model.Kriging(oo).sigmaNSQ;
            % Update the Internal Regression SigmaNSQ
            current_model.Internal.Regression(oo).SigmaNSQ = ...
                current_model.Kriging(oo).sigmaNSQ;
            % Subtract the total variance with the noise variance
            % and update the current_model.Kriging sigmaSQ
            current_model.Kriging(oo).sigmaSQ = ...
                current_model.Kriging(oo).sigmaSQ - ...
                current_model.Kriging(oo).sigmaNSQ;
            %...and in the current_model.Internal.Kriging.GP
            current_model.Internal.Kriging(oo).GP.sigmaSQ = ...
                current_model.Internal.Kriging(oo).GP.sigmaSQ - ...
                current_model.Internal.Kriging(oo).sigmaNSQ;
        else
            current_model.Kriging(oo).sigmaNSQ = ...
                current_model.Internal.Regression(oo).SigmaNSQ;
            current_model.Internal.Kriging(oo).sigmaNSQ = ...
                current_model.Internal.Regression(oo).SigmaNSQ;
        end
        % NOTE: the different capitalization, in sigmaNSQ vs. SigmaNSQ and
        % sigmaSQ vs. SigmaSQ, is due to the convention that 'sigmaSQ'
        % in .Kriging(oo) is camelCase but in other places it's UpperCase.
    end
end

%%
% Raise the flag that the metamodel has been calculated
current_model.Internal.Runtime.isCalculated = true;

%%
% Build the random field needed for Kriging resampling, if requested
if current_model.Internal.isTrajectory
    uq_createKrigingRF(current_model);
end

%%
if DisplayLevel
    fprintf('---   Calculation finished!                                             ---\n')
end

success = true;

end

function beta = calc_Beta(current_model, auxMatrices, outIdx)
%CALC_BETA computes the Kriging trend coefficients of the current_model.

estimMethod = current_model.Internal.Kriging(outIdx).GP.EstimMethod;
trendType = current_model.Internal.Kriging(outIdx).Trend.Type;
Y = current_model.ExpDesign.Y(:,outIdx);
F = current_model.Internal.Kriging(outIdx).Trend.F;

switch lower(estimMethod)
    case 'cv'        
        betaEstimMethod = 'standard';
    case 'ml'
        betaEstimMethod = 'qr';
end

beta = uq_Kriging_calc_beta(F, trendType, Y, betaEstimMethod, auxMatrices);

end

function R = calc_R(current_model, X, outIdx)
%CALC_R computes the correlation matrix of the current_model at X.

evalR_handle = current_model.Internal.Kriging(outIdx).GP.Corr.Handle;
CorrOptions = current_model.Internal.Kriging(outIdx).GP.Corr;
theta = current_model.Internal.Kriging(outIdx).Optim.Theta;
N = current_model.Internal.Runtime.N;
isRegression = current_model.Internal.Regression(outIdx).IsRegression;
isHomoscedastic = current_model.Internal.Regression(outIdx).IsHomoscedastic;
% Compute R
R = evalR_handle(X, X, theta, CorrOptions);

% If regression and homoscedastic, adjust R with the Tau parameter
if isRegression && isHomoscedastic
    if isfield(current_model.Internal.Kriging(outIdx).Optim, 'Tau')
        tau = current_model.Internal.Kriging(outIdx).Optim.Tau;
    else
        sigmaSQ =  current_model.Internal.Kriging(outIdx).Optim.SigmaSQ;
        sigmaNSQ = current_model.Internal.Regression(outIdx).SigmaNSQ; 
        tau = sigmaNSQ / (sigmaSQ + sigmaNSQ);
    end
    R = (1-tau) * R + tau * eye(N);
end

end

function C = calc_C(R,current_model,outIdx)
%CALC_C computes the covariance matrix of the current_model at X.

sigmaSQ = current_model.Internal.Kriging(outIdx).Optim.SigmaSQ;
sigmaNSQ = current_model.Internal.Regression(outIdx).SigmaNSQ;
C = sigmaSQ * R;
if iscolumn(sigmaNSQ)
    C = C + diag(sigmaNSQ);
else
    C = C + sigmaNSQ;
end

end

function sigmaSQ = calc_SigmaSQCV(randIdx, Y, F, auxMatrices)
%CALC_SIGMASQCV computes the GP variance based on CV estimation.

% Calculate K-Fold CV errors for sigmaSQ computation
estim_method = 'cv';
[CVErrors,CVSigma2] = uq_Kriging_calc_KFold(randIdx, Y, F, auxMatrices);
% Compile relevant parameters into a structure
parameters.CVErrors = CVErrors;
parameters.CVSigma2 = CVSigma2;

sigmaSQ = uq_Kriging_calc_sigmaSq(parameters,estim_method);

end

function sigmaSQ = calc_SigmaSQML(N, Y, F, beta, auxMatrices)
%CALC_SIGMASQML computes the GP variance based on ML estimation.

% Compile relevant parameters into a structure
parameters.Y = Y;
parameters.N = N;
parameters.F = F;
parameters.beta = beta;
if ~isnan(auxMatrices.cholR)
    parameters.Ytilde = auxMatrices.Ytilde;
    parameters.Ftilde = auxMatrices.Ftilde;
    estimMethod = 'ml_chol';
else
    parameters.Rinv = auxMatrices.Rinv;
    estimMethod = 'ml_nochol';
end

sigmaSQ = uq_Kriging_calc_sigmaSq(parameters,estimMethod);

end
