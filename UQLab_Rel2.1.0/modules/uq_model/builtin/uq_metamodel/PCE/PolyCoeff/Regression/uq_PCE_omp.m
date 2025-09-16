function results = uq_PCE_omp(univ_p_val, current_model)
% UQ_PCE_CALCULATE_COEFFICIENTS_OLS(MODULE): calculate via Orthogonal
% Matching Pursuit regression the polynomial chaos coefficients with the 
% options specified


% initializing the output status to 0
success = 0;

% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_PCE_omp cannot handle objects of type %s', current_model.Type);
end

% get the current output
current_output = current_model.Internal.Runtime.current_output;


%% Generating the set of polynomial indices
Psi = uq_PCE_create_Psi(current_model.PCE(current_output).Basis.Indices, univ_p_val);

% get the experimental design model evaluations
Y = current_model.ExpDesign.Y(:,current_output);


%% Initialization of the OMP iterations
DegreeEarlyStop = current_model.Internal.PCE(current_output).DegreeEarlyStop;
OmpEarlyStop = current_model.Internal.PCE(current_output).OMP.OmpEarlyStop;
TargetAccuracy = current_model.Internal.PCE(current_output).OMP.TargetAccuracy;
ModifiedLoo = current_model.Internal.PCE(current_output).OMP.ModifiedLoo;
KeepIterations = current_model.Internal.PCE(current_output).OMP.KeepIterations;

% verbosity level
DisplayLevel = current_model.Internal.Display;



%% iterative OMP
% set the options for the omp iterations:
omp_options.early_stop = OmpEarlyStop;
omp_options.modified_loo = ModifiedLoo;
omp_options.display = DisplayLevel;
omp_options.precision = TargetAccuracy;
omp_options.keepiterations = KeepIterations;

if isfield(current_model.ExpDesign, 'CY')
    omp_options.CY = current_model.ExpDesign.CY;
end

results.omp_options(current_output) = omp_options;

omp_results = uq_omp(Psi, Y, omp_options);



%% Assign the remaining outputs
coefficients = zeros(size(Psi,2),1);


% check that we are not running in adaptive basis mode
if DegreeEarlyStop
    idx = current_model.Internal.Runtime.degree_index;
    results.coeff_array = omp_results.coeff_array;
    results.max_score(idx) = omp_results.max_score;
else % update the set of best coefficients if not in basis adaptive mode
    results.coeff_array = omp_results.coeff_array;
    results.max_score   = omp_results.max_score;
end

% now let's get the interesting results out of omp, and send them to the
% output
nz_idx = omp_results.nz_idx;
coefficients(nz_idx) = omp_results.coefficients(nz_idx);
%results.coefficients  = omp_results.coefficients;
results.coefficients  = coefficients;
results.coeff_array   = omp_results.coeff_array;
results.a_scores      = omp_results.a_scores;
results.loo_scores      = 1 - omp_results.a_scores;

results.best_basis_index = omp_results.best_basis_index;

% The actual indices for the coefficients retrieved by OMP
%results.indices = current_model.PCE(current_output).Basis.Indices(nz_idx,:);
results.indices = current_model.PCE(current_output).Basis.Indices;

% the order at which the indices were recovered
results.omp_idx = omp_results.nz_idx;

% now get the actual error from the resutls of the hybrid OMP
%[results.LOO, results.normEmpErr] = uq_PCE_loo_error(Psi(:,nz_idx), M, Y, results.coefficients, 1);
results.LOO = omp_results.LOO;
results.normEmpErr = omp_results.normEmpErr;
results.optErrorParams = omp_results.optErrorParams;

% and the OMPs estimate of the LOO
results.LOO_omp = 1 - results.max_score;



