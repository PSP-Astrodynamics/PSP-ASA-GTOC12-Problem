function results = uq_sensitivity(CurrentAnalysis)
% RESULTS = UQ_SENSITIVITY(CURRENTANALYSIS): entry point for the calculation of
%     sensitivity measures in UQLab. The appropriate method is run based on
%     the options in CURRENTANALYSIS and the results are formatted and stored in the
%     CurrentAnalysis.Results structure.
%
% See also: UQ_CORRELATION_INDICES,UQ_SRC_INDICES,UQ_COTTER_INDICES,
%           UQ_PERTURBATION_METHOD,UQ_MORRIS_INDICES,UQ_SOBOL_INDICES


%% RETRIEVE THE VALIDATED SENSITIVITY OPTIONS
Options = CurrentAnalysis.Internal;

%% Select the Method
switch lower(Options.Method)
    % Correlation based indices:
    case 'correlation'
        if Options.Display > 0
            fprintf('\nStarting Correlation Analysis...\n');
        end
        
        results = uq_correlation_indices(CurrentAnalysis);
        
    % Standard Regression Coefficients
    case 'src'
        if Options.Display > 0
            fprintf('\nStarting Standard Regression Coefficients Analysis...\n');
        end
        
        results = uq_SRC_indices(CurrentAnalysis);
        
        
    % Cotter method:
    case 'cotter'
        if Options.Display > 0
            fprintf('\nStarting Cotter Analysis...\n');
        end
        
        results = uq_cotter_indices(CurrentAnalysis);
        
    case 'perturbation'
        if Options.Display > 0
            fprintf('\nStarting Perturbation Analysis...\n');
        end
        
        results = uq_perturbation_method(CurrentAnalysis);
        
    % Morris method:
    case 'morris'
        
        if Options.Display > 0
            fprintf('\nStarting Morris Analysis...\n');
        end
        
        results = uq_morris_indices(CurrentAnalysis);
        
    % Sobol' indices:
    case 'sobol'
        
        if Options.Display > 0
            fprintf('\nStarting Sobol'' indices analysis...\n');
        end
        
        % If the model is a PCE or LRA metamodel, and it is not specified 
        % otherwise, then calculate its analytical indices:
        if strcmpi(Options.Model.Type, 'uq_metamodel') && ...
                any(strcmpi(Options.Model.MetaType, {'pce','lra'})) && ...
                Options.Sobol.CoefficientBased
            
            if Options.Display > 0
                fprintf('\nCalculating %s-based Sobol'' indices up to order %d\n',...
                    upper(Options.Model.MetaType),Options.Sobol.Order);
            end

            % Calculate with the respective method:
            switch lower(Options.Model.MetaType)
                case 'pce'
                    results = uq_PCE_sobol_indices(Options.Sobol.Order, Options.Model);
                case 'lra'
                    results = uq_LRA_sobol_indices(Options.Sobol.Order, Options.Model);
%                 case 'sse'
%                     results = uq_SSE_sobol_indices(Options.Sobol.Order, Options.Model);
            end
            results.CoefficientBased = true;
        else
            
            results = uq_sobol_indices(CurrentAnalysis);
            results.CoefficientBased = false;
        end
    case 'borgonovo'
        if Options.Display > 0
            fprintf('\nStarting Borgonovo indices analysis...\n');
        end

        results = uq_borgonovo_indices(CurrentAnalysis);
        
    % ANCOVA indices:
    case 'ancova'
        
        if Options.Display > 0
            fprintf('\nStarting ANCOVA indices analysis...\n');
        end
        results = uq_ancova_indices(CurrentAnalysis);
        
    % Kucherenko indices:
    case 'kucherenko'
        
        if Options.Display > 0
            fprintf('\nStarting Kucherenko indices analysis...\n');
        end
        results = uq_kucherenko_indices(CurrentAnalysis);
        
    % Shapley indices:
%     case 'shapley'
%         
%         if Options.Display > 0
%             fprintf('\nStarting Shapley indices analysis...\n');
%         end
%         results = uq_shapley_indices_ApproxRe(CurrentAnalysis);
        
    otherwise
        
        error('The selected method "%s" is not implemented yet in the uq_sensitivity module.', Options.Method);
        
end


%% Try to add variable names to the results:
try % from input object
    [VariableNames{1:length(CurrentAnalysis.Internal.Input.Marginals)}] = ...
        deal(Options.Input.Marginals.Name);
    
    results.VariableNames = VariableNames;
catch
    for ii = 1:Options.M
        results.VariableNames{ii} = sprintf('X%i',ii);
    end
end

