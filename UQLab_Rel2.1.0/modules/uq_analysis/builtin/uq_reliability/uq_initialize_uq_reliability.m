function success = uq_initialize_uq_reliability(current_analysis)
% success = UQ_INITIALIZE_UQ_RELIABILITY(current_analysis):
%     initializes the structural reliability analyses defined in 
%     CURRENT_ANALYSIS. All initializations are done in this file.
% 
% See also: UQ_RELIABILITY

success = 0;


%%
% User options
Options = current_analysis.Options; 

% Actual options that the module will use
Internal = current_analysis.Internal; 

%% Check if the user has provided a Model and / or an Input
[opt, Options] = uq_process_option(Options, 'Model', uq_getModel, 'uq_model');
Internal.Model = opt.Value;

[opt, Options] = uq_process_option(Options, 'Input', uq_getInput, 'uq_input');
Internal.Input = opt.Value;

%% Set the Method:
% Depending on the method, some parts of the initialization script are
% needed or not:
InitSimulation = false;
InitFORM = false;
InitGradient = false;
InitIS = false;
InitSubsetSim = false;
InitAKMCS = false;
InitInvFORM = false ;
InitALR = false;
InitSSER = false;
InitLS = false;
InitBLS = false;

%% Reset the limitState count
uq_evalLimitState('reset');

%% Set the method specify defaults
%process the method
[Method, Options] = uq_process_option(Options, 'Method', 'mc', 'char');

if Method.Missing || Method.Invalid
    error('\nAn analysis method should be provided.\n');
else
    % Map the multiple methods description to a fixed set:
    % mc, is, form, sorm
    switch lower(Method.Value)
        case {'mc','mcs','montecarlo', 'monte carlo'}
            Internal.Method = 'mc';
            % Needs to initialize the simulation options:
            InitSimulation = true;
            DEFAULTSaveEvaluations = 1;
            DEFAULTBatchSize = 1e4;
            
        case {'importancesampling','is','importance sampling'}
            Internal.Method = 'is';
            % Needs to initialize the simulation options, FORM and the
            % gradient:
            InitSimulation = true;
            InitFORM = true;
            InitGradient = true;
            InitIS = true;
            DEFAULTSaveEvaluations = 1;
            DEFAULTBatchSize = 1e2;
            
        case 'form'
            [opt, Options] = uq_process_option(Options, 'NoSORM');
            if opt.Disabled || opt.Missing || opt.Invalid
                Internal.NoSORM = true;
            else
                Internal.NoSORM = opt.Value;
            end
            
            % Decide whether to change to SORM or not:
            if Internal.NoSORM
                Internal.Method = 'form';
            else
                Internal.Method = 'sorm';
            end
            % Needs to initialize FORM and the gradient:
            InitFORM = true;
            InitGradient = true;
            DEFAULTSaveEvaluations = 1;
            
        case 'sorm'
            Internal.Method = 'sorm';
            % Needs to initialize FORM and the gradient:
            InitFORM = true;
            InitGradient = true;
            DEFAULTSaveEvaluations = 1;
            
        case 'subset'
            % Needs to initialize simulation options and subset simulation
            % options
            Internal.Method = 'subset';
            InitSimulation = true;
            InitSubsetSim = true;
            DEFAULTSaveEvaluations = 1;
            DEFAULTBatchSize = 1e3;
            
        case 'akmcs'
            % Needs to initialize simulation options and ak-mcs options
            Internal.Method = 'akmcs';
            InitSimulation = true;
            InitAKMCS = true;
            DEFAULTSaveEvaluations = 1;
            DEFAULTBatchSize = 1e4;
            DEFAULTNugget = 1e-10; 
        case 'apckmcs'
            % Needs to initialize simulation options and ak-mcs options
            Internal.Method = 'akmcs';
            Options.AKMCS.MetaModel = 'PCK';
            InitSimulation = true;
            InitAKMCS = true;
            DEFAULTSaveEvaluations = 1;
            DEFAULTBatchSize = 1e4;
            DEFAULTNugget = 1e-10; 
            
        case { 'inverseform','iform' }
            [opt, Options] = uq_process_option(Options, 'NoSORM');
            if opt.Disabled || opt.Missing || opt.Invalid
                Internal.NoSORM = true;
            else
                Internal.NoSORM = opt.Value;
            end
            
            % Decide whether to change to SORM or not:
            if Internal.NoSORM
                Internal.Method = 'inverseform';
            else
                Internal.Method = 'sorm';
            end
            % Needs to initialize FORM and the gradient:
            InitFORM = true;
            InitGradient = true;
            InitInvFORM = true ;
            DEFAULTSaveEvaluations = 1;
            
        case {'activelearning','alr'}
            % Needs to initialize simulation options and ak-mcs options
            Internal.Method = 'alr';
            InitALR = true ;
            % Set the other initialization according to the type of
            % reliability method chosen
            if ~isfield(Options,'ALR') || ~isfield(Options.ALR,'Reliability')
                % No reliability algorithm set by the user - default is
                % subset simulation
                % Needs to initialize simulation options and subset simulation
                % options
                InitSimulation = true;
                InitSubsetSim = true;
                DEFAULTSaveEvaluations = 1;
                DEFAULTBatchSize = 1e5 ;
                DEFAULTMaxSampleSize = 1e7 ;
            elseif isfield(Options.ALR,'Reliability') && ...
                    ~isempty(Options.ALR.Reliability)
                switch lower(Options.ALR.Reliability)
                    case {'mc','mcs','montecarlo', 'monte carlo'}
                        % Needs to initialize the simulation options:
                        InitSimulation = true;
                        DEFAULTSaveEvaluations = 1;
                        DEFAULTBatchSize = 1e6;
                        DEFAULTMaxSampleSize = 1e7 ;
                    case {'importancesampling','is','importance sampling'}
                        % Needs to initialize the simulation options, FORM and the
                        % gradient:
                        InitSimulation = true;
                        InitFORM = true;
                        InitGradient = true;
                        InitIS = true;
                        DEFAULTSaveEvaluations = 1;
                        DEFAULTBatchSize = 1e4;
                        DEFAULTMaxSampleSize = 1e5 ;

                    case 'form'
                        [opt, Options] = uq_process_option(Options, 'NoSORM');
                        if opt.Disabled || opt.Missing || opt.Invalid
                            Internal.NoSORM = true;
                        else
                            Internal.NoSORM = opt.Value;
                        end
                        
                        % Needs to initialize FORM and the gradient:
                        InitFORM = true;
                        InitGradient = true;
                        DEFAULTSaveEvaluations = 1;
                        
                    case 'sorm'
                        % Needs to initialize FORM and the gradient:
                        InitFORM = true;
                        InitGradient = true;
                        DEFAULTSaveEvaluations = 1;
                        
                    case 'subset'
                        % Needs to initialize simulation options and subset simulation
                        % options
                        InitSimulation = true;
                        InitSubsetSim = true;
                        DEFAULTSaveEvaluations = 1;
                        DEFAULTBatchSize = 1e5;
                        DEFAULTMaxSampleSize = 2e6 ;

                    case {'ls', 'linesampling'}
                        % Needs to initialize simulation, FORM and gradient
                        InitSimulation = true;
                        InitFORM = true;
                        InitGradient = true;
                        InitLS = true;
                        DEFAULTSaveEvaluations = 1;
                        DEFAULTBatchSize = [];
                        DEFAULTMaxSampleSize = [];

                        
                    otherwise 
                        error('\nThe provided reliability method within ALR "%s" is not correct.', ...
                Options.ALR.Reliability);   

                end
            else
                % By default, subset simulation is used in active learning
                InitSimulation = true;
                InitSubsetSim = true;
                DEFAULTSaveEvaluations = 1;
                DEFAULTBatchSize = 1e5;
                DEFAULTMaxSampleSize = 2e6 ;

            end
          
        case {'sser'}
            % Needs to initialize simulation options and ak-mcs options
            Internal.Method = 'sser';
            InitSSER = true ;
            
            % SSLE - Default options
            % Partitioning
            DEFAULTSSER.Partitioning = @(obj, subIdx) uq_SSE_partitioning_misclass(obj, subIdx);
            
            % Selection
            DEFAULTSSER.Refine.Score = @(obj, subIdx) uq_SSE_refineScore_Pf(obj, subIdx);
            
            % Post expansion action
            DEFAULTSSER.PostExpansion = @(obj, subIdx) uq_SSE_postExpansion_computePf(obj, subIdx);
           
            % Stopping criterion
            DEFAULTSSER.Stopping.Criterion = @(obj) uq_SSE_stopping_Beta(obj);

            % ExpDesign
            DEFAULTSSER.ExpDesign.Enrichment = @(obj, currBounds, nEnrich) uq_SSE_enrichment_LSS(obj, currBounds, nEnrich);
            DEFAULTSSER.ExpDesign.Sampling = 'sequential';
            DEFAULTSSER.ExpDesign.NEnrich = 10;
            DEFAULTSSER.ExpDesign.NSamples = 1e5;

            % ExpOptions
            DEFAULTSSER.ExpOptions.Bootstrap.Replications = 200;
            
            % Save evaluations
            DEFAULTSaveEvaluations = 1;

        case {'ls', 'linesampling'}
            Internal.Method = 'ls';
            InitSimulation = true;
            InitFORM = true;
            InitGradient = true;
            InitLS = true;
            DEFAULTSaveEvaluations = 1;
            DEFAULTBatchSize = 1e2;
            DEFAULTMaxSampleSize = 1e3;

        case {'bls', 'bayesianlinesampling'}
            Internal.Method = 'bls';
            InitSimulation = true;
            InitFORM = true;
            InitGradient = true;
            InitLS = true;
            InitBLS = true;
            DEFAULTSaveEvaluations = 1;
            DEFAULTBatchSize = 1e4;
            DEFAULTNugget = 1e-10;

        otherwise
            error('\nThe provided analysis method "%s" is not correct.', ...
                Method.Value);
            
    end
end





%% COMMON OPTIONS:

% Process the limit state function (as struct):
DefLS.Threshold = 0;
DefLS.CompOp = '<=';

[opt, Options] = uq_process_option(Options, 'LimitState', DefLS, 'struct');
LimitState = opt.Value;

% Process the fields of LimitState:
% - Threshold:
[opt, LimitState] = uq_process_option(LimitState, 'Threshold', 0, 'double');
LimitState.Threshold = opt.Value;

% - Comparison option (CompOp):
[opt, LimitState] = uq_process_option(LimitState, 'CompOp', '<=', 'char');
switch opt.Value
    case {'<', '<=', 'leq', '>', '>=', 'geq'}
        LimitState.CompOp = opt.Value;
    otherwise
        LimitState.CompOp = opt.Default;
end


% LimitState finished processing now:
Internal.LimitState = LimitState;

% Save the evaluations (when possible)
[opt, Options] = uq_process_option(Options, 'SaveEvaluations', DEFAULTSaveEvaluations, {'logical', 'double', 'char'});
switch opt.Value
    case {0, false, 'no','none','disabled'}
        Internal.SaveEvaluations = 0;
    otherwise
        Internal.SaveEvaluations = opt.Default;
end

% Transient analysis (for now, only FORM treats this differently)
[opt, Options] = uq_process_option(Options, 'Transient', false, {'logical', 'double', 'char'});
switch opt.Value
    case {1, true, 'yes','all','enabled'}
        Internal.Transient = 1;
    otherwise
        Internal.Transient = opt.Default;
end

% Initialize the display:
[Options, Internal] = uq_initialize_display(Options, Internal);

%%%UQHPCSTART%%%
[Options, Internal] = uq_initialize_HPC(Options, Internal);
% Set the default granularity options:
% By default, only simulation methods are distributed.
HPCOptions = Internal.HPC;

if HPCOptions.Enabled
    
    [opt, HPCOptions] = uq_process_option(HPCOptions, 'FORM', false, {'double', 'logical'});
    Internal.HPC.FORM = opt.Value;
    
    [opt, HPCOptions] = uq_process_option(HPCOptions, 'SORM', false, {'double', 'logical'});
    Internal.HPC.SORM = opt.Value;
    
    [opt, HPCOptions] = uq_process_option(HPCOptions, 'MC', true, {'double', 'logical'});
    Internal.HPC.MC = opt.Value;
    
    [opt, HPCOptions] = uq_process_option(HPCOptions, 'IS', true, {'double', 'logical'});
    Internal.HPC.IS = opt.Value;
    
    % Remove the option thas was processed before:
    HPCOptions = rmfield(HPCOptions, 'Enabled');
    
    % Check if there was something else provided:
    uq_options_remainder(HPCOptions, ...
        'the HPC configuration of the analysis module');
    
else
    Internal.HPC.FORM = false;
    Internal.HPC.SORM = false;
    Internal.HPC.MC = false;
    Internal.HPC.IS = false;
end
%%%UQHPCEND%%%

OptionsFields = fieldnames(Options);

%% ASYNCHRONOUS OPTIONS 
% Process them (as struct):
DefAS.Enable = false;
DefAS.InitED = false ;
DefAS.Save = true ;
DefAS.Path = '';
DefAS.Snapshot = '';
[opt, Options] = uq_process_option(Options, 'Async', DefAS, 'struct');
Async = opt.Value;

% Process the fields of Async:
% - Enabled/Disabled:
[opt, Async] = uq_process_option(Async, 'Enable', DefAS.Enable, {'logical','integer'});
Async.Enable = opt.Value;

% - Initial ED:
[opt, Async] = uq_process_option(Async, 'InitED', DefAS.InitED, {'logical','integer'});
Async.InitED = opt.Value;

% - To Save or not:
[opt, Async] = uq_process_option(Async, 'Save', DefAS.Save, {'logical','integer'});
Async.Save = opt.Value;

% - Path to the snapshot file:
[opt, Async] = uq_process_option(Async, 'Path', DefAS.Path, 'char');
Async.Path = opt.Value;

% - Name of the snapshot file
[opt, Async] = uq_process_option(Async, 'Snapshot', DefAS.Snapshot, 'char');
% Create a default file name if none is given
TimeStamp = uq_createUniqueID() ;
if isempty(opt.Value)
    opt.Value = ['Reliability_Snapshot_',TimeStamp, '.mat'] ;
end
Async.Snapshot = opt.Value;

% Async finished processing now:
Internal.Async = Async ;
Internal.Runtime.Async = struct ; % Initialize a Runtime field for async   
%% SIMULATION METHODS (MC, IS, subset sim., and AKMCS)

if InitSimulation
    
    SimOpts = struct;
    
    [opt, Options] = uq_process_option(Options, 'Simulation', SimOpts, 'struct');
    SimOpts = opt.Value;
    
    % Set the batch size to evaluate at a time
    [opt, SimOpts] = uq_process_option(SimOpts, 'BatchSize', DEFAULTBatchSize, 'double');
    Internal.Simulation.BatchSize = opt.Value;
    
	BatchSizeisUserGiven = ~opt.Missing ;

    % Set the sampling method
    [opt, SimOpts] = uq_process_option(SimOpts, 'Sampling', 'mc', 'char');
    Internal.Simulation.Sampling = opt.Value;
    
    % Set the target coefficient of variation
    [opt, SimOpts] = uq_process_option(SimOpts, 'TargetCoV', [], 'double');
    Internal.Simulation.TargetCoV = opt.Value;
    
    % If there is a target CoV, we can set max. runs to Inf by default,
    % otherwise, we limit it to 10^5:
    if isempty(opt.Value)
        if strcmp(current_analysis.Options.Method, 'IS')
            MRdefault = 1e3;
        elseif strcmp(current_analysis.Options.Method, 'ALR') || strcmp(current_analysis.Options.Method, 'LS')
            % Max sample size is defined according to the simulation method used withtin ALR
            MRdefault = DEFAULTMaxSampleSize ; 
        else
            MRdefault = 1e5;
        end
    else
        MRdefault = inf;
    end
    
    % Maximum number of function evaluations
    [opt, SimOpts] = uq_process_option(SimOpts, 'MaxSampleSize', MRdefault, 'double');
    Internal.Simulation.MaxSampleSize = opt.Value;
    if opt.Invalid || opt.Missing || opt.Disabled
        % Do not print the warning for active learning
        if ~any(strcmpi(Internal.Method,{'activelearning','alr','ls'}))
        fprintf('Warning: Maximum number of model evaluations was limited to 10^5\n');
        end
    end
    
    % Check if the user has given both .MaxSampleSize and .BatchSize
    if BatchSizeisUserGiven && ~opt.Missing
        % Now if MaxSampleSize > BatchSize, print a warning and update with
        % BatchSize = MaxSampleSize
        if Internal.Simulation.BatchSize > Internal.Simulation.MaxSampleSize
            Internal.Simulation.BatchSize = Internal.Simulation.MaxSampleSize ;
            warning('The given .MaxSampleSize was larger than the given .Batchsize! The .BatchSize has been reduced to .MaxSampleSize');
        end
    end
        
    
    % Confidence level Alpha:
    [opt, SimOpts] = uq_process_option(SimOpts, 'Alpha', 0.05, 'double');
    Internal.Simulation.Alpha = opt.Value;
    
    uq_options_remainder(SimOpts, 'the simulation methods');
    
end

%% Options for the FORM algorithm (and therefore also for SORM and IS)
if InitFORM
    
    FORMOpts = struct;
    [opt, Options] = uq_process_option(Options, 'FORM', FORMOpts, 'struct');
    FORMOpts = opt.Value;
    
    
    % FORM algorithm Specific Options
    [opt, FORMOpts] = uq_process_option(FORMOpts, 'StartingPoint', [], 'double');
    Internal.FORM.StartingPoint = opt.Value;

    % Solution algorithm:
    [opt, FORMOpts] = uq_process_option(FORMOpts, 'Algorithm', 'iHLRF', 'char');
    
    % Only two specific strings are accepted:
    if ~any(strcmpi(opt.Value, {'hlrf', 'ihlrf'}))
        Internal.FORM.Algorithm = opt.Default;
        opt.Invalid = true;
        % Show a warning if the user provided an invalid string:
        fprintf('\nWarning: The provided algorithm "%s" was not recognized. Switching to "%s".\n', opt.Value, opt.Default);
    else
        Internal.FORM.Algorithm = opt.Value;
    end
    
    
    % Stop criteria on U: (Stagnation)
    [opt, FORMOpts] = uq_process_option(FORMOpts, 'StopU', 1e-4, 'double');
    Internal.FORM.StopU = opt.Value;
    
    
    % Stop criteria on G: (Convergence)
    [opt, FORMOpts] = uq_process_option(FORMOpts, 'StopG', 1e-6, 'double');
    Internal.FORM.StopG = opt.Value;
    
    
    % Maximum number of iterations:
    if ~InitLS
        [opt, FORMOpts] = uq_process_option(FORMOpts, 'MaxIterations', 1e2, 'double');
    else
        [opt, FORMOpts] = uq_process_option(FORMOpts, 'MaxIterations', 2, 'double');
    end
    Internal.FORM.MaxIterations = opt.Value;
    
    
end

if InitInvFORM
    invFORMOpts = struct;
    
    [opt, Options] = uq_process_option(Options, 'invFORM', invFORMOpts, 'struct');
    invFORMOpts = opt.Value;

        % inverse FORM algorithm Specific Options
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'StartingPoint', [], 'double');
    Internal.invFORM.StartingPoint = opt.Value;
    
    % Solution algorithm:
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'Algorithm', 'AMV', 'char');
    % Only two specific strings are accepted:
    if ~any(strcmpi(opt.Value, {'amv', 'cmv', 'hmv','sqp'}))
        Internal.invFORM.Algorithm = opt.Default;
        opt.Invalid = true;
        % Show a warning if the user provided an invalid string:
        fprintf('\nWarning: The provided algorithm "%s" was not recognized. Switching to "%s".\n', opt.Value, opt.Default);
    else
        Internal.invFORM.Algorithm = opt.Value;
    end

    % Target reliability index
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'TargetBetaHL', 1.6449, 'double');
    Internal.invFORM.TargetBetaHL = opt.Value;
    
    % Stop criteria on U: (Stagnation)
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'StopU', 1e-3, 'double');
    Internal.invFORM.StopU = opt.Value;
    
    % Stop criteria on U: (Stagnation)
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'StopG', 1e-3, 'double');
    Internal.invFORM.StopG = opt.Value;
 
    % Maximum number of iterations:
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'MaxIterations', 1e2, 'double');
    Internal.invFORM.MaxIterations = opt.Value;
    
end
%% Differentiation options (also for FORM, SORM, IS):
if InitGradient
    % default to standardized calculation of the gradient
    if isfield(Options, 'Gradient')
        GradOpts = Options.Gradient;
        if ~isfield(GradOpts, 'Step') || isempty(GradOpts.Step)
            Options.Gradient.Step = 'Standardized';
        end
    else
        Options.Gradient.Step = 'Standardized';
    end
    [Options, Internal] = uq_initialize_gradient(Options, Internal, true);
end

%% Importance sampling (IS) special options:
if InitIS
    
    % See if the option was provided at all:
    ISOpts.FORM = [];
    ISOpts.Instrumental = [];
    [opt, Options] = uq_process_option(Options, 'IS', ISOpts, 'struct');
    ISOpts = opt.Value;
    
    % Process the field FORM:
    [opt, ISOpts] = uq_process_option(ISOpts, 'FORM', [], {'struct', 'uq_analysis', 'double'});
    Internal.IS.FORM = opt.Value;
    % In case the provided option is a double other than []
    if isnumeric(opt.Value) && ~isempty(opt.Value)
        fprintf('\nWarning: Invalid option for IS.FORM, it will be ignored.\n');
        opt.Value = [];
    end
    
    % If the user gave an analysis, check if it is solved and retrieve the
    % results:
    if isa(opt.Value, 'uq_analysis')
        if isprop(opt.Value, 'Results')
            opt.Value = opt.Value.Results(end);
            Internal.IS.FORM = opt.Value;
        else
            fprintf('\nWarning: The FORM results given to importance sampling are not valid.\n');
            fprintf('FORM will be executed to find the design point.\n');
            Internal.IS.FORM = [];
            opt.Value = [];
        end
    end


    % Check that if it was given by the user, it has the required fields,
    % otherwise run FORM later:
    if isstruct(opt.Value)
        if ~isfield(opt.Value, 'Ustar') % || ~isfield(opt.Value, 'BetaHL')
            fprintf('\nWarning: The FORM results given to importance sampling are not valid.\n');
            fprintf('FORM will be executed to find the design point.\n');
            Internal.IS.FORM = [];
        end
    end
    
    % Process the instrumental density, field SOpts.IS.Instrumental
    [opt, ISOpts] = uq_process_option(ISOpts, 'Instrumental', [], {'struct', 'uq_input', 'double'});
    
    if isnumeric(opt.Value) && ~isempty(opt.Value) % In case the provided option is a double other than []
        fprintf('\nWarning: Invalid option for IS.Instrumental, it will be ignored.\n');
        Internal.IS.Instrumental = [];
        
    elseif length(opt.Value)==1 % There is only one instrumental provided
        Internal.IS.Instrumental = opt.Value;
        if isstruct(opt.Value)
            try
                InstrumentalInput = uq_createInput(opt.Value, '-private');
                Internal.IS.Instrumental = InstrumentalInput;
            catch ME
                fprintf('\nWarning: The struct given in IS.Instrumental does not define a proper instrumental density');
                fprintf('\nInput could not be initialized with error:\n%s\n', ME.message);
                fprintf('\nFORM will be executed to find a proper instrumental density\n');
                Internal.IS.Instrumental = [];
            end
        elseif isa(opt.Value,'uq_input')
            Internal.IS.Instrumental = opt.Value;
        else
            fprintf('\nWarning: Invalid option for IS.Instrumental, it will be ignored.\n');
            Internal.IS.Instrumental = [];
        end
        
    elseif isstruct(opt.Value) || isa(opt.Value,'uq_input') % struct contains multiple InstrInputs or InstrOpts
        
            for uu = 1:length(opt.Value) % turn all Opts into Inputs
                if isa(opt.Value(uu),'uq_input') % already in desired form
                    Internal.IS.Instrumental(uu) = opt.Value(uu);
                elseif isstruct(opt.Value(uu)) % turn Opts into Input
                    try
                        Internal.IS.Instrumental(uu) = uq_createInput(opt.Value(uu), '-private');                        
                    catch ME
                        fprintf('\nWarning: The struct given in IS.Instrumental does not define a proper instrumental density');
                        fprintf('\nInput could not be initialized with error:\n%s\n', ME.message);
                        fprintf('\nFORM will be executed to find a proper instrumental density\n');
                        Internal.IS.Instrumental = [];
                        break
                    end
                else % structure contains nothing useful
                    fprintf('\nWarning: Invalid option for IS.Instrumental, it will be ignored.\n');
                    Internal.IS.Instrumental = [];
                    break
                end
            end
    elseif isempty(opt.Value)
        % No Instrumental distribution provided, do nothing
        Internal.IS.Instrumental = [];
    else
        fprintf('\nWarning: The struct given in IS.Instrumental does not define a proper instrumental density');
        fprintf('\nInput could not be initialized');
        fprintf('\nFORM will be executed to find a proper instrumental density\n');
        Internal.IS.Instrumental = [];
    end
        
    % Check if both were given, and in that case prefer the instrumental
    % density:
    if ~isempty(Internal.IS.Instrumental) && ~isempty(Internal.IS.FORM)
        fprintf('\nWarning: Importance sampling cannot accept both FORM results and an instrumental density\n');
        fprintf('FORM results will be ignored\n');
        Internal.IS.FORM = [];
    end
    % Check if there were more options given:
    uq_process_option(ISOpts, ' importance sampling.');
end

%% Initialize subset simulation options:
% Note that the default values are chosen in correpsondance to: 
%   Au and Beck (2001), Estimation of small failure probabilities in high
%   dimensions by subset simulation, Prob. Eng. Mech. 16(4), p 263-277.
if InitSubsetSim
    
    SSOpts = struct;
    
    [opt, Options] = uq_process_option(Options, 'Subset', SSOpts, 'struct');
    SSOpts = opt.Value;
    
    %set the intermediate failure probability p0
    if ~InitALR
    [opt, SSOpts] = uq_process_option(SSOpts, 'p0', 0.1, 'double');
    Internal.Subset.p0 = opt.Value;
    else
        % use a larger p0 as default if ALR is selected
        [opt, SSOpts] = uq_process_option(SSOpts, 'p0', 0.15, 'double');
        Internal.Subset.p0 = opt.Value;
    end
    %set the maximum number of subsets
    
    MaxSubsets = floor(Internal.Simulation.MaxSampleSize / Internal.Simulation.BatchSize / (1-Internal.Subset.p0));
    [opt, SSOpts] = uq_process_option(SSOpts, 'MaxSubsets', MaxSubsets,'double');
    Internal.Subset.MaxSubsets = min(opt.Value, MaxSubsets);
    
    %set the MH acceptance criterion
    [opt, SSOpts] = uq_process_option(SSOpts, 'Componentwise', 1, 'double');
    Internal.Subset.Componentwise = opt.Value;
    
    %set the random walker of the Markov Chain
    RWOpts = struct;
    [opt, SSOpts] = uq_process_option(SSOpts, 'Proposal', RWOpts, 'struct');
    RWOpts = opt.Value;
    
    %set the proposal distribution of the random walker
    [opt, RWOpts] = uq_process_option(RWOpts, 'Type', 'uniform', 'char');
    Internal.Subset.Proposal.Type = opt.Value;
    
    % set the proposal distribution of the random walker
    [opt, RWOpts] = uq_process_option(RWOpts, 'Parameters', 1, 'double');
    Internal.Subset.Proposal.Parameters = opt.Value;
    
end

%% Initialize AK-MCS options
if InitAKMCS
    AKOpts = struct;
    
    [opt, Options] = uq_process_option(Options, 'AKMCS', AKOpts, 'struct');
    AKOpts = opt.Value;
    
    %check the initial experimental design
    if ~isfield(AKOpts, 'IExpDesign')
        AKOpts.IExpDesign.N = max(10, 2*length(Internal.Input.Marginals));
        AKOpts.IExpDesign.Sampling = 'mc';
    end
    if ~isfield(AKOpts.IExpDesign, 'X')
        IEDefault.N = max(10, 2*length(Internal.Input.Marginals));
        IEDefault.Sampling = 'mc';
        [opt, AKOpts] = uq_process_option(AKOpts,'IExpDesign',IEDefault,'struct');
        Internal.AKMCS.IExpDesign = opt.Value;
    else 
        if isfield(AKOpts.IExpDesign, 'X') && isfield(AKOpts.IExpDesign, 'Y')
            error('Field .IExpDesign.Y detected: the initial experimental design must be specified using the fields .IExpDesign.X and .IExpDesign.G');
        end
        [opt, AKOpts] = uq_process_option(AKOpts,'IExpDesign',[],'struct');
        Internal.AKMCS.IExpDesign = opt.Value;
    end
    
    %check the meta-model type
    [opt, AKOpts] = uq_process_option(AKOpts, 'MetaModel', 'Kriging', 'char');
    MetaModel = opt.Value;
    
    %put the meta-model type name as a standardized on for consistencies
    switch lower(MetaModel)
        case 'kriging'
            MetaModel = 'Kriging';
        case 'pck'
            MetaModel = 'PCK';
    end
    Internal.AKMCS.MetaModel = MetaModel;
    
    %process the Kriging options if available
    [opt, AKOpts] = uq_process_option(AKOpts, MetaModel, [], 'struct');
    Internal.AKMCS.(MetaModel) = opt.Value;
    
    switch lower(MetaModel)
        case 'kriging'
            %check for the Nugget (in Kriging)
            if isfield(Internal.AKMCS.Kriging, 'Corr')
                if ~isfield(Internal.AKMCS.Kriging.Corr, 'Nugget')
                    Internal.AKMCS.Kriging.Corr.Nugget = DEFAULTNugget;
                end
            else
                Internal.AKMCS.Kriging.Corr.Nugget = DEFAULTNugget;
            end
            
        case 'pck'
            %check for the Nugget (in Kriging)
            if isfield(Internal.AKMCS.PCK,'Kriging')&& isfield(Internal.AKMCS.PCK.Kriging, 'Corr')
                if ~isfield(Internal.AKMCS.PCK.Kriging.Corr, 'Nugget')
                    Internal.AKMCS.PCK.Kriging.Corr.Nugget = DEFAULTNugget;
                end
            else
                Internal.AKMCS.PCK.Kriging.Corr.Nugget = DEFAULTNugget;
            end
            
    end
    %check whether there are Kriging options specified
    %-> done directly in uq_akmcs at the moment
    
    %check the learning function
    [opt, AKOpts] = uq_process_option(AKOpts, 'LearningFunction', 'U', 'char');
    Internal.AKMCS.LearningFunction = opt.Value;
    
    %check the number of total added samples
    [opt, AKOpts] = uq_process_option(AKOpts, 'MaxAddedED', 1000, 'double');
    Internal.AKMCS.MaxAddedSamplesTotal = opt.Value;
    
    %locking the number of samples in each batch
    Internal.AKMCS.MaxAddedSamplesInBatch = Internal.AKMCS.MaxAddedSamplesTotal;
    
    %check the convergence criterion
    [opt, AKOpts] = uq_process_option(AKOpts, 'Convergence', 'stopU', 'char');
    Internal.AKMCS.Convergence = opt.Value;
    
    %locking the BatchSize = MaxNumberOfSamples
    Internal.Simulation.BatchSize = Internal.Simulation.MaxSampleSize;

end

%% Initialize Active Learning options
if InitALR
    ALROpts = struct;
    
    [opt, Options] = uq_process_option(Options, 'ALR', ALROpts, 'struct');
    ALROpts = opt.Value;
    
    % Check the initial experimental design
    % Defaults: Size = max(10, 2M) - Sampling: LHS
    if ~isfield(ALROpts, 'IExpDesign')
        ALROpts.IExpDesign.N = max(10, 2*length(Internal.Input.Marginals));
        ALROpts.IExpDesign.Sampling = 'lhs';
    end
    if ~isfield(ALROpts.IExpDesign, 'X')
        IEDefault.N = max(10, 2*length(Internal.Input.Marginals));
        IEDefault.Sampling = 'lhs';
        [opt, ALROpts] = uq_process_option(ALROpts,'IExpDesign',IEDefault,'struct');
        Internal.ALR.IExpDesign = opt.Value;
    else 
        if isfield(ALROpts.IExpDesign, 'X') && isfield(ALROpts.IExpDesign, 'Y')
            error('Field .IExpDesign.Y detected: the initial experimental design must be specified using the fields .IExpDesign.X and .IExpDesign.G');
        end
        [opt, ALROpts] = uq_process_option(ALROpts,'IExpDesign',[],'struct');
        Internal.ALR.IExpDesign = opt.Value;
    end
    
    % Check the meta-model type
    [opt, ALROpts] = uq_process_option(ALROpts, 'Metamodel', 'PCK', 'char');
    MetaModel = opt.Value;
    
    % Put the meta-model type name as a standardized one for consistency
    switch lower(MetaModel)
        case 'kriging'
            MetaModel = 'Kriging';
        case {'pck', 'pc-kriging'}
            MetaModel = 'PCK';
        case 'svr'
            MetaModel = 'SVR' ;
        case 'pce'
            MetaModel = 'PCE' ;
        case 'lra'
            MetaModel = 'LRA' ;
    end
    Internal.ALR.MetaModel = MetaModel;
    
    %process the metamodel options if available
    [opt, ALROpts] = uq_process_option(ALROpts, MetaModel, [], 'struct');
    Internal.ALR.(MetaModel) = opt.Value;
    
    % Reliability mehod
    [opt, ALROpts] = uq_process_option(ALROpts, 'Reliability', 'Subset', 'char');
    Internal.ALR.Reliability = opt.Value ;
    
    % Defaults options for reliability
    % Simulation
   
    switch lower(Internal.ALR.MetaModel)
        case {'kriging','pck'}
            DEFAULTLF = 'U' ;
            DEFAULTCONV = 'StopBetaBound' ;
            % Specify reasonable optimization limits
            nonConstMarginals= Internal.Input.Marginals(Internal.Input.nonConst);
            DEFAULTOPTBOUNDS = NaN(2,length(Internal.Input.Marginals));
            FullRanges = diff(uq_all_invcdf(repmat([0.01; 0.99],1,length(nonConstMarginals)),nonConstMarginals));
            DEFAULTOPTBOUNDS(:,Internal.Input.nonConst,:) = [0.01; .99]*FullRanges;
        case 'pce'
            DEFAULTLF = 'FBR' ;
            DEFAULTCONV = 'StopBetaStab' ;
            DEFAULTBOOTREP = 200 ;
        case {'svr','lra'}
            DEFAULTLF = 'CMM' ;
            DEFAULTCONV = 'StopBetaStab' ;
        case 'svc'
            % not implemented yet
            error('SVC is currently not supported for active learning reliability') ;
    end

    
    % Add some specific default parameters of the metamodels 
    switch lower(MetaModel)
        case 'kriging'
            % check for the Nugget (in Kriging)
            if isfield(Internal.ALR.Kriging, 'Corr')
                if ~isfield(Internal.ALR.Kriging.Corr, 'Nugget')
                    Internal.ALR.Kriging.Corr.Nugget = 1e-10 ;
                end
            else
                Internal.ALR.Kriging.Corr.Nugget = 1e-10 ;
            end
            if ~isfield(Internal.ALR.Kriging,'EstimMethod')
                Internal.ALR.Kriging.EstimMethod = 'ML' ;
            end
            if ~isfield(Internal.ALR.Kriging,'Optim') || ~isfield(Internal.ALR.Kriging.Optim,'Bounds')

                Internal.ALR.Kriging.Optim.Bounds = DEFAULTOPTBOUNDS ;
            end


        case 'pck'
            % check for the Nugget (in Kriging)
            if isfield(Internal.ALR.PCK,'Kriging')&& isfield(Internal.ALR.PCK.Kriging, 'Corr')
                if ~isfield(Internal.ALR.PCK.Kriging.Corr, 'Nugget')
                    Internal.ALR.PCK.Kriging.Corr.Nugget = 1e-10 ;
                end
            else
                Internal.ALR.PCK.Kriging.Corr.Nugget = 1e-10 ;
            end
            
            if ~isfield(Internal.ALR.PCK.Kriging,'EstimMethod')
                Internal.ALR.PCK.Kriging.EstimMethod = 'ML' ;
            end
            % PCE part
            Internal.ALR.PCK.PCE.Degree = 1:3 ;
                        
            if isfield(Internal.ALR.PCK,'Kriging') 
                if ~isfield(Internal.ALR.PCK.Kriging,'Optim') || ~isfield(Internal.ALR.PCK.Kriging.Optim,'Bounds')
                    Internal.ALR.PCK.Kriging.Optim.Bounds = DEFAULTOPTBOUNDS ;
                end
            end

        case 'lra'
            % Check degree and add the degree if none is specified
            if ~isfield(Internal.ALR.LRA, 'Degree')
                Internal.ALR.LRA.Degree = 1:3 ;
            end
            if ~isfield(Internal.ALR.LRA, 'Rank')
                Internal.ALR.LRA.Rank = 1:3 ;
            end
      
    end
    
    %check the learning function
    [opt, ALROpts] = uq_process_option(ALROpts, 'LearningFunction', DEFAULTLF, 'char');
    Internal.ALR.LearningFunction = opt.Value;
    % Bootstrap replicates if any
    if strcmpi(Internal.ALR.LearningFunction, 'fbr')
        [opt, ALROpts] = uq_process_option(ALROpts, 'BootstrapRep', DEFAULTBOOTREP, 'double');
        Internal.ALR.BootstrapRep = opt.Value;
    end
    % Number of points per enrichment set
    [opt, ALROpts] = uq_process_option(ALROpts, 'NumOfPoints', 1, 'double');
    Internal.ALR.NumOfPoints = opt.Value;
    
    % check the convergence criterion
    [opt, ALROpts] = uq_process_option(ALROpts, 'Convergence', DEFAULTCONV, {'char','cell'});
    if ~iscell(opt.Value)
        opt.Value = {opt.Value} ;
    end
    Internal.ALR.Convergence = opt.Value;
    
    %Convergence threshold
    % Depends on the learning function
    DEFAULTCONVTHRES = zeros(1,length(Internal.ALR.Convergence)) ;
    for ii = 1:length(Internal.ALR.Convergence)
        switch lower(Internal.ALR.Convergence{ii})
            case 'stoplf'
                switch lower(Internal.ALR.LearningFunction)
                    case 'u'
                        DEFAULTCONVTHRES(ii) = -2;
                    case 'eff'
                        DEFAULTCONVTHRES(ii) = 1e-3 ;
                    case 'cmm'
                        DEFAULTCONVTHRES(ii) = 1e-2 ;
                    case 'fbr'
                        DEFAULTCONVTHRES(ii) = 1e-2 ;
                    otherwise
                        DEFAULTCONVTHRES(ii) = 1e-2 ;
                end
            case 'stopbetastab'
                DEFAULTCONVTHRES(ii) = 1e-2 ;
            case 'stoppfstab'
                DEFAULTCONVTHRES(ii) = 1e-2 ;
            case 'stopbetabound'
                DEFAULTCONVTHRES(ii) = 1e-2 ;
                
            case 'stoppfbound'
                DEFAULTCONVTHRES(ii) = 1e-2 ;
            otherwise
                DEFAULTCONVTHRES(ii) = 1e-2 ;
        end
    end
    [opt, ALROpts] = uq_process_option(ALROpts, 'ConvThres', DEFAULTCONVTHRES, 'double');
    Internal.ALR.ConvThres = opt.Value;
    
    if length(Internal.ALR.ConvThres) > 1 && ...
            length(Internal.ALR.Convergence) > 1 && ...
            length(Internal.ALR.ConvThres) ~= length(Internal.ALR.Convergence)
        error('Inconsistent size of the convergence threshold on number of convergence criteria') ;
    end
    if length(Internal.ALR.ConvThres) == 1 && ...
            length(Internal.ALR.Convergence) > 1
        Internal.ALR.ConvThres = ...
            Internal.ALR.ConvThres * ...
            ones(length(Internal.ALR.Convergence),1) ;
    end
    
    % Number of successive iterations of satisfying the convergence
    % criterion to actually exit
    [opt, ALROpts] = uq_process_option(ALROpts, 'ConvIter', 2, 'double');
    Internal.ALR.ConvIter = opt.Value;
    
    %check the number of total added samples
    [opt, ALROpts] = uq_process_option(ALROpts, 'MaxAddedED', 1000, 'double');
    Internal.ALR.MaxAddedED = opt.Value; 
    
    % Multi-output enrichment strategy
    [opt, ALROpts] = uq_process_option(ALROpts, 'MOStrategy', 'bestlf', 'char');
    if opt.Invalid || ~any(strcmpi(opt.Value, {'series','parallel','transient','simultaneous','independent','bestlf'}))
        warning('Unknown multi-output enrichment strategy. Using default value.');
        Internal.ALR.MOStrategy = 'bestlf' ;
    else
        Internal.ALR.MOStrategy = opt.Value;
    end
    
    % Common random numbers
    [opt, ALROpts] = uq_process_option(ALROpts, 'CRN', true, 'logical');
    Internal.ALR.CRN = opt.Value; 
    
    %  Maximum size of the candidate set
    [opt, ALROpts] = uq_process_option(ALROpts, 'MaxCandidateSize', 5e4, 'double');
    Internal.ALR.MaxCandidateSize = opt.Value; 
end

%% Initialize SSER options

if InitSSER
    SSEROpts = struct;
    
    % Process SSER options
    [opt, Options] = uq_process_option(Options, 'SSER', SSEROpts, 'struct');
    SSEROpts = opt.Value;
    
    % Partitioning
    [opt, SSEROpts] = uq_process_option(SSEROpts,'Partitioning',DEFAULTSSER.Partitioning);
    Internal.SSER.Partitioning = opt.Value; 
    
    % Selection
    [opt, SSEROpts] = uq_process_option(SSEROpts,'Refine',DEFAULTSSER.Refine);
    Internal.SSER.Refine = opt.Value; 
    
    % Experimental design
    [opt, SSEROpts] = uq_process_option(SSEROpts,'ExpDesign',DEFAULTSSER.ExpDesign);
    Internal.SSER.ExpDesign = opt.Value; 
    
    % Post Expansion Action
    [opt, SSEROpts] = uq_process_option(SSEROpts,'PostExpansion',DEFAULTSSER.PostExpansion);
    Internal.SSER.PostExpansion = opt.Value; 

    % Convergence option
    [opt, SSEROpts] = uq_process_option(SSEROpts,'Stopping',DEFAULTSSER.Stopping);
    Internal.SSER.Stopping = opt.Value;   

    % Expansion option
    [opt, SSEROpts] = uq_process_option(SSEROpts,'ExpOptions',DEFAULTSSER.ExpOptions);
    Internal.SSER.ExpOptions = opt.Value;   
end

%% Initialize line sampling options
if InitLS
    
    LSOpts = struct;
    [opt, Options] = uq_process_option(Options, 'LS', LSOpts, 'struct');
    LSOpts = opt.Value;
    
    % Process LS Batch, MaxLines and TagetCoV to Internal.Simulation
    % if statement needed such that it does not overwrite the options for
    % for the BLS method
    if strcmp(Internal.Method,'ls') || strcmp(Internal.Method,'alr')
        % MaxLines
        [opt, LSOpts] = uq_process_option(LSOpts, 'MaxLines', 1000, 'double');
        Internal.Simulation.MaxSampleSize = opt.Value;
    
        % BatchSize
        [opt, LSOpts] = uq_process_option(LSOpts, 'BatchSize', 100, 'double');
        Internal.Simulation.BatchSize = opt.Value;
    
        % TargetCoV
        [opt, LSOpts] = uq_process_option(LSOpts, 'TargetCoV', [], 'double');
        Internal.Simulation.TargetCoV = opt.Value;
    end

    % Direction options
    DirectionOpts = struct;
    [opt, LSOpts] = uq_process_option(LSOpts, 'Direction', DirectionOpts, 'struct');
    DirectionOpts = opt.Value;

    % Direction options: Initial
    [opt, DirectionOpts] = uq_process_option(DirectionOpts, 'Initial', 'GradOrigin', 'char');
    Internal.LS.Direction.Initial = opt.Value;

    % Direction options: Adaptive
    [opt, DirectionOpts] = uq_process_option(DirectionOpts, 'Adaptive', true, {'double', 'logical'});
    Internal.LS.Direction.Adaptive = opt.Value;
    
    % Process the field FORM:
    [opt, DirectionOpts] = uq_process_option(DirectionOpts, 'FORM', [], {'struct', 'uq_analysis', 'double'});
    Internal.LS.Direction.FORM = opt.Value;
    % In case the provided option is a double other than []
    if isnumeric(opt.Value) && ~isempty(opt.Value)
        fprintf('\nWarning: Invalid option for LS.FORM, it will be ignored.\n');
        opt.Value = [];
    end
    
    % If the user gave an analysis, check if it is solved and retrieve the
    % results:
    if isa(opt.Value, 'uq_analysis')
        if isprop(opt.Value, 'Results')
            opt.Value = opt.Value.Results(end);
            Internal.LS.FORM = opt.Value;
        else
            fprintf('\nWarning: The FORM results given to importance sampling are not valid.\n');
            fprintf('FORM will be executed to find the design point.\n');
            Internal.LS.FORM = [];
            opt.Value = [];
        end
    end


    % Check that if it was given by the user, it has the required fields,
    % otherwise run FORM later:
    if isstruct(opt.Value)
        if ~isfield(opt.Value, 'Ustar') % || ~isfield(opt.Value, 'BetaHL')
            fprintf('\nWarning: The FORM results given to importance sampling are not valid.\n');
            fprintf('FORM will be executed to find the design point.\n');
            Internal.LS.FORM = [];
        end
    end
    
    % Root options
    RootOpts = struct;
    [opt, LSOpts] = uq_process_option(LSOpts, 'RootFinder', RootOpts, 'struct');
    RootOpts = opt.Value;
    
    % Root options: Type
    [opt, RootOpts] = uq_process_option(RootOpts, 'Type', 'newton', 'char');
    Internal.LS.RootFinder.Type = opt.Value;

    % Root options: InitialRoot
    if strcmpi(Internal.LS.RootFinder.Type, 'spline')
        InitialRoot = 'spline';
    else
        InitialRoot = 'polynomial';
    end
    [opt, RootOpts] = uq_process_option(RootOpts, 'InitialRoot', InitialRoot, 'char');
    Internal.LS.RootFinder.InitialRoot = opt.Value;
    
    % Root options: WayPoints
    if (strcmp(Internal.LS.RootFinder.Type,'polynomial') || strcmp(Internal.LS.RootFinder.InitialRoot,'polynomial'))
        WayPoints = [2,5,7];
    else
        WayPoints = 2:7;
    end

    [opt, RootOpts] = uq_process_option(RootOpts, 'WayPoints', WayPoints, 'double');
    Internal.LS.RootFinder.WayPoints = opt.Value;

    % Root options: PolynomialOrder
    if (strcmp(Internal.LS.RootFinder.Type,'polynomial') || ...
            strcmp(Internal.LS.RootFinder.InitialRoot,'polynomial')) && ...
            length(Internal.LS.RootFinder.WayPoints) == 3
        
        PolynomialOrder = 2;
    elseif (strcmp(Internal.LS.RootFinder.Type,'polynomial') || ...
            strcmp(Internal.LS.RootFinder.InitialRoot,'polynomial'))
        
        PolynomialOrder = length(WayPoints)-1;
    else
        PolynomialOrder = [];
    end
    Internal.LS.RootFinder.PolynomialOrder = PolynomialOrder;

    % Root options: Tolerance of newton's method
    Internal.LS.RootFinder.Tolerance = 1e-3;

    % Root options: MaximumIterations of newton's method
    Internal.LS.RootFinder.MaximumIterations = 20;

end

%% Initialize partial bayesian active lerarning - line sampling options
if InitBLS
    BLSOpts = struct;
    
    [opt, Options] = uq_process_option(Options, 'BLS', BLSOpts, 'struct');
    BLSOpts = opt.Value;
    
    % initial design
    IEDefault.N = max(10, 2*length(Internal.Input.Marginals));
    IEDefault.Sampling = 'lhs';
    [opt, BLSOpts] = uq_process_option(BLSOpts,'IExpDesign',IEDefault,'struct');
    Internal.BLS.IExpDesign = opt.Value;
    
    % process the Kriging options if available
    [opt, BLSOpts] = uq_process_option(BLSOpts, 'Kriging', [], 'struct');
    Internal.BLS.Kriging = opt.Value;
    
     % check for the Nugget (in Kriging)
    if isfield(Internal.BLS.Kriging, 'Corr')
        if ~isfield(Internal.BLS.Kriging.Corr, 'Nugget')
            Internal.BLS.Kriging.Corr.Nugget = DEFAULTNugget;
        end
    else
        Internal.BLS.Kriging.Corr.Nugget = DEFAULTNugget;
    end
    
    % check the tolerance
    [opt, BLSOpts] = uq_process_option(BLSOpts, 'ConvCoV', 0.1, 'double');
    Internal.BLS.ConvCoV = opt.Value;
    
    % check the number of total added samples
    [opt, BLSOpts] = uq_process_option(BLSOpts, 'MaxAddedED', 1000, 'double');
    Internal.BLS.MaxAddedED = opt.Value;
    
    % check learning function
    [opt, BLSOpts] = uq_process_option(BLSOpts, 'LearningFunction', 'upper variance', 'char');
    Internal.BLS.LearningFunction = opt.Value;
    
end

%% Remove the type and name and  check the reminder
% Remove the option Type, that is not processed:
Options = rmfield(Options, 'Type');

% Remove also the Name option, if provided:
if isfield(Options, 'Name')
    Options = rmfield(Options, 'Name');
end

% Check if there was something else provided:
uq_options_remainder(Options, ...
    'Reliability');

%% Give the filtered options back to the object
current_analysis.Internal = Internal;
success = 1;

%% Run the analysis
uq_runAnalysis(current_analysis);