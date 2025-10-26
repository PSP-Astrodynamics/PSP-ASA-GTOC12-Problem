function results = uq_lar(Psi, Y, options)
% RESULTS = UQ_LAR(PSI, Y, OPTIONS): sparse regression with Hybrid Least Angle
%   Regression. PSI is the matrix of evaluations of the regressors in the
%   experimental design points, while Y are the corresponding model
%   responses. The OPTIONS structure is optional and can contain any of the
%   following fields: 
%   
%    'hybrid_lars': set to 1 in uq_PCE_lars, disregarding users' choices.
%       Hybrid-LARS means that we perform an OLS regression at the end of  
%       the basis selection to obtain more accurate results. We always 
%       perform Hybrid-LARS, since LOO-based choice of the hyperparameter
%       is not valid for standard LARS. If there is a constant regressor in
%       the basis, we always add it to the set of selected regressors.
%    'normalize': 0 or 1 (default 1), normalize the both PSI and Y to have 
%       variance 1. Should in general be enabled
%    'early_stop': 0 or 1 (default 1), stop the LAR iterations if the accuracy starts
%       decreasing
%    'loo_modified': 0 or 1 (default 1), use modified LOO for selection of
%       regressors
%    'loo_hybrid': 0 or 1 (default 1), compute the LOO based on
%       coefficients recomputed by OLS and not based on the coefficients
%       computed by LARS
%    'CY': matrix of weights for weighted regression
%
%   The RESULTS structure contains the results as a structure with the following fields:
%     'coefficients':     the array of coefficients
%     'best_basis_index': the index of the iteration LAR has converged to
%     'max_score':        the maximum score of the best iteration (1 - LOO_k)
%     'LOO':              the Leave One Out error estimate for the best iteration
%     'normEmpErr':       the estimated normalizedEmpiricalError 
%     'nz_idx':           the index of non-zero regressors (w.r.t. the original
%                         PSI matrix)
%     'a_scores':         the vector of scores for each iteration of LAR
%     'coeff_array':      the matrix of the coefficients for each iteration
%                         of LAR
%
%   Example: calculate the regression of a given design matrix PSI on the
%            model evaluations Y with normalized lars, and plot the
%            evolution of the scores of the LAR iterations:
%
%   lar_options.early_stop = 1;
%   lar_options.normalize = 1;
%   lar_results = uq_lar(Psi, Y, lar_options)
%
% See also: UQ_PCE_OLS_REGRESSION, UQ_PCE_LOO_ERROR

%% Initialization of the default options
normalize_columns = 1;
early_stop = 1;
hybrid_lars = 1;
modified_loo = 1;
hybrid_loo = 1;
no_selection = 0;
generalized_ls = 0;
DisplayLevel = 0;

%% parsing the options vector (if any)
if exist('options', 'var')
    % normalize the columns of Psi prior to running lars
    if isfield(options, 'normalize')
        normalize_columns = options.normalize;
    end
   
    % early stop option
    % is this basis adaptive?
    if isfield(options, 'early_stop')
        early_stop = options.early_stop;
    end

    
    % hybrid lars option
    if isfield(options, 'hybrid_lars')
        hybrid_lars = options.hybrid_lars;
    end
    
    % disable basis selection (mostly for debug purposes only)
    if isfield(options, 'no_selection')
        no_selection = options.no_selection;
    end
    
    if isfield(options, 'loo_modified')
        modified_loo = options.loo_modified;
    end
    
    if isfield(options, 'loo_hybrid')
        hybrid_loo = options.loo_hybrid;
    end
    
    % verbosity level
    if isfield(options, 'display')
        DisplayLevel = options.display;
    else
        DisplayLevel = 0;
    end
    % generalized least squares in the presence of a covariance matrix for
    % Y
    if isfield(options, 'CY')
        CY = options.CY;
        generalized_ls = 1;
    end
end

% OLS options
olsoptions.modified_loo = modified_loo;

% get the number of data points and polynomials
[N ,P] = size(Psi);

%% trivial case: only 1 regressor, let's directly return the OLS solution
if P == 1
    % ols solution
    if generalized_ls
        olsoptions.CY = CY;
        ols_results = uq_PCE_OLS_regression(Psi, Y, olsoptions);
    else
        ols_results = uq_PCE_OLS_regression(Psi, Y, olsoptions);
    end
    
    % and now on to assigning the outputs
    results.coefficients = ols_results.coefficients;
    results.LOO = ols_results.LOO;
    results.normEmpErr = ols_results.normEmpErr;
    results.optErrorParams = ols_results.optErrorParams;
    results.coeff_array = results.coefficients;
    results.max_score   = 1-results.LOO;
    results.a_scores    = results.max_score;
    results.loo_scores  = results.LOO;
       
    results.best_basis_index = 1;
    results.nz_idx  = 1;
        
    % and the LARs estimate of the LOO
    results.LOO_lars = results.LOO;
    results.lars_idx = 1;
    
    
    % and exit from the algorithm
    return;
end

%% Apply the weight matrix, if supplied
if generalized_ls
    % decorrelate the outputs
    CYinv = CY\eye(size(CY));
    L = chol(CYinv);
    Psi = L*Psi;
    Y = L*Y;
end

%% Centering and normalization

% first check for constant regressors (this is necessary before centering)
constidx = ~any(diff(Psi, 1));
constindices = find(constidx); % indices of constant regressors
constval = Psi(1,constidx);
bool_const_and_center = any(constidx); % true iff constant regressor exists

% always center the data if possible.
% no constant regressor -- do not center 
if bool_const_and_center
    % Center Psi. Note: this will remove the constant regressors, as they 
    % are treated separately in LARS
    mu_Psi = mean(Psi,1);
    Psi = Psi - repmat(mu_Psi, N, 1);
    
    % center the data as well
    mu_Y = mean(Y);
    Y = Y - mu_Y;
    modi_diag = 1/N*ones(N,1);
    run_lars_iterations = var(Y); % used as a flag -- if var(Y) == 0 and 
    % there is a constant regressor, no iterations are necessary 
else
    modi_diag = zeros(N,1);
    run_lars_iterations = 1; % if there is no constant regressor, always run 
    % lars iterations
end

% normalize the regressors and the experimental design if necessary
if normalize_columns
    normPsi = sqrt(sum(Psi.^2, 1)/(N-1)); % columns should have stddev 1 (if centered)
    nznorm_indices = (normPsi~=0); % indices with nonzero norm
    Psi(:, nznorm_indices) = Psi(:, nznorm_indices)./repmat(normPsi(nznorm_indices), N, 1);
end





%% Initialization of the LAR iterations

nvars = min(N-2,P); % maximum number of active predictors: either the full set of basis elements, or N-1 (the - 2 is due to how k is incremented in the loop)
mu = zeros(size(Y)); % initial direction of the LAR 
a_coeff = []; % set of active coefficients
i_coeff = 1:P; % maximal set of coefficients
M = []; % initial information matrix (PsiT_j Psi_j)
maxk = 8*nvars; % maximum number of LARs iterations
coeff_array = zeros(nvars+1, P);

a_scores =-inf(1, nvars+1);
loo_scores = inf*ones(1, nvars+1);


% initialize the best lars leave one out score
refscore = inf;


%% iterative LAR
k = 0;
if DisplayLevel > 1
    fprintf('Maximum LARS candidate basis size: %d\n', P);
end

% initial score: just do OLS with the constant term, if it exists
if bool_const_and_center
    ols_results = uq_PCE_OLS_regression(ones(size(Y,1),1), Y, olsoptions);
    loo_scores(1) = ols_results.LOO;
    a_scores(1) = 1-loo_scores(1);
% First entry is for the constant model
% If there is no constant regressor: a_score(1) stays -inf
end

maxiter = min(maxk,nvars);

while k < maxiter && run_lars_iterations
    k = k + 1;
    if DisplayLevel > 3
        fprintf('Computing LAR iteration %d\n',k);
    end
    
    % correlation with the residual
    cj = Psi'*(Y - mu);
    % getting the most correlated with the current inactive set
    [C, idx] = max(abs(cj(i_coeff)));
    idx = i_coeff(idx); % translate the index to an absolute index
    
    
    % invert the information matrix at the first iteration, later only update its value on
    % the basis of the previous inverted one
    if k == 1
        M = pinv(Psi(:,idx)'*Psi(:,idx));
    else
        x = (Psi(:,a_coeff))'*Psi(:,idx);
        r = (Psi(:,idx))'*Psi(:,idx) ;
        % update the information matrix based on the last calculated
        % inverse
        M = uq_blockwise_inverse(M,x,x',r) ; 
        
        % if the resulting matrix is singular, throw out a warning and use pinv
        if any(~isfinite(M(:)))
            try
                M = pinv(Psi(:,[a_coeff idx])'*Psi(:,[a_coeff idx]));
            catch me
                if DisplayLevel > 1
                    warning('singular design matrix. Skipping the current basis element and removing it from the candidates to improve stability');
                end
                i_coeff(i_coeff == idx) = [];
                M = pinv(Psi(:,a_coeff)'*Psi(:,a_coeff));
                continue;
            end
            
        end
    end
    
   % update the set of active predictors with the newfound idx
    a_coeff = [a_coeff idx];
    
    
    % now we get the vector of correlation signs (cf. pg 207 of Blatman's Thesis)
    s = sign(cj(a_coeff));
    % set the null signs to positive
    s(~s) = 1;
    
    %% now trying to calculate gamma, w and u based on Blatman's Thesis and Efron et al. 2004
    % full reference Blatman Thesis: Blatman, G, 2009, Adaptive sparse polynomial chaos
    % expansions for uncertainty propagation and sensitivity analysis, PhD Thesis,
    % Universit?? Blaise Pascal - Clermont II
    
    % full reference Efron et al. 2004 (gamma calculation): EFRON, HASTIE,JOHNSTONE and
    % TIBSHIRANI, Least Angle Regression, The Annals of Statistics 2004, Vol. 32, No. 2,
    % 407???499 

    % Variable naming after Blatman et al. 2004 (Simpler)
    c = 1/sqrt((s'*M)*s);
    
    % descent direction
    w = c*M*s;
    % descent versor in the residual space
    u = Psi(:,a_coeff)*w;
    % 
    aj = Psi'*u;
    
    % calculating gamma, based on Efron et al. 2004. 
    % Please note the variable naming change (Efron => this code):
    % AA => C, cj => cj(i_coeff). The rest is the same
    if k < nvars
        tmp = [(C - cj(i_coeff))./(c - aj(i_coeff)); (C + cj(i_coeff))./(c + aj(i_coeff))];
        % careful, this array may have all zeros!!!!
        gamma = min(tmp(tmp > 0));
        if isempty(gamma)
            gamma = 0;
            warning('Warning: numerical instability!! Gamma for LAR iteration %d was set to 0 to prevent crashes.', k);
        end
    else % we are at the OLS solution, so update the vectors accordingly
        gamma = C/c;
    end
    
    % remove the coefficient from the candidate predictors
    i_coeff(i_coeff == idx) = [];
    
    % now update the residual 
    mu = mu + gamma*u;
    
    % and finally update the coefficients in the correct direction to yield equicorrelated
    % vectors
    coeff_array(k+1,a_coeff) = coeff_array(k,a_coeff) + gamma*w' ;
    
    
    %% adaptive LARS: Modified Leave One Out error estimate Q^2:
    % based on Blatman, 2009 (PhD Thesis), pg. 115-116
        
    % modified Leave One Out Estimate should be (eq. 5.10, pg 116)
    % Err_loo = mean((M(x^(i))- metaM(x^(i))/(1-h_i)).^2), with
    % h_i = tr(Psi*(PsiTPsi)^-1 *PsiT)_i and
    % divided by var(Y) (eq. 5.11) and multiplied by the T coefficient (eq 5.13):
    % T(P,NCoeff) = NCoeff/(NCoeff-P) * (1 + tr(PsiTPsi)^-1)
    
    % corrected leave-one-out error:
    if ~hybrid_loo
        loo = uq_PCE_loo_error(Psi(:,a_coeff), M, Y, coeff_array(k+1,a_coeff)', modified_loo, modi_diag);
    else
        loo = uq_PCE_loo_error(Psi(:,a_coeff), M, Y, [], modified_loo, modi_diag);
    end
    if loo < 0
        warning('leave one out error negative!!')
    end
        
    loo_scores(k+1) = loo;
    a_scores(k+1) = 1 - loo;
    
        
    %  Stop the iterations if the error increases again:
    mm = round(nvars*0.1) ;
    mm = max(mm,100);
    mm = min(mm, nvars);
    
    % update the current best score
    if loo < refscore
        refscore = loo;
    end
    
    if k > mm
        % simply stop if the loo error is consistently above the reference loo for
        % at least 10% of the iterations
        if (loo_scores(k-mm) <= refscore) && early_stop
            if DisplayLevel > 1
                fprintf('Early stop at coefficient %d/%d \n', k-mm, P);
            end
            break;
        end
    end
end


% get the best score in the current array
if ~no_selection
    [maxScore, k] = max(a_scores);
else
    maxScore = 1-loo;
    k = length(a_scores);
end


%% Assigning the coefficients with the best candidate basis via OLS (Hybrid LARS)
% recompute the coefficients with the correct basis, by rescaling back the
% Psi and Y matrices

nz_idx = abs(coeff_array(k,:)) > 0;

% let's first scale back the Psi matrix to the original shape:
if normalize_columns
%     totcoeff = length(sigma_Psi);
%     Psi = bsxfun(@plus, Psi * spdiags(sigma_Psi', 0, totcoeff, totcoeff),mu_Psi);
    Psi(:, nznorm_indices) = Psi(:, nznorm_indices) .* repmat(normPsi(nznorm_indices), N, 1);
end

if bool_const_and_center
    Psi = bsxfun(@plus,Psi,mu_Psi);
    Y = Y + mu_Y;

    % add the index of the constant regressor to the index set of active 
    % coefficients
    nz_idx(constindices(1)) = 1;
end

% now we assign the coefficients, either through an extra hybrid_lars
% iteration, or by rescaling of the (non-hybrid) LARS solution.
% NOTE: for calls by the PCE module, hybrid_lars is always true (set in 
% uq_PCE_lars).
coefficients = zeros(P,1);
if hybrid_lars
    % and now let's recalculate the coefficients via standard least squares
    ols_results = uq_PCE_OLS_regression(Psi(:,nz_idx), Y,olsoptions); % do not use the covariance option, as Y and Psi are already decorrelated
    coefficients(nz_idx) = ols_results.coefficients;
    results.LOO = ols_results.LOO;
    results.normEmpErr = ols_results.normEmpErr;
    results.optErrorParams = ols_results.optErrorParams;
else % can only be reached through direct calling of uq_lar
    coefficients(nz_idx) = coeff_array(k,nz_idx);
    % if we normalized, we have to rescale now
    if normalize_columns 
        coefficients(nznorm_indices) = coefficients(nznorm_indices)./ (normPsi(nznorm_indices))';
    end
    % and add the constant term, if it exists
    if bool_const_and_center
        coefficients(constindices(1)) =  mean(Y-Psi*coefficients) / constval(1);
    end
    [results.LOO, results.normEmpErr, results.optErrorParams] = uq_PCE_loo_error(Psi(:,nz_idx), pinv(Psi(:,nz_idx).'*Psi(:,nz_idx)), Y, coefficients(nz_idx), 1);
end


if DisplayLevel > 1
    fprintf('LAR basis size: %d/%d\n', sum(nz_idx), P);
end


%% Assign the remaining outputs
results.coeff_array = coeff_array;
results.max_score   = maxScore;

% now let's check that the coefficients array has the correct dimensions, 
% otherwise clear it (it means it is outdated)

results.coefficients = coefficients;
results.a_scores     = a_scores;
results.loo_scores     = loo_scores;

results.best_basis_index = k;
results.nz_idx  = nz_idx;

% useful to reorder the matrix
if bool_const_and_center
    % add the index of the constant regressor
    results.lars_idx = [constindices(1) a_coeff(1:(k-1))];
else
    results.lars_idx = a_coeff(1:(k-1));
end

% now get the actual error from the results of the hybrid LARS
% and the LARs estimate of the LOO
results.LOO_lars = 1 - maxScore;
