function results = uq_rbdo (current_analysis)
% UQ_RBDO provides the starting point for any reliability based design
% optimization in UQLab. It directs to the corresponding file for the
% RBDO methods
%
% See also: UQ_QMC, ...
%% Set the options
current_analysis.Internal.Runtime.ModelEvaluations = 0 ;
%% Book-keeping
current_analysis.Internal.Runtime.RecordedConstraints = [] ;
current_analysis.Internal.Runtime.RecordedSoftConstraints = [] ;

Options = current_analysis.Internal ;

%% Select the methods
switch lower(Options.Method)
    
    case {'two-level','two level'}   % Quantile-based Monte Carlo
        switch lower(current_analysis.Internal.Reliability.Method)
            case {'mcs'}
                if Options.Display > 0
                    fprintf('\nStarting a two level method using Monte Carlo Sampling in the inner loop...\n\n');
                end
            case {'form'}
                if Options.Display > 0
                    fprintf('\nStarting a two level method using FORM in the inner loop...\n\n');
                end
            case {'sorm'}
                if Options.Display > 0
                    fprintf('\nStarting a two level method using SORM in the inner loop...\n\n');
                end
            case {'is'}
                if Options.Display > 0
                    fprintf('\nStarting a two level method using Importance Sampling in the inner loop...\n\n');
                end
            case {'subset'}
                if Options.Display > 0
                    fprintf('\nStarting a two level method using Subset Sampling in the inner loop...\n\n');
                end
            case{'qmc'}
                if Options.Display > 0  % Add Display options later
                    fprintf('\nStarting a two level method using Quantile Monte carlo in the inner loop...\n\n');
                end
            case {'iform'}
                if Options.Display > 0
                    fprintf('\nStarting a two level method using inverse FORM in the inner loop...\n\n');
                end
            otherwise
                error('The selected reliability analysis method "%s" does not exist', current_analysis.Internal.Reliability.Method)
        end
        % Directly run optimizer, the constraints will call the inner loop
        results = uq_runRBDOptimizer(current_analysis) ;
        
    case{'mono level', 'mono-level', 'sla'}
        fprintf('\nStarting a single loop approach (SLA)...\n\n');
        results = uq_sla( current_analysis ) ;
        
        
    case {'decoupled', 'decoupled approach'}
        switch lower(current_analysis.Internal.Reliability.Method)
            case { 'inverse form', 'iform', 'inverseform'}
                if Options.Display > 0
                    fprintf('\nStarting a decoupled approach using sequential optimization reliability assessment (SORA)...\n\n');
                end
                results = uq_sora( current_analysis ) ;
            otherwise
                error('The selected reliability analysis method "%s" does not exist', current_analysis.Internal.Reliability.Method)
        end
        % Other direct naming of the approaches
    case{'ria'}
        if Options.Display > 0
            fprintf('\nStarting Reliability Index Approach...\n\n');
        end
        % Directly run optimizer, the constraints will call the inner loop
        results = uq_runRBDOptimizer(current_analysis) ;
    case{'pma'}
        if Options.Display > 0
            fprintf('\nStarting Performance Measure Approach...\n\n');
        end
        % Directly run optimizer, the constraints will call the inner loop
        results = uq_runRBDOptimizer(current_analysis) ;
    case{'sora'}
        if Options.Display > 0
            fprintf('\nStarting Sequential Optimization and Reliability Assessment (SORA) approach...\n\n');
        end
        results = uq_sora( current_analysis ) ;
        
    case {'qmc'}
        if Options.Display > 0
            fprintf('\nStarting Quantile Monte Carlo (QMC) optimization approach...\n\n');
        end
        results = uq_runRBDOptimizer(current_analysis) ;
    case 'deterministic'
        if Options.Display > 0
            fprintf('\nStarting determistic design optimization (DDO)...\n\n');
        end
        results = uq_runRBDOptimizer(current_analysis) ;
    otherwise
        error('The selected RBDO method "%s" does not exist', Options.Method)
end

% Add the history of constraints - only if it is not SORA that is used...
if ~strcmpi(Options.Method,'sora')
    % For cmaes based algorithm, make sure to remove the constraints saved
    % while searching for an initial feasible point
    switch lower(Options.Optim.Method)
        case 'ccmaes'
            Lcons = size(current_analysis.Internal.Runtime.RecordedConstraints,1) ;
            Lcost = size(results.History.Score,1) ;
            if Lcons > Lcost
                current_analysis.Internal.Runtime.RecordedConstraints(1:Lcons-Lcost,:) = [] ;
            end
        case 'hccmaes'
            % .GlobalRC is the recorded constraint from the global part of
            % the algorithm, herein CMA-ES
            Lcons = size(current_analysis.Internal.Runtime.GlobalRC,1) ;
            Lcost = size(results.History.GlobalOptim.Score,1) ;
            if Lcons > Lcost
                current_analysis.Internal.Runtime.RecordedConstraints(1:Lcons-Lcost,:) = [] ;
            end
    end
    results.History.Constraints = current_analysis.Internal.Runtime.RecordedConstraints ;
end
% Rename the funccount be funccount for SQP and IP
if isfield(results.output,'funcCount')
    results.output.funccount = results.output.funcCount ;
    results.output = rmfield(results.output, 'funcCount') ;
end

if current_analysis.Internal.Runtime.Metamodel
    % Add metamodel information if a surrogate was used
    results.Metamodel = current_analysis.Internal.Constraints.Model ;
    % Add the number of calls to the original model
    results.OriginalModelCalls = size(results.Metamodel.ExpDesign.X,1)  ;
end

% Add active learning results if they exist
if current_analysis.Internal.Runtime.AL
    results.ActiveMetamodel.LearningConv = current_analysis.Internal.Runtime.ActiveMeta.Conv ;
    results.ActiveMetamodel.ExpDesign.NAdded = current_analysis.Internal.Runtime.ActiveMeta.NAdded ;
    results.ActiveMetamodel.ExpDesign.X = current_analysis.Internal.Runtime.ActiveMeta.X ;
    results.ActiveMetamodel.ExpDesign.Y = current_analysis.Internal.Runtime.ActiveMeta.Y ;
end
end
