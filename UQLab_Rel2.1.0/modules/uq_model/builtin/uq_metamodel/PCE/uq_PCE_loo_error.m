function [loo, normEmpErr, opt_results] = uq_PCE_loo_error(Psi, M, Y, coefficients, modified_flag, modi_diag)
% [LOO, NORMEMPERR, OPT_RESULTS] = UQ_PCE_LOO_ERROR(PSI, M, coefficients,MODIFIED_FLAG):
%     calculate the LOO error for the OLS regression on regressor matrix
%     PSI that generated the coefficients in COEFFICIENTS. If MODIFIED_FLAG
%     is set to true, modified leave one out calculation is returned
%     (based on Blatman, 2009 (PhD Thesis), pg. 115-116).
%
%     See also: UQ_PCE_OLS_REGRESSION, UQ_LAR

% based on Blatman, 2009 (PhD Thesis), pg. 115-116
% 
% modified Leave One Out Estimate is given by (eq. 5.10, pg 116):
%   Err_loo = mean((M(x^(i))- metaM(x^(i))/(1-h_i)).^2), with
%   h_i = tr(Psi*(PsiTPsi)^-1 *PsiT)_i and
%
% divided by var(Y) (eq. 5.11) and multiplied by the T coefficient (eq 5.13):
%   T(P,NCoeff) = NCoeff/(NCoeff-P) * (1 + tr(PsiTPsi)^-1)


%% Initialization
% if the modified_flag is not specified, set it to 1
if ~exist('modified_flag', 'var')
    modified_flag = 1;
end

% if no coefficients are provided, calcualte them by OLS
if isempty(coefficients)
   coefficients = M*(Psi.'*Y); 
end

% initialize the optional results to the empty matrix
opt_results = [];
% size of the currently accepted basis
N = size(Psi,1);
NCoeff = numel(coefficients);


% h factor (the full matrix is not calculated explicitly, only the trace is to save memory)
PsiM = Psi*M;
h = sum(PsiM.*Psi,2);

% calculate the correct h factor when the covariate are centered
if exist('modi_diag', 'var')
    h = h+modi_diag;
end

% final Err_loo score
res = Psi*coefficients - Y;
varY = var(Y, 1, 1);


if ~varY % if the data has 0 variance, set the errors to 0
    normEmpErr = 0;
    loo = 0;
else
    normEmpErr = norm(res)^2/length(res)/varY;
    loo = mean((res ./ (1-h)) .^ 2, 1) / varY;
    % if there are NaNs, just return an infinite LOO error (this happens,
    % e.g., when a strongly underdetermined problem is solved)
    loo(isnan(loo)) = Inf;
end


%% Modified LOO if specified
if nargout < 3
    if exist('modified_flag', 'var') && modified_flag
        trM = trace(M);
        if trM < 0 || abs(trM) > 1e6
            trM = trace(pinv(Psi.'*Psi));
        end
        if N > NCoeff
            T = N/(N-NCoeff) * (1 + trM) ;
        else
            T = inf;
        end
        loo = T*loo;
        normEmpErr = T*normEmpErr;
        opt_results.T = T;
    end
else
    trM = trace(M);
    if trM < 0 || abs(trM) > 1e6
        trM = trace(pinv(Psi.'*Psi));
    end
    if N > NCoeff
        T = N/(N-NCoeff) * (1 + trM) ;
    else
        T = inf;
    end
    opt_results.T = T;
    opt_results.loo = loo;
    opt_results.ModifiedLoo = loo*T;
    opt_results.normEmpErr = normEmpErr;
    opt_results.ModifiednormEmpErr = normEmpErr*T;
    opt_results.LooPred = Y+sqrt(T)*res ./ (1-h); 
    if exist('modified_flag', 'var') && modified_flag
        loo = T*loo;
        normEmpErr = T*normEmpErr;
    end
end
