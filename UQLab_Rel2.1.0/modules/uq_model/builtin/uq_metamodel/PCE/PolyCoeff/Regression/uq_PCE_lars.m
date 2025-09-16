function results = uq_PCE_lars(univ_p_val, current_model)
% RESULTS = UQ_PCE_LARS(UNIV_P_VAL,PCMODEL): calculate the sparse PCE 
%     coefficients for the model in PCMODEL given the univariate polynomial
%     evaluations in univ_p_val with Least Angle Regression.
%
% See also: UQ_LAR, UQ_PCE_OLS_REGRESSION,
% UQ_PCE_CALCULATE_COEFFICIENTS_REGRESSION


% initializing the output status to 0
success = 0;

% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_PCE_lars cannot handle objects of type %s', current_model.Type);
end

% get the current output
current_output = current_model.Internal.Runtime.current_output;

DegreeEarlyStop = current_model.Internal.PCE(current_output).DegreeEarlyStop;

%% Generating the set of polynomial indices
Psi = uq_PCE_create_Psi(current_model.PCE(current_output).Basis.Indices, univ_p_val);


% get the experimental design model evaluations
Y = current_model.ExpDesign.Y(:,current_output);

%% Initialization of the LAR iterations
LarsEarlyStop = current_model.Internal.PCE(current_output).LARS.LarsEarlyStop;

ModifiedLoo = current_model.Internal.PCE(current_output).LARS.ModifiedLoo;

HybridLoo = current_model.Internal.PCE(current_output).LARS.HybridLoo;

% hybrid lars is always enabled
% HybridLars =  current_model.Internal.PCE(current_output).LARS.HybridLars;
HybridLars = true;

% verbosity level
DisplayLevel = current_model.Internal.Display;


%% iterative LAR
% set the options for the lar iterations:
lar_options.early_stop = LarsEarlyStop;
if isfield(current_model.Internal.PCE(current_output).LARS, 'Normalize')
    lar_options.normalize = current_model.Internal.PCE(current_output).LARS.Normalize;
else
    lar_options.normalize = true;
end
lar_options.hybrid_lars = HybridLars;
lar_options.loo_modified = ModifiedLoo;
lar_options.loo_hybrid = HybridLoo;
lar_options.display = DisplayLevel;

if isfield(current_model.ExpDesign, 'CY')
    lar_options.CY = current_model.ExpDesign.CY;
end

results.lar_options(current_output) = lar_options;

lar_results = uq_lar(Psi, Y, lar_options);



%% Assign the remaining outputs
coefficients = zeros(size(Psi,2),1);

results.coeff_array = lar_results.coeff_array;
results.max_score   = lar_results.max_score;

% now let's get the interesting results out of lar, and send them to the
% output
nz_idx = lar_results.nz_idx;
coefficients(nz_idx) = lar_results.coefficients(nz_idx);
results.coefficients  = coefficients;
results.coeff_array   = lar_results.coeff_array;
results.a_scores      = lar_results.a_scores;
results.loo_scores      = lar_results.loo_scores;

results.best_basis_index = lar_results.best_basis_index;

% The actual indices for the coefficients retrieved by LARS
results.indices = current_model.PCE(current_output).Basis.Indices;

% the order at which the indices were recovered
results.lars_idx = lar_results.lars_idx;

% now get the actual error from the resutls of the hybrid LARS
results.LOO = lar_results.LOO;
results.normEmpErr = lar_results.normEmpErr;
results.optErrorParams = lar_results.optErrorParams;
% and the LARs estimate of the LOO
results.LOO_lars = 1 - results.max_score;
