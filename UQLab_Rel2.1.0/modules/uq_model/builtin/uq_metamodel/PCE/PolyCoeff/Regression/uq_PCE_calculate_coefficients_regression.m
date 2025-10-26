function success = uq_PCE_calculate_coefficients_regression(current_model)
% SUCCESS = UQ_PCE_CALCULATE_COEFFICIENTS_REGRESSION(CURRENT_MODEL):
%     Calculate the polynomial chaos coefficients of CURRENT_MODEL via
%     least-square regression.
%
% See also: UQ_PCE_CALCULATE_COEFFICIENTS_PROJECTION

%% CONSISTENCY CHECKS AND INITIALIZATION
% initialize the output status to 0
success = 0;

% Check that the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_metamodel cannot handle objects of type %s', current_model.Type);
end

% Verbosity level
DisplayLevel = current_model.Internal.Display;

%% Retrieve the necessary information from the framework
% current output of the model
current_output = current_model.Internal.Runtime.current_output;
PCEOptions = current_model.Internal.PCE(current_output);

%% Generate the initial experimental design

% The experimental design is calculated only for the first component
% (reused afterwards)
if current_output == 1
    % create the experimental design X
    [current_model.ExpDesign.X, current_model.ExpDesign.U] = uq_getExpDesignSample(current_model);
    
    % and evaluate it with the full model
    current_model.ExpDesign.Y = uq_eval_ExpDesign(current_model,current_model.ExpDesign.X);
    
    % Update the number of output variables of the model
    Nout = size(current_model.ExpDesign.Y, 2);
    current_model.Internal.Runtime.Nout = Nout;
    % copy the necessary information about the PCE options to the various
    % output coordinates
    for oo = 2:Nout
        current_model.Internal.PCE(oo) =  current_model.Internal.PCE(1);
        current_model.PCE(oo).Basis.PolyTypes = current_model.PCE(1).Basis.PolyTypes;
        current_model.PCE(oo).Basis.PolyTypesParams = current_model.PCE(1).Basis.PolyTypesParams;
        current_model.PCE(oo).Basis.PolyTypesAB     = current_model.PCE(1).Basis.PolyTypesAB;
    end
end


%% Least-square regression
% detect if the regression is basis-adaptive
current_model.Internal.PCE(current_output).DegreeArray = PCEOptions.Degree;
current_model.Internal.PCE(current_output).Degree = current_model.Internal.PCE(current_output).DegreeArray(1);
current_model.Internal.Runtime.degree_index = 1;
current_model.Internal.Runtime.qnorm_index = 1;

% target accuracy stopping criterion
regMethod = upper(current_model.Internal.Method);
TargetAccuracy = PCEOptions.(regMethod).TargetAccuracy;


% Read the number of qNorms given
Truncation = current_model.Internal.PCE(current_output).Basis.Truncation;
nqnorms = length(Truncation.qNorm);

% Running adaptive in the degree an qNorm or not?
if isfield(PCEOptions, 'DegreeEarlyStop')
    DegreeEarlyStop = PCEOptions.DegreeEarlyStop;
else
    DegreeEarlyStop = true;
end
if isfield(PCEOptions, 'qNormEarlyStop')
    qNormEarlyStop = PCEOptions.qNormEarlyStop;
else
    qNormEarlyStop = true; % default to qNorm Early Stop
end
% some options for EarlyStop
% stop degree, if LOO error does not decrease n_checks_degree times
n_checks_degree = 2;
% stop qNorm, if criterion isn't fulfilled n_checks_qNorm times
n_checks_qNorm = 2;
if nqnorms < n_checks_qNorm+1
    qNormEarlyStop = false;
end

%% OLS options
% defaults
olsoptions.modified_loo = true;
if isfield(PCEOptions, 'OLS') && isfield(PCEOptions.OLS, 'ModifiedLoo')
    olsoptions.modified_loo = PCEOptions.OLS.ModifiedLoo;
end


%% Generating the set of polynomial indices

% we only want to do run metamodelling on the non-constant variables
M = current_model.Internal.Runtime.MnonConst;

%% Start of Adaptivity loops

% Overall score indicator: this will be used to compare between different
% methods
bestScore = -inf;

% basis adaptive polynomial chaos: repeat the calculation by
% increasing polynomial degree until the target accuracy is reached
% For each degree check all q-norms and choose the best one
scores = -inf*ones(size(current_model.Internal.PCE(current_output).DegreeArray));

for itr = 1:length(current_model.Internal.PCE(current_output).DegreeArray)
    pp = (current_model.Internal.PCE(current_output).DegreeArray(itr));
    
    current_model.Internal.PCE(current_output).Degree = pp;
    
    % some diagnostic output
    if DisplayLevel > 1
        fprintf('\n\nCalculating PCE coefficients up to degree %d\n',pp);
        fprintf('Generating the polynomial basis indices...\n')
    end
    
    % cycle through qNorms
    % save their score (1-LOO) and number of basis elements for
    % qNormEarlyStop. 
    qNormScore = -inf*ones(nqnorms,1);
    qNormBasisSize = zeros(nqnorms,1);
    % set the truncation options
    truncOpts = Truncation;
    for qq = 1:nqnorms
        truncOpts.qNorm = Truncation.qNorm(qq);
                
        % some diagnostic output
        if DisplayLevel > 1
            fprintf('\n\nCalculating PCE coefficients up with qNorm %1.2f\n',truncOpts.qNorm);
        end
        
        % Generate the alpha index matrix
        current_model.PCE(current_output).Basis.Indices = ...
            uq_generate_basis_Apmj(0:pp, M, truncOpts);
        
        % Update the basis size of the current q-norm
        qNormBasisSize(qq) = size(current_model.PCE(current_output).Basis.Indices,1);
        % skip the qNorm if it's the same as last iteration
        if qq > 1
            if qNormBasisSize(qq) == qNormBasisSize(qq-1)
                if DisplayLevel > 1
                    fprintf('Skipping qNorm %.2f because it did not enrich the basis.\n',truncOpts.qNorm)
                end
                qNormScore(qq) = -inf; % update the score only and get back to the beginning
                continue;
            end
        end
        
        if DisplayLevel > 1
            fprintf('Polynomial basis indices generation complete!\n\n')
            % time to evaluate the univariate polynomials on the
            % experimental design
            fprintf('Evaluating the univariate polynomials on the experimental design...\n')
        end
        
        univ_p_val = uq_PCE_eval_unipoly(current_model);
        
        if DisplayLevel > 1
            fprintf('Evaluation of the univariate polynomials complete!\n\n')
        end
        
        switch lower(current_model.Internal.Method)
            case 'ols'
                if DisplayLevel > 1
                    fprintf('Calculating the coefficients with Ordinary Least Squares...\n')
                end
                Psi = uq_PCE_create_Psi(current_model.PCE(current_output).Basis.Indices, univ_p_val);
                Y = current_model.ExpDesign.Y(:,current_output);
                if isfield(current_model.ExpDesign, 'CY')
                    olsoptions.CY = current_model.ExpDesign.CY;
                    ols_results = uq_PCE_OLS_regression(Psi, Y, olsoptions);
                else
                    ols_results = uq_PCE_OLS_regression(Psi, Y, olsoptions);
                end
                
                % save the score and the number of basis elements
                qNormScore(qq) = 1 - ols_results.LOO;
                
                % Select the best qNorm if it's better than the previous
                if qq == 1 || qNormScore(qq) > scores(itr)
                    scores(itr) = qNormScore(qq);
                    results = ols_results;
                    results.indices =  current_model.PCE(current_output).Basis.Indices;
                    best_qNorm_pp =  truncOpts.qNorm; % best q-norm for current degree pp
                end

                
            case 'lars'
                if DisplayLevel > 1
                    fprintf('Calculating the coefficients with the Lars algorithm...\n')
                end
                lars_results = uq_PCE_lars(univ_p_val, current_model);
                if current_model.Internal.Options.debug
                    current_model.Internal.PCE(current_output).LARS.lars_results = lars_results;
                end
                
                % save the score and the number of basis elements
                qNormScore(qq) = 1 - lars_results.LOO;
                               
                % Select the best qNorm if it's better than the previous
                if qq == 1 ||qNormScore(qq) > scores(itr)
                    scores(itr) = qNormScore(qq,1);
                    results = lars_results;
                    best_qNorm_pp =  truncOpts.qNorm; % best q-norm for current degree pp
                end
                
                
                
            case 'omp'
                if DisplayLevel > 1
                    fprintf('Calculating the coefficients with the OMP algorithm...\n')
                end
                omp_results = uq_PCE_omp(univ_p_val, current_model);
                if current_model.Internal.Options.debug
                    current_model.Internal.PCE(current_output).OMP.omp_results = omp_results;
                end
                
                % save the score and the number of basis elements
                qNormScore(qq) = 1 - omp_results.LOO;
                
                % Select the best qNorm if it's better than the previous
                if qq == 1 || qNormScore(qq) > scores(itr)
                    scores(itr) = qNormScore(qq,1);
                    results = omp_results;
                    best_qNorm_pp =  truncOpts.qNorm; % best q-norm for current degree pp
                end

            otherwise
            % try to execute based on the name
            try
                eval(['custom_results = uq_PCE_' lower(current_model.Internal.Method) '(univ_p_val, current_model);']);
                % save the score and the number of basis elements
                qNormScore(qq) = 1 - custom_results.LOO;
                % Select the best qNorm if it's better than the previous
                if qq == 1 || qNormScore(qq) > scores(itr)
                    scores(itr) = qNormScore(qq,1);
                    results = custom_results;
                    best_qNorm_pp =  truncOpts.qNorm; % best q-norm for current degree pp
                end

            catch me
                disp(me.message)
                disp(me.stack(1))
                error('could not execute the specified %s regression method!',current_model.Internal.Method);
            end
        end
        % and increase the qnorm_index
        current_model.Internal.Runtime.qnorm_index = current_model.Internal.Runtime.qnorm_index + 1;
        
        % EarlyStop check
        % if there are at least n_checks_qNorm entries after the
        % best one, we stop
        if qNormEarlyStop && sum(isfinite(qNormScore)) > n_checks_qNorm
            % If the score has decreased (i.e., the error has increased) 
            % the last two iterations, stop
            % increase in score = 1, non-increase = 0
            deltas = (diff(qNormScore(isfinite(qNormScore))) > 0); 
            if sum(deltas(end-n_checks_qNorm+1:end)) == 0
                % stop the q-norm loop here
                break
            end
        end
        
    end % of qNorm loop
        
    %%% qNorm adaptivity ends here. At this point the best qNorm is chosen. The following is only done for degree. %%%
    
    current_model.Internal.PCE(current_output).(upper(regMethod)).LOO(itr) = results.LOO;
    current_model.Internal.PCE(current_output).(upper(regMethod)).normEmpErr(itr) = results.normEmpErr;
    % Update DegreeEarlyStop criterion if provided in the
    % options
    if isfield(current_model.Internal.PCE(current_output).(upper(regMethod)),'DegreeEarlyStop')
        DegreeEarlyStop = current_model.Internal.PCE(current_output).(upper(regMethod)).DegreeEarlyStop;
    end

    % and displaying the current error estimates
    if DisplayLevel > 1
        switch lower(current_model.Internal.Method)
            case 'ols'
                % need to put an abs just for underdetermined problems
                fprintf('Current estimated normalized empirical error: %e\n', abs(results.normEmpErr));
            otherwise
                fprintf('Current estimated normalized empirical error: %e\n', results.normEmpErr);
        end
        fprintf('Current estimated leave-one-out error: %e\n', results.LOO);
    end
    
    % make sure that infinite scores are set to -infinity and they
    % are not picked as the best
    if ~isfinite(scores(itr))
        scores(itr) = -inf;
    end
    % now retrieve the results if they are the current best
    if (itr == 1) || (scores(itr) > bestScore) % if the current score is the best one, update the indices and coefficients thus far
        bestScore = scores(itr);
        
        best_degree = pp;
        best_qNorm = best_qNorm_pp; % q-norm associated to pp
        best_indices = results.indices;
        best_coeffs = results.coefficients;
        best_loo = abs(results.LOO);
        best_optErrorParams = results.optErrorParams;
        best_normEmpErr = results.normEmpErr;
        
        % lars-specific results
        if exist('lars_results', 'var')
            best_coeffs_array = results.coeff_array;
            best_a_scores = results.a_scores;
            
            best_lars_idx = results.lars_idx;
            best_loo_scores = results.loo_scores;
            best_loo_lars = results.LOO_lars;
        end
        
        % omp-specific results
        if exist('omp_results', 'var')
            best_coeffs_array = results.coeff_array;
            best_a_scores = results.a_scores;
            
            best_omp_idx = results.omp_idx;
            best_loo_scores = results.loo_scores;
            best_loo_omp = results.LOO_omp;
        end
    end
    
    
    
    % All needed  information is taken from this iteration. Now it
    % is compared to the ones before.
    
    % also check the direction of the error:
    % if it increases consistently stop the iterations
    errorIncreases = 0;
    if length(scores(~isinf(scores))) > n_checks_degree
        ss = sign(scores(~isinf(scores)) - max(scores(~isinf(scores))));
        errorIncreases = sum(sum(ss(end-1:end))) <= -n_checks_degree;
    end
    
    % stop if the target accuracy is reached, or if the error increases
    % consistently
    stopNow = (best_loo <= TargetAccuracy) || (DegreeEarlyStop && errorIncreases) || pp == current_model.Internal.PCE(current_output).DegreeArray(end);
    
    if stopNow
        if DisplayLevel > 0
            if (best_loo <= TargetAccuracy) || errorIncreases
                fprintf('The estimation of PCE coefficients converged at polynomial degree %d and qNorm %1.2f for output variable %d\n', best_degree, best_qNorm, current_output);
            else
                fprintf('The estimation of PCE coefficients stopped at polynomial degree %d and qNorm %1.2f for output variable %d\n', best_degree, best_qNorm, current_output);
            end
            fprintf('Final LOO error estimate: %d\n',best_loo);
        end
        
        % now assign the relevant indices and coefficients
        current_model.PCE(current_output).Basis.Indices = best_indices;
        current_model.PCE(current_output).Coefficients = best_coeffs;
        current_model.Internal.PCE(current_output).Degree = best_degree;
        current_model.Internal.PCE(current_output).BestDegree = best_degree;
        % overwrite the q-norm array with the best q-norm:
        current_model.Internal.PCE(current_output).Basis.Truncation.qNorm = best_qNorm;
        
        % current_model.Internal.PCE(current_output).Basis.Truncation.BestqNorm = best_qNorm;
        FN = fieldnames(best_optErrorParams);
        for nn = 1:length(FN)
            current_model.Internal.Error(current_output).(FN{nn}) = best_optErrorParams.(FN{nn});
        end
        if isfield(best_optErrorParams,'loo')
            current_model.Error(current_output).LOO = best_optErrorParams.loo;
        end
        if isfield(best_optErrorParams,'ModifiedLoo')
            current_model.Error(current_output).ModifiedLOO = best_optErrorParams.ModifiedLoo;
        end
        if isfield(best_optErrorParams,'normEmpErr')
            current_model.Error(current_output).normEmpErr = best_optErrorParams.normEmpErr;
        end
        
        if isfield(best_optErrorParams,'LooPred')
            current_model.Error(current_output).LooPred = best_optErrorParams.LooPred;
        end
%         current_model.Internal.Error(current_output).optErrorParams = best_optErrorParams;
        if exist('lars_results', 'var')
            % only save the coefficients if needed
            if current_model.Internal.PCE(current_output).LARS.KeepIterations
                current_model.Internal.PCE(current_output).LARS.coeff_array = best_coeffs_array;
            end
            current_model.Internal.PCE(current_output).LARS.lars_idx = best_lars_idx;
            current_model.Internal.PCE(current_output).LARS.a_scores = best_a_scores;
            current_model.Internal.PCE(current_output).LARS.loo_scores = best_loo_scores;
            current_model.Internal.Error(current_output).LOO_lars = best_loo_lars;
        end
        if exist('omp_results', 'var')
            % only save the coefficients if needed
            if current_model.Internal.PCE(current_output).OMP.KeepIterations
                current_model.Internal.PCE(current_output).OMP.coeff_array = best_coeffs_array;
            end
            current_model.Internal.PCE(current_output).OMP.omp_idx = best_omp_idx;
            current_model.Internal.PCE(current_output).OMP.a_scores = best_a_scores;
            current_model.Internal.PCE(current_output).OMP.loo_scores = best_loo_scores;
            current_model.Internal.Error(current_output).LOO_omp = best_loo_omp;
        end
        
        break;
    end
    % and increase the degree_index
    current_model.Internal.Runtime.degree_index = current_model.Internal.Runtime.degree_index + 1;
end

% Store the final

if DisplayLevel > 0
    % print out a warning if the final accuracy was not met (and it
    % was set > 0)
    if best_loo > PCEOptions.(regMethod).TargetAccuracy && PCEOptions.(regMethod).TargetAccuracy
        fprintf('Warning: the desired target accuracy of %e could not be reached with the current experimental design!\n', PCEOptions.(regMethod).TargetAccuracy);
        fprintf('Final accuracy: %e\n\n', current_model.Error(current_output).LOO);
    end
end


% Now that the coefficients are calculated, we can calculate bootstrap
% bounds on the coefficients
if isfield(PCEOptions, 'Bootstrap') && ~isempty(PCEOptions.Bootstrap)
    if DisplayLevel
        fprintf('Calculating Bootstrap replications... ')
    end
    %% Generating the set of polynomial indices
    nnz_idx = current_model.PCE(current_output).Coefficients ~= 0;
    % assemble a Psi matrix only with the sparse basis (if any)
    Psi = uq_PCE_create_Psi(current_model.PCE(current_output).Basis.Indices(nnz_idx,:), univ_p_val);
    % run the bootstrap for the OLS problem (works for LARS as well, as it it just a sparse OLS)
    OLSBootstrap = uq_OLS_bootstrap(Psi, current_model.ExpDesign.Y(:,current_output), PCEOptions.Bootstrap);
    
    % copy over the settings from the Bootstrap into each output
    FN = fieldnames(PCEOptions.Bootstrap);
    for kk = 1:length(FN)
        current_model.Internal.Bootstrap(current_output).(FN{kk}) = PCEOptions.Bootstrap.(FN{kk});
    end
    % now create a custom PCE with the retrieved coefficients (for later
    % evaluation)
    BPCEOpts.Type = 'Metamodel';
    BPCEOpts.MetaType = 'PCE';
    BPCEOpts.Method = 'Custom';
    BPCEOpts.Display = 0; 
    % Take care that there is always at least one basis coefficient (the
    % constant term)
    BPCEBasis.Indices = current_model.PCE(current_output).Basis.Indices(nnz_idx,:);
    if isempty(BPCEBasis.Indices)
        BPCEBasis.Indices = sparse(zeros(1,M));
    end
    BPCEBasis.PolyTypes = current_model.PCE(current_output).Basis.PolyTypes;
    BPCEBasis.PolyTypesParams = current_model.PCE(current_output).Basis.PolyTypesParams;
    BPCEBasis.PolyTypesAB = current_model.PCE(current_output).Basis.PolyTypesAB;
    BPCE = struct([]);
    for ii = 1:size(OLSBootstrap.BArray, 2)
        BPCE(ii).Basis = BPCEBasis;
        if sum(nnz_idx)
            BPCE(ii).Coefficients = OLSBootstrap.BArray(:,ii);
        else
            BPCE(ii).Coefficients = 0;
        end
    end
    BPCEOpts.PCE = BPCE;
    BPCEOpts.Input = current_model.Internal.Input;
    % create the nested PCE
    current_model.Internal.Bootstrap(current_output).BPCE = uq_createModel(BPCEOpts, '-private');
    
    % copy over any remaining fields from the Bootstrap results into the
    % stored Bootstrap
    FN = fieldnames(OLSBootstrap);
    for kk = 1:length(FN)
        current_model.Internal.Bootstrap(current_output).(FN{kk}) = OLSBootstrap.(FN{kk});
    end
    
    if DisplayLevel
       fprintf('done!\n');
    end
end



%% Output
success = 1;
