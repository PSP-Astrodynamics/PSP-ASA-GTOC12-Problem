function results = uq_PCE_sp(univ_p_val, current_model)
% Wrapper for the Subspace pursuit algorithm 

% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_PCE_sp cannot handle objects of type %s', current_model.Type);
end

% get the current output
current_output = current_model.Internal.Runtime.current_output;

ModifiedLooFlag = current_model.Internal.PCE(current_output).SP.ModifiedLoo;

% Method to determine best K
if isfield(current_model.Internal.PCE(current_output).SP, 'CVMethod')
    CVMethod = lower(current_model.Internal.PCE(current_output).SP.CVMethod);
    if strcmpi(CVMethod, 'kfold')
        if isfield(current_model.Internal.PCE(current_output).SP, 'NumFolds')
            numFolds = current_model.Internal.PCE(current_output).SP.NumFolds;
        else
            numFolds = 5;
        end
    end
else
    CVMethod = 'loo'; % default
end

% Number of nonzeros in the solution
if isfield(current_model.Internal.PCE(current_output).SP, 'NNZ')
    K = current_model.Internal.PCE(current_output).SP.NNZ;
else
    K = []; % default: determine by CV
end

% Options (for .Normalize and .Hybrid)
SP_options = current_model.Internal.PCE(current_output).SP;

%% Generate the regression matrix
Psi = uq_PCE_create_Psi(current_model.PCE(current_output).Basis.Indices, univ_p_val);
[N, P] = size(Psi);

% get the experimental design model evaluations
Y = current_model.ExpDesign.Y(:,current_output);


%% Take weights into account
if isfield(current_model.ExpDesign, 'CY')
    CY = current_model.ExpDesign.CY;
    CYinv = CY \ eye(size(CY));
    L = chol(CYinv);
    Psi = L*Psi;
    Y = L*Y;
end

%% Subspace pursuit

if ~isempty(K) % one value was specified for K = #nonzeros in solution
    coeffs = uq_sp(Psi, Y, K, SP_options);
    nonzero_locations = (coeffs ~= 0);
    Psi_nonzero = Psi(:, nonzero_locations);
    [loo, normEmpErr, opt_results] = uq_PCE_loo_error(Psi_nonzero, pinv(Psi_nonzero'*Psi_nonzero), Y, coeffs(nonzero_locations), ModifiedLooFlag, false);

    % Prepare results
    results.coefficients = coeffs;
    results.LOO = loo; %LOO;
    results.normEmpErr = normEmpErr; %mean((Y - Psi*coeffs).^2) / var(Y,1);
    results.indices = current_model.PCE(current_output).Basis.Indices; % ALL indices
    results.optErrorParams = opt_results;
    
else % K == []
        
    % Either LOO or k-fold CV
    switch lower(CVMethod)
        case 'loo'
            % need to determine best K
            numKvalues = 10; % number of sparsity values to try
            % Need 2K <= N for OLS solution AND want sparse solution --> K <= P/2
            K_values = floor(linspace(1, min(P/2, N/2), numKvalues+1)); % Possible sparsities
            K_values = unique(K_values); % for small N or P, some values can occur several times
            if numel(K_values) > 1
                K_values(1) = []; % remove the entry K=1
            end
            numKvalues = numel(K_values);
            
            %% Find best K with LOO 

            coeffs_array = cell(numKvalues, 1);
            loo = zeros(numKvalues, 1);
            normEmpErr = zeros(numKvalues,1);
            opt_results = cell(numKvalues, 1);

            for k = 1:numKvalues
                coeffs_array{k} = uq_sp(Psi, Y, K_values(k), SP_options);
                nonzero_locations = (coeffs_array{k} ~= 0);
                Psi_nonzero = Psi(:, nonzero_locations);
                % Compute LOO error based on active basis returned by SP
                % We can do this because SP computes the coefficients using OLS
                [loo(k), normEmpErr(k), opt_results{k}] = uq_PCE_loo_error(Psi_nonzero, pinv(Psi_nonzero'*Psi_nonzero), Y, coeffs_array{k}(nonzero_locations), ModifiedLooFlag, false);
            end
            [~, i_minloo] = min(loo);

            % Prepare results
            results.coefficients = coeffs_array{i_minloo};
            results.LOO = loo(i_minloo);
            results.normEmpErr = normEmpErr(i_minloo);
            results.indices = current_model.PCE(current_output).Basis.Indices;
            results.optErrorParams = opt_results{i_minloo};
            
        case 'kfold'
            size_fold = N / numFolds;
            shuffled_indices = randperm(N);
            
            % need to determine best K
            numKvalues = 10; % number of sparsity values to try
            % Need 2K <= N for OLS solution AND want sparse solution --> K <= P/2
            K_values = floor(linspace(1, min(P/2, (N-ceil(size_fold))/2), numKvalues+1)); % Possible sparsities
            K_values = unique(K_values); K_values(1) = []; % for small N or P, some values can occur several times
            numKvalues = numel(K_values);
            
            KfoldCVerror = zeros(numKvalues,1);
            varY = var(Y);
            
            
            for k = 1:numKvalues
                residual_norm = 0;

                % CROSS-VALIDATION
                for ff = 1:numFolds
                    start_fold = round((ff-1) * size_fold + 1);
                    end_fold = round(ff * size_fold);
                    if (ff == numFolds)
                        % last fold uses all remaining points
                        end_fold = N;
                    end
                    training_indices = horzcat(shuffled_indices(1:(start_fold-1)), shuffled_indices((end_fold+1):N));
                    validation_indices = shuffled_indices(start_fold:end_fold);
                    if ~isempty(intersect(training_indices, validation_indices))
                        error('Something is wrong: training and validation set have nonempty intersection');
                    end
                    if ~(numel(validation_indices) + numel(training_indices) == N)
                        error('Something is wrong: training and validation set don''t add up to whole set');
                    end
                    % Solve with solver on training set
                    coeffs = uq_sp(Psi(training_indices, :), Y(training_indices), K_values(k), SP_options);
                    
                    % Compute norm of residual on validation set
                    residual_norm  = residual_norm + norm(Y(validation_indices) - Psi(validation_indices,:) * coeffs)^2 / numel(validation_indices);
                end
                KfoldCVerror(k) = residual_norm / numFolds / varY;

            end

            [~, min_ind] = min(KfoldCVerror);
            best_K = K_values(min_ind);
            
            % Perform SP on the full dataset with this K
            coeffs = uq_sp(Psi, Y, best_K, SP_options);
            
            % Compute the LOO error
            nonzero_locations = (coeffs ~= 0);
            Psi_nonzero = Psi(:, nonzero_locations);
            [loo, normEmpErr, opt_results] = uq_PCE_loo_error(Psi_nonzero, pinv(Psi_nonzero'*Psi_nonzero), Y, coeffs(nonzero_locations), ModifiedLooFlag, false);

            % Prepare results
            results.coefficients = coeffs;
            results.LOO = loo;
            results.normEmpErr = normEmpErr;
            results.indices = current_model.PCE(current_output).Basis.Indices;
            results.optErrorParams = opt_results;
            
        otherwise
            error('uq_PCE_sp: unknown CVMethod %s. Must be either ''LOO'' or ''kfold''!', CVMethod)
    end


end

end

