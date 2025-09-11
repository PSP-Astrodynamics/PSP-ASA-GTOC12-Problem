function results = uq_PCE_bcs(univ_p_val, current_model)
% Bayesian compressive sensing 
% in the version of Babacan, Molina, and Katsaggelos 2010 ("Fast Laplace")

%% Checks and options
% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_PCE_bcs cannot handle objects of type %s', current_model.Type);
end

% get the current output (only != 1 if we have vector-valued output)
current_output = current_model.Internal.Runtime.current_output;

% ModifiedLoo (or here rather modified CV error)
ModifiedLoo = current_model.Internal.PCE(current_output).BCS.ModifiedLoo;

if isfield(current_model.Internal.PCE(current_output).BCS, 'NumFolds')
    numFolds = current_model.Internal.PCE(current_output).BCS.NumFolds;
else % default
    numFolds = 10;
end

%% Generating the set of polynomial indices
Psi = uq_PCE_create_Psi(current_model.PCE(current_output).Basis.Indices, univ_p_val);

% get the experimental design model evaluations
Y = current_model.ExpDesign.Y(:,current_output);

% Take weights into account
if isfield(current_model.ExpDesign, 'CY')
    CY = current_model.ExpDesign.CY;
    CYinv = CY \ eye(size(CY));
    L = chol(CYinv);
    Psi = L*Psi;
    Y = L*Y;
end


%% 
[N, P] = size(Psi);
varY = var(Y);

if varY == 0
    varY = 1; % just for the computation of the range of sigma2's
end

sigma2_perc = 10.^linspace(-16,-1,10);
sigma2_values = varY * N * sigma2_perc;
eta_stop = 1e-7; % our default threshold for the relative change in L

%% Run FastLaplace (in the form of our implementation uq_bcs)
% First cross-validation to choose best hyperparameter sigma2

shuffled_indices = datasample(1:N, N, 'Replace', false);
size_fold = N / numFolds;
KfoldCVerror = zeros(numel(sigma2_values),1);

for s = 1:numel(sigma2_values)
    resnorm2 = 0;

    % CROSS-VALIDATION
    for k = 1:numFolds
        start_fold = round((k-1) * size_fold + 1);
        end_fold = round(k * size_fold);
        if (k == numFolds)
            % last fold uses all remaining points
            end_fold = N;
        end
        training_indices = horzcat(shuffled_indices(1:start_fold - 1), shuffled_indices(end_fold + 1:N));
        validation_indices = shuffled_indices(start_fold:end_fold);
        if ~isempty(intersect(training_indices, validation_indices))
            error('Something is wrong: training and validation set have nonempty intersection');
        end
        if ~(numel(validation_indices) + numel(training_indices) == N)
            error('Something is wrong: training and validation set don''t add up to whole set');
        end
        % Solve with solver on training set
        bcs_results = uq_bcs(Psi(training_indices, :), Y(training_indices), sigma2_values(s), eta_stop, 0);
        coeffs_fold = bcs_results.coeffs;
        
        % Compute norm of residual on validation set
        resnorm2  = resnorm2 + norm(Y(validation_indices) - Psi(validation_indices,:) * coeffs_fold)^2/ numel(validation_indices);
    end
    KfoldCVerror(s) = resnorm2 / numFolds / varY;
    
end

%% Determine hyperparameter with smallest CV error and recompute solution on full training set
[minCVerror, i_minCV] = min(KfoldCVerror);

% Recompute solution using pure method with best hyperparameter and full training set
bcs_results = uq_bcs(Psi, Y, sigma2_values(i_minCV), eta_stop, 0); %smaller eta_stop?
coeffs = bcs_results.coeffs;


%% Modified CV error (always computed)
Psi_active = Psi(:, bcs_results.active_indices);
nActive = numel(bcs_results.active_indices);

M = pinv(Psi_active'*Psi_active);
trM = trace(M);
if N > nActive
    T = N/(N-nActive) * (1 + trM) ;
else
    T = inf;
end

%% Prepare results
results.coefficients = coeffs;
results.indices = current_model.PCE(current_output).Basis.Indices; % ALL indices

normEmpErr = norm(Psi*coeffs - Y)^2/N/varY;

if ModifiedLoo
    loo = T*minCVerror;
    normEmpErr = T*normEmpErr;
else
    loo = minCVerror; % use unmodified CV error for model selection
    % no change in normEmpErr
end

results.LOO = loo; 
results.normEmpErr = normEmpErr;


opt_results.T = T;
opt_results.loo = minCVerror; % In this case, it is the cross-val error (10-fold by default)
opt_results.ModifiedLoo = minCVerror*T;
opt_results.normEmpErr = normEmpErr;
opt_results.ModifiednormEmpErr = normEmpErr*T;


results.optErrorParams = opt_results;

% %% Some additional information that we want to pass outside
% results.optErrorParams.sigma2 = sigma2_values;
% results.optErrorParams.CVerrors = KfoldCVerror;
% results.optErrorParams.bestIndex = i_minCV;
% results.optErrorParams.bcs_path = bcs_results.bcs_path;

end

