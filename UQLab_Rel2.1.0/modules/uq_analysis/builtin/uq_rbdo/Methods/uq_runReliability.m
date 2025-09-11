function results = uq_runReliability(d, current_analysis)

Options = current_analysis.Internal ;

ReliabOpts.Type = 'Reliability' ;
if isfield(Options,'LimitState')
    ReliabOpts.LimitState = Options.LimitState ;
end
ReliabOpts.Display = 0 ;
%% Create input object
M_d = Options.Runtime.M_d ;
M_z = Options.Runtime.M_z ;
switch lower( Options.Reliability.Method )
    case {'mcs','mc','monte carlo','qmc'}
        % do nothing - No input object is needed as there won't be any
        % reliability analysis using UQLab reliability module
    otherwise
        % Create an input object as
        for ii = 1: M_d
            IOpts.Marginals(ii).Type = Options.Input.DesVar(ii).Type ;
            % Get standard deviation if not explicitely given by the user
            if strcmp(Options.Input.DesVar(ii).Runtime.DispersionMeasure,'Std')
                % Case 1: Std has been given
                Std = Options.Input.DesVar(ii).Std ;
            else
                % Case 2: a coefficient of variation has been given
                Std = Options.Input.DesVar(ii).CoV .*abs(d(ii)) ;
            end
            % Moments are given to the margianls: mean and standard deviation
            IOpts.Marginals(ii).Moments = [d(ii) Std] ;
        end
        
       % Build an input object for the design variables
       DesInput = uq_createInput(IOpts,'-private') ;
        
        % Environmental variables
        if M_z > 0
            % Merge the design and environmental variables input objects
            ReliabOpts.Input = uq_mergeInputs(DesInput,Options.Input.EnvVar) ;
        else
            % There are only design variables, so the actual input object
            % is that of the design variables
            ReliabOpts.Input = DesInput ;
        end
        
end

%% Start reliability
switch lower( Options.Reliability.Method )
    case {'mcs','mc','monte carlo'}
        
        LocalAnalysis.Results = uq_evalPfMC(d, current_analysis) ;
        current_analysis.Internal.Runtime.XC = current_analysis.Internal.History.X ;
        
    case{'form'}
        OptionsNames = [fieldnames(ReliabOpts); fieldnames(Options.Reliability)];
        ReliabOpts = cell2struct([struct2cell(ReliabOpts); struct2cell(Options.Reliability)], OptionsNames, 1);
        ReliabOpts.Model = Options.Constraints.Model ;
        
        if Options.Optim.CommonRandomNumbers == 1
            % Save current status of rng
            s = rng ;
            % Set a seed
            rng(Options.Runtime.Seed,'twister') ;
        end
        
        LocalAnalysis = uq_createAnalysis(ReliabOpts, '-private') ;
        if Options.Optim.CommonRandomNumbers == 1
            % Restore previous status of rng
            rng(s) ;
        end
    case{'sorm'}
        OptionsNames = [fieldnames(ReliabOpts); fieldnames(Options.Reliability)];
        ReliabOpts = cell2struct([struct2cell(ReliabOpts); struct2cell(Options.Reliability)], OptionsNames, 1) ;
        ReliabOpts.Model = Options.Constraints.Model ;
        
        if Options.Optim.CommonRandomNumbers == 1
            % Save current status of rng
            s = rng ;
            % Set a seed
            rng(Options.Runtime.Seed,'twister') ;
        end
        LocalAnalysis = uq_createAnalysis(ReliabOpts, '-private') ;
        if Options.Optim.CommonRandomNumbers == 1
            % Restore previous status of rng
            rng(s) ;
        end
    case {'is'}
        OptionsNames = [fieldnames(ReliabOpts); fieldnames(Options.Reliability)];
        ReliabOpts = cell2struct([struct2cell(ReliabOpts); struct2cell(Options.Reliability)], OptionsNames, 1);
        ReliabOpts.Model = Options.Constraints.Model ;
        
        if Options.Optim.CommonRandomNumbers == 1
            % Save current status of rng
            s = rng ;
            % Set a seed
            rng(Options.Runtime.Seed,'twister') ;
        end
        LocalAnalysis = uq_createAnalysis(ReliabOpts, '-private') ;
        if Options.Optim.CommonRandomNumbers == 1
            % Restore previous status of rng
            rng(s) ;
        end
        
        current_analysis.Internal.Runtime.XC = LocalAnalysis.Results.History.X ;
        
    case {'subset'}
        OptionsNames = [fieldnames(ReliabOpts); fieldnames(Options.Reliability)];
        ReliabOpts = cell2struct([struct2cell(ReliabOpts); struct2cell(Options.Reliability)], OptionsNames, 1);
        ReliabOpts.Model = Options.Constraints.Model ;
        
        if Options.Optim.CommonRandomNumbers == 1
            % Save current status of rng
            s = rng ;
            % Set a seed
            rng(Options.Runtime.Seed,'twister') ;
        end
        
        % Run the reliability analysis
        LocalAnalysis = uq_createAnalysis(ReliabOpts, '-private') ;
        
        if Options.Optim.CommonRandomNumbers == 1
            % Restore previous status of rng
            rng(s) ;
        end
        temp = LocalAnalysis.Results.History.X ;
        current_analysis.Internal.Runtime.XC = vertcat(temp{:}) ;
        
    case {'qmc'}
        
        LocalAnalysis.Results = uq_evalQuantile(d, current_analysis) ;
        current_analysis.Internal.Runtime.XC = current_analysis.Internal.History.X ;
        
    case {'inverseform','iform'}
        OptionsNames = [fieldnames(ReliabOpts); fieldnames(Options.Reliability)];
        ReliabOpts = cell2struct([struct2cell(ReliabOpts); struct2cell(Options.Reliability)], OptionsNames, 1);
        ReliabOpts.invFORM.TargetBetaHL = current_analysis.Internal.TargetBeta ;
        ReliabOpts.Model = Options.Constraints.Model ;
        
        if Options.Optim.CommonRandomNumbers == 1
            % Save current status of rng
            s = rng ;
            % Set a seed
            rng(Options.Runtime.Seed,'twister') ;
        end
        LocalAnalysis = uq_createAnalysis(ReliabOpts, '-private') ;
        if Options.Optim.CommonRandomNumbers == 1
            % Restore previous status of rng
            rng(s) ;
        end
        
end
current_analysis.Internal.Runtime.ModelEvaluations = ...
    current_analysis.Internal.Runtime.ModelEvaluations + LocalAnalysis.Results.ModelEvaluations ;
results = LocalAnalysis ;
end

