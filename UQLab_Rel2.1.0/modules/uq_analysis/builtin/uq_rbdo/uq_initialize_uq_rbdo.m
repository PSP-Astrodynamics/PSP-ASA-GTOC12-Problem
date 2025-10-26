function success = uq_initialize_uq_rbdo(current_analysis)
% success = UQ_INITIALIZE_UQ_RBDO(current_analysis):
%     initializes Reliability-Based Design Optimization defined in
%     CURRENT_ANALYSIS. All initializations are done in this file.
%
% See also: UQ_RBDO
% See also: UQ_RELIABILITY

success = 0;

%%
% User options
Options = current_analysis.Options;
% Actual options that the module will use
Internal = current_analysis.Internal ;

%% List of default options
% Design & Augmented space
DEFAULTDesVar.Type = 'constant' ;
DEFAULTDesVar.Std = 0 ;
DEFAULTDesVar.CoV = 0 ;
DEFAULTEnvVar.Type = 'Gaussian' ;

% Cost and Constraints models
DEFAULTModelType = 'default_model' ;
DEFAULTMetaType = 'Kriging' ;
DefLS.Threshold = 0 ;
DefLS.CompOp = '<=' ;

% Reliability - Simulation
DEFAULTRBDOMethod = 'Two-Level' ;
DEFAULTReliabilityMethod = 'MCS' ;
DEFAULTSamplingMethod = 'MC' ;
KnownRBDOMethods = {'two-level', 'mono-level', 'decoupled', 'ria','pma','sora', 'qmc','sla','deterministic'} ;

% Optimization - General
OptimKnownMethods = {'GA','HGA', 'CCMAES','HCCMAES', 'IP','SQP','intCCMAES','coupledIP','coupledSQP'} ;
% Known optimization methods with respect to toolbox
OptimKnownOptimToolboxMethods = {'IP','SQP','HGA','HCE','HCCMAES','COUPLEDIP','COUPLEDSQP'} ;
OptimKnownGlobalOptimToolboxMethods = 'GA' ;
OptimKnownOptimAndGlobalToolboxMethods = 'HGA' ;
% Optimization
OptimFieldsDatatypes.MAXFUNEVALS = 'double';
OptimFieldsDatatypes.NUMSTARTPOINTS = 'double';
OptimFieldsDatatypes.NLM = 'double';
OptimFieldsDatatypes.NPOP = 'double';
OptimFieldsDatatypes.NSTALL = 'double';
OptimFieldsDatatypes.TOLFUN = 'double';
OptimFieldsDatatypes.MAXITER = 'double';
OptimFieldsDatatypes.TOLX = 'double';
OptimFieldsDatatypes.FVALMIN = 'double';
OptimFieldsDatatypes.INITIALVALUE = 'double';
OptimFieldsDatatypes.BOUNDS = 'double';
OptimFieldsDatatypes.DISPLAY = 'char';
OptimFieldsDatatypes.ALGORITHM = 'char';
OptimFieldsDatatypes.INITIALSIGMA = 'double';
OptimFieldsDatatypes.TOLSIGMA = 'double';
OptimFieldsDatatypes.INTERNAL = 'struct';
OptimFieldsDatatypes.FDTYPE = 'char';
OptimFieldsDatatypes.FDSTEPSIZE = 'double';
OptimFieldsDatatypes.FDSTEP = 'char';
OptimFieldsDatatypes.LOCALMETHOD = 'char';

OptimReqFields.GA   = {'Display', 'MaxIter','TolFun'} ;
OptimReqFields.CCMAES   = {'Display', 'MaxIter','TolFun'} ;
OptimReqFields.IP   = {'Display', 'MaxIter', 'TolX','TolFun'} ;
OptimReqFields.SQP   = {'Display', 'MaxIter', 'TolX','TolFun'} ;
OptimReqFields.COUPLEDIP = {'Display', 'MaxIter', 'TolX','TolFun'} ;
OptimReqFields.COUPLEDSQP = {'Display', 'MaxIter', 'TolX','TolFun'} ;
OptimReqFields.HGA = {'Display', 'MaxIter','TolFun', 'TolX'} ;
OptimReqFields.HCCMAES = {'Display', 'MaxIter','TolFun', 'TolX'} ;
OptimReqFields.INTIP   = {'Display', 'MaxIter','TolFun'} ;

% Method-specific default values
% IP related options
OptimDefaults_Method.IP.MaxFunEvals = 1000;
OptimDefaults_Method.IP.nLM = 5;
OptimDefaults_Method.IP.NumStartPoints = 1;
OptimDefaults_Method.IP.FDType = 'forward';
OptimDefaults_Method.IP.FDStepSize = 1e-3;
OptimDefaults_Method.IP.FDStep = 'relative';


% SQP related options
OptimDefaults_Method.SQP.MaxFunEvals = 1000;
OptimDefaults_Method.SQP.nLM = 5;
OptimDefaults_Method.SQP.NumStartPoints = 1;
OptimDefaults_Method.SQP.FDType = 'forward';
OptimDefaults_Method.SQP.FDStepSize = 1e-3;
OptimDefaults_Method.SQP.FDStep = 'relative';
% GA
OptimDefaults_Method.GA.nStall = 50;
% GA.nPop depends on the dimension of the problem. This option will be
% defined once the dimension is known, i.e. after processing the input
% field options
OptimDefaults_Method.GA.nPop =  [] ;

%CCMAES related options
OptimDefaults_Method.CCMAES.nStall = 20 ;
OptimDefaults_Method.CCMAES.TolSigma = 1e-6 ;
OptimDefaults_Method.CCMAES.Internal = [] ;
% Default value of InitialSigma depends on the optimization bounds and will
% be set later
OptimDefaults_Method.CCMAES.InitialSigma = [] ;

% Intrusive CCMAES = CCMAES in terms of options
OptimDefaults_Method.INTCCMAES = OptimDefaults_Method.CCMAES ;
% Coupled IP/SQP = IP/SQP in terms of options
OptimDefaults_Method.COUPLEDIP = OptimDefaults_Method.IP ;
OptimDefaults_Method.COUPLEDSQP = OptimDefaults_Method.SQP ;

% Hybrid methods
OptimDefaults_Method.HGA = merge_structures(OptimDefaults_Method.IP,...
    OptimDefaults_Method.GA) ;
OptimDefaults_Method.HCCMAES = merge_structures(OptimDefaults_Method.IP,...
    OptimDefaults_Method.CCMAES) ;
% Add choice of the local algorithm. 'IP' or 'SQP'
OptimDefaults_Method.HGA.LocalMethod = 'ip' ;
OptimDefaults_Method.HCCMAES.LocalMethod = 'ip' ;

% Default values when nothing is set by the user
OptimDefaults.Method = 'CCMAES' ;
OptimDefaults.CCMAES = OptimDefaults_Method.CCMAES ;
OptimDefaults.Display = [] ;
OptimDefaults.MaxIter = 500 ;
OptimDefaults.TolX = 1e-6 ;
OptimDefaults.TolFun = 1e-6 ;
OptimDefaults.CommonRandomNumbers = 1 ;
OptimDefaults.LimitState = DefLS ;
OptimDefaults.ConstraintType = 'Pf' ; % This is changed to 'Beta' later if the user has given the constraint in using Options.TargetBeta 
% Optimization - CMAES

% Augmented space
DefAugSpace.Method = 'hypercube' ;
DefAugSpace.DesAlpha = 0.05 ;
DefAugSpace.EnvAlpha = 0.05 ;
% Enrichment
DEFAULTENRICH.Type = 'none' ;
DEFAULTENRICH.Sampling = 'MC' ;
DEFAULTENRICH.BatchSize = 1e4 ;
DEFAULTENRICH.BR = 100 ;
DEFAULTENRICH.NSamplesToAddPerIter = 1 ;
DEFAULTENRICH.ConvThreshold = 0.01 ; % This default value is modified later when using svr or coupled enrichment with Kriging.
DEFAULTENRICH.MaxAddedPoints = 100 ;
DEFAULTENRICH.LocalNPoints = 1 ;
DEFAULTENRICH.LocalConvThreshold = 2 ;
DEFAULTENRICH.LocalMaxAdded = 2 ;
DEFAULTENRICH.LocalRetsart = true ;
DEFAULTENRICH.LocalTryEnr = 4 ;
DEFAULTENRICH.MOStrategy = 'max' ;
% Known Metamodels
KnownMetamodels = {'Kriging','PCE','PCK','SVR','SVC','LRA'} ;

%% Set the Method:
% Depending on the method, some parts of the initialization script are
% needed or not:
InitSimulation = false;
InitFORM = false;
InitGradient = false;
InitIS = false;
InitSubsetSim = false;
InitInvFORM = false ;

%% RBDO Method
% Set RBDO method
[rbdoMethod, Options] = uq_process_option(Options, 'Method', DEFAULTRBDOMethod, 'char');
if rbdoMethod.Missing
    Internal.Method = DEFAULTRBDOMethod ;
end
if any(strcmpi(KnownRBDOMethods, rbdoMethod.Value)) && ~rbdoMethod.Invalid
    Internal.Method = rbdoMethod.Value ;
else
    % If the selected method is unknown raise a warning and use the default
    msg = sprintf('Invalid RBDO method. Using the default: %s instead.',...
        DEFAULTRBDOMethod);
    EVT.Type = 'W';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:rbdo:init:rbdomethod_override';
    uq_logEvent(current_analysis, EVT);
    
    Internal.Method = DEFAULTRBDOMethod ;
end
% Now update the default optimization algorithm if the user chose any
% approaximation RBDO technique...
if any(strcmpi(Internal.Method, {'ria','pma','sora', 'sla'}))
    OptimDefaults.Method = 'SQP' ;
end

% Update some convergence criteria in case SORA is used:
if strcmpi(Internal.Method,'sora')
    % MaxIter = Max number of cycles
    OptimDefaults.MaxIter = 100 ;
end
%% GLOBAL DISPLAY LEVEL
[Options, Internal] = uq_initialize_display(Options, Internal);

%% HPC options - valid for SLA
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
    
    [opt, HPCOptions] = uq_process_option(HPCOptions, 'SLA', true, {'double', 'logical'});
    Internal.HPC.SLA = opt.Value;
    
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
    Internal.HPC.SLA = false;
    
end
%%%UQHPCEND%%%

%%
% Set the reliability analysis method
if ~isfield(Options, 'Reliability')
    Options.Reliability = struct ;
end
[opt, Options.Reliability] = uq_process_option(Options.Reliability, 'Method', DEFAULTReliabilityMethod, 'char');
Internal.Reliability.Method = opt.Value ;
% Make sure that the reliability analysis is consistent with the chosen
% method

% RIA should correspond to FORM
if strcmpi(Internal.Method, 'ria')
    if  ~strcmpi(opt.Value, 'form')
        Internal.Reliability.Method = 'form' ;
        if ~opt.Missing || opt.Invalid
            % Print a warning if the user has set a reliability analysis
            % different from FORM for an RIA analysis
            fprintf('\nWarning: The reliability method has been set to FORM for RIA\n') ;
        end
    end
end

% Decoupled and PMA should correspond to inverse form
if any(strcmpi(Internal.Method, {'pma', 'decoupled','sora'}))
    if ~any(strcmpi(opt.Value, {'inverseform','iform', 'inverse form'}))
        Internal.Reliability.Method = 'iform' ;
        if ~opt.Missing || opt.Invalid
            % Print a warning if the user has set a reliability analysis
            % different from inverse FORM for a PMA/SORA method
            if strcmpi(Internal.Method, 'pma')
                fprintf('\nWarning: The given reliability method is ignored. PMA is based on inverse form\n') ;
            elseif strcmpi(Internal.Method, 'sora')
                fprintf('\nWarning: The given reliability method is ignored. SORA is based on inverse form\n') ;
            elseif strcmpi(Internal.Method, 'decoupled')
                fprintf('\nWarning: The given reliability method has been set to inverse FORM for the decoupled approach (Only availale option)\n') ;
            end
        end
    end
end

% QMC should correspond to qmc
if strcmpi(Internal.Method, 'qmc')
    if  ~strcmpi(opt.Value, {'qmc'})
        Internal.Reliability.Method = 'qmc' ;
        if ~opt.Missing || opt.Invalid
            % Print a warning if the user has set a reliability analysis
            % different from qmc for a QMC analysis
            fprintf('\nWarning: The reliability method has been set to quantile Monte carlo sampling for QMC\n') ;
        end
    end
end

% For SLA make sure the gradient is initialized
if strcmpi(Internal.Method, 'sla')
    InitGradient = true ;
end

switch lower(Internal.Reliability.Method)
    case {'mc','mcs','montecarlo', 'monte carlo'}
        % Needs to initialize the simulation options:
        InitSimulation = true;
        DEFAULTBatchSize = 1e4;
        DEFAULTMaxSampleSize = 1e4;
        
        % Set the name that will be used throughout the code
        Internal.Reliability.Method = 'mcs' ;
    case {'importancesampling','is','importance sampling'}
        % Needs to initialize the simulation options, FORM and the
        % gradient:
        InitSimulation = true;
        InitFORM = true;
        InitGradient = true;
        InitIS = true;
        DEFAULTBatchSize = 1e2;
        DEFAULTMaxSampleSize = 1e3 ;
        
        % Set the name that will be used throughout the code
        Internal.Reliability.Method = 'is' ;
    case 'form'
        [opt, Options] = uq_process_option(Options, 'NoSORM');
        if opt.Disabled || opt.Missing || opt.Invalid
            Internal.Reliability.NoSORM = true;
        else
            Internal.Reliability.NoSORM = opt.Value;
        end
        
        %         Decide whether to change to SORM or not:
        if Internal.Reliability.NoSORM
            Internal.Reliability.Method = 'form';
        else
            Internal.Reliability.Method = 'sorm';
        end
        % Needs to initialize FORM and the gradient:
        InitFORM = true;
        InitGradient = true;
        
    case 'sorm'
        %         Internal.Method = 'sorm';
        % Needs to initialize FORM and the gradient:
        InitFORM = true;
        InitGradient = true;
        % Set the name that will be used throughout the code
        Internal.Reliability.Method = 'sorm' ;
    case 'subset'
        % Needs to initialize simulation options and subset simulation
        % options
        %         Internal.Method = 'subset';
        InitSimulation = true;
        InitSubsetSim = true;
        DEFAULTBatchSize = 1e3;
        DEFAULTMaxSampleSize = 1e5 ;
        
        % Set the name that will be used throughout the code
        Internal.Reliability.Method = 'subset' ;
    case 'qmc'
        InitSimulation = true ;
        DEFAULTBatchSize = 1e4;
        DEFAULTMaxSampleSize = 1e4 ;
        
        % Set the name that will be used throughout the code
        Internal.Reliability.Method = 'qmc' ;
    case {'inverseform','iform', 'inverse form'}
        InitInvFORM = true ;
        InitFORM = true ;
        % Set the name that will be used throughout the code
        Internal.Reliability.Method = 'iform' ;
    otherwise
        error('\nThe provided relibaility method "%s" is not correct.', ...
            Internal.Reliability.Method);
end

%% Options for the FORM algorithm (and therefore also for SORM and IS)
if InitFORM
    
    FORMOpts = struct;
    
    [opt, Options.Reliability] = uq_process_option(Options.Reliability, 'FORM', FORMOpts, 'struct');
    FORMOpts = opt.Value;
    
    % Solution algorithm:
    [opt, FORMOpts] = uq_process_option(FORMOpts, 'Algorithm', 'iHLRF', 'char');
    % Only two specific strings are accepted:
    if ~any(strcmpi(opt.Value, {'hlrf', 'ihlrf'}))
        Internal.Reliability.FORM.Algorithm = opt.Default;
        opt.Invalid = true;
        % Show a warning if the user provided an invalid string:
        fprintf('\nWarning: The provided algorithm "%s" was not recognized. Switching to "%s".\n', opt.Value, opt.Default);
    else
        Internal.Reliability.FORM.Algorithm = opt.Value;
    end
    
    % Stop criteria on U: (Stagnation)
    [opt, FORMOpts] = uq_process_option(FORMOpts, 'StopU', 1e-4, 'double');
    Internal.Reliability.FORM.StopU = opt.Value;
    
    % Stop criteria on G: (Convergence)
    [opt, FORMOpts] = uq_process_option(FORMOpts, 'StopG', 1e-6, 'double');
    Internal.Reliability.FORM.StopG = opt.Value;
    
    
    % Maximum number of iterations:
    [opt, FORMOpts] = uq_process_option(FORMOpts, 'MaxIterations', 1e2, 'double');
    Internal.Reliability.FORM.MaxIterations = opt.Value;
end

%% Differentiation options (also for FORM, SORM, IS, SLA):
if InitGradient
    % default to standardized calculation of the gradient
    if isfield(Options.Reliability, 'Gradient')
        GradOpts = Options.Reliability.Gradient;
        if ~isfield(GradOpts, 'Step') || isempty(GradOpts.Step)
            Options.Reliability.Gradient.Step = 'Standardized';
        end
    else
        Options.Reliability.Gradient.Step = 'Standardized';
    end
    [Options.Reliability, Internal.Reliability] = ...
        uq_initialize_gradient(Options.Reliability, Internal.Reliability, true);
end

%% SIMULATION METHODS (MC, IS, subset sim., and AKMCS)
if InitSimulation
    
    SimOpts = struct;
    
    [opt, Options.Reliability] = uq_process_option(Options.Reliability, 'Simulation', SimOpts, 'struct');
    SimOpts = opt.Value;
    
    
    % Set the batch size to evaluate at a time
    [optBatchSize, SimOpts] = uq_process_option(SimOpts, 'BatchSize', DEFAULTBatchSize, 'double');
    Internal.Reliability.Simulation.BatchSize = optBatchSize.Value;
    
    % Set the sampling method
    [opt, SimOpts] = uq_process_option(SimOpts, 'Sampling', DEFAULTSamplingMethod, 'char');
    Internal.Reliability.Simulation.Sampling = opt.Value;
    
    % Set the target coefficient of variation
    [opt, SimOpts] = uq_process_option(SimOpts, 'TargetCoV', [], 'double');
    Internal.Reliability.Simulation.TargetCoV = opt.Value;
    
    % If there is a target CoV, we can set max. runs to Inf by default,
    % otherwise, we limit it to 10^5:
    if isempty(opt.Value)
        if strcmpi(Internal.Reliability.Method, 'is')
            MRdefault = 1e3;
        elseif strcmpi(Internal.Reliability.Method, 'qmc')
            MRdefault = 1e4;
        else
            MRdefault = 1e5 ;
        end
    else
        MRdefault = Inf;
    end
    
    % Maximum number of function evaluations
    [optMaxSampleSize, SimOpts] = uq_process_option(SimOpts, 'MaxSampleSize', MRdefault, 'double');
    Internal.Reliability.Simulation.MaxSampleSize = optMaxSampleSize.Value;
    if optMaxSampleSize.Invalid || optMaxSampleSize.Missing || optMaxSampleSize.Disabled
        if strcmpi(Internal.Reliability.Method, 'is')
            fprintf('Warning: Maximum number of model evaluations was limited to 10^3\n');
        elseif any(strcmpi(Internal.Reliability.Method, {'qmc'}))
            fprintf('Warning: Maximum number of model evaluations was limited to 10^4\n');
        else
            fprintf('Warning: Maximum number of model evaluations was limited to 10^5\n');
        end
    end
    
    if any(strcmpi(Internal.Reliability.Method, {'mc','mcs','qmc'}))
        % When using Monte Carlo Sampling for evaluating Pf or quantile,
        % make sure that BatchSize and MaxSampleSize have the same value
        if optMaxSampleSize.Missing & ~optBatchSize.Missing
            % Batch size is given but not maxSampleSize, set MaxSampleSize =
            % BatchSize
            Internal.Reliability.Simulation.MaxSampleSize = Internal.Reliability.Simulation.BatchSize ;
        elseif ~optMaxSampleSize.Missing & optBatchSize.Missing
            % Batch size is given bnut not maxSampleSize, set MaxSampleSize =
            % BatchSize
            Internal.Reliability.Simulation.BatchSize = Internal.Reliability.Simulation.MaxSampleSize ;
        end
        % If the two are given by the user issue a warning
        if ~optMaxSampleSize.Missing & ~optBatchSize.Missing
            fprintf('Warning: Maximum sample size and batch size are different.\n') ;
            fprintf('This may cause numerical issues if gradient-based methods are used in optimization.\n');
        end
    end
    
    % Confidence level Alpha: This option is purposely put very low so as
    % not to be used at all (or should be put extremely low)
    [opt, SimOpts] = uq_process_option(SimOpts, 'Alpha', 0.05, 'double');
    Internal.Reliability.Simulation.Alpha = opt.Value;
    
    uq_options_remainder(SimOpts, 'the simulation methods');
    
end

%% Importance sampling (IS) special options:
if InitIS
    
    % See if the option was provided at all:
    ISOpts.FORM = [];
    ISOpts.Instrumental = [];
    [opt, Options.Reliability] = uq_process_option(Options.Reliability, 'IS', ISOpts, 'struct');
    ISOpts = opt.Value;
    
    % Process the field FORM:
    [opt, ISOpts] = uq_process_option(ISOpts, 'FORM', [], {'struct', 'uq_analysis', 'double'});
    Internal.Reliability.IS.FORM = opt.Value;
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
            Internal.Reliability.IS.FORM = opt.Value;
        else
            fprintf('\nWarning: The FORM results given to importance sampling are not valid.\n');
            fprintf('FORM will be executed to find the design point.\n');
            Internal.Reliability.IS.FORM = [];
            opt.Value = [];
        end
    end
    
    % Check that if it was given by the user, it has the required fields,
    % otherwise run FORM later:
    if isstruct(opt.Value)
        if ~isfield(opt.Value, 'Ustar') % || ~isfield(opt.Value, 'BetaHL')
            fprintf('\nWarning: The FORM results given to importance sampling are not valid.\n');
            fprintf('FORM will be executed to find the design point.\n');
            Internal.Reliability.IS.FORM = [];
        end
    end
    
    % Process the instrumental density, field SOpts.IS.Instrumental
    [opt, ISOpts] = uq_process_option(ISOpts, 'Instrumental', [], {'struct', 'uq_input', 'double'});
    Internal.Reliability.IS.Instrumental = opt.Value;
    
    % In case the provided option is a double other than []
    if isnumeric(opt.Value) && ~isempty(opt.Value)
        fprintf('\nWarning: Invalid option for IS.Instrumental, it will be ignored.\n');
        opt.Value = [];
    end
    
    if isstruct(opt.Value)
        try
            InstrumentalInput = uq_createInput(opt.Value, '-private');
            Internal.IS.Instrumental = InstrumentalInput;
        catch ME
            fprintf('\nWarning: The struct given in IS.Instrumental does not define a proper instrumental density');
            fprintf('\nInput could not be initialized with error:\n%s\n', ME.message);
            fprintf('\nFORM will be executed to find a proper instrumental density\n');
            Internal.Reliability.IS.Instrumental = [];
            
        end
    end
    
    % Check if both were given, and in that case prefer the instrumental
    % density:
    if ~isempty(Internal.Reliability.IS.Instrumental) && ~isempty(Internal.Reliability.IS.FORM)
        fprintf('\nWarning: Importance sampling cannot accept both FORM results and an instrumental density\n');
        fprintf('FORM results will be ignored\n');
        Internal.Reliability.IS.FORM = [];
    end
    % Check if there were more options given:
    uq_process_option(ISOpts, ' importance sampling.');
end

%% Initialize subset simulation options:
if InitSubsetSim
    
    SSOpts = struct;
    
    [opt, Options.Reliability] = uq_process_option(Options.Reliability, 'Subset', SSOpts, 'struct');
    SSOpts = opt.Value;
    
    %set the intermediate failure probability p0
    [opt, SSOpts] = uq_process_option(SSOpts, 'p0', 0.1, 'double');
    Internal.Reliability.Subset.p0 = opt.Value;
    
    %set the maximum number of subsets
    %     MaxSubsets = floor(Internal.Reliability.Simulation.MaxSampleSize / ...
    %         Internal.Reliability.Simulation.BatchSize / (1-Internal.Reliability.Subset.p0));
    % Set MaxSubset such that the lowest Pf than can be found is 10^{-15}.
    % If p0 = 0.1 then MaxSubsets here would be 15
    MaxSubsets = ceil(log10(1e-15)/log10(Internal.Reliability.Subset.p0)) ;
    [opt, SSOpts] = uq_process_option(SSOpts, 'MaxSubsets', MaxSubsets,'double');
    Internal.Reliability.Subset.MaxSubsets = opt.Value ;
    
    %set the MH acceptance criterion
    [opt, SSOpts] = uq_process_option(SSOpts, 'Componentwise', 1, 'double');
    Internal.Reliability.Subset.Componentwise = opt.Value;
    
    %set the random walker of the Markov Chain
    RWOpts = struct;
    [opt, SSOpts] = uq_process_option(SSOpts, 'Proposal', RWOpts, 'struct');
    RWOpts = opt.Value;
    
    %set the proposal distribution of the random walker
    [opt, RWOpts] = uq_process_option(RWOpts, 'Type', 'uniform', 'char');
    Internal.Reliability.Subset.Proposal.Type = opt.Value;
    
    %     set the proposal distribution of the random walker
    %     RWdOpts = struct;
    %     [opt, RWOpts] = uq_process_option(RWOpts, 'propDistr', RWdOpts, 'struct');
    %     RWdOpts = opt.Value;
    
    
    %set the parameters
    [opt, RWOpts] = uq_process_option(RWOpts, 'Parameters', 1, 'double');
    Internal.Reliability.Subset.Proposal.Parameters = opt.Value;
    
end

%%
if InitInvFORM
    invFORMOpts = struct;
    
    [opt, Options.Reliability] = uq_process_option(Options.Reliability, 'invFORM', invFORMOpts, 'struct');
    invFORMOpts = opt.Value;
    
    % inverse FORM algorithm Specific Options
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'StartingPoint', [], 'double');
    Internal.Reliability.invFORM.StartingPoint = opt.Value;
    
    % Solution algorithm:
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'Algorithm', 'AMV', 'char');
    % Only two specific strings are accepted:
    if ~any(strcmpi(opt.Value, {'amv', 'cmv', 'hmv','sqp'}))
        Internal.Reliability.invFORM.Algorithm = opt.Default;
        opt.Invalid = true;
        % Show a warning if the user provided an invalid string:
        fprintf('\nWarning: The provided algorithm "%s" was not recognized. Switching to "%s".\n', opt.Value, opt.Default);
    else
        Internal.Reliability.invFORM.Algorithm = opt.Value;
    end
    
    % Target reliability index
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'TargetBeta', 1.6449, 'double');
    Internal.Reliability.invFORM.TargetBeta = opt.Value;
    
    % Stop criteria on U: (Stagnation)
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'StopU', 1e-3, 'double');
    Internal.Reliability.invFORM.StopU = opt.Value;
    
    % Stop criteria on U: (Stagnation)
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'StopG', 1e-3, 'double');
    Internal.Reliability.invFORM.StopG = opt.Value;
    
    % Maximum number of iterations:
    [opt, invFORMOpts] = uq_process_option(invFORMOpts, 'MaxIterations', 1e2, 'double');
    Internal.Reliability.invFORM.MaxIterations = opt.Value;
    
end

% Check if the limit-state options were defined at the reliability level
% and handle them appropriately
if isfield(Options.Reliability, 'LimitState')
    if isfield(Options.LimitState, 'CompOp') || isfield(Options.LimitState, 'Threshold')
        error('The limit-state option .CompOp and .Threshold cannot be defined both at the reliability and optimization levels!');
    else
        % If they are not defined at the optimization level, transfer the one
        % defined at the reliability level to the optimization level
        if isfield(Options.Reliability.LimitState,'CompOp')
            Options.LimitState.CompOp = Options.Reliability.LimitState.CompOp;
        end
        if isfield(Options.Reliability.LimitState, 'Threshold')
            Options.LimitState.Threshold = Options.Reliability.LimitState.Threshold;
        end
        % Remove the limit-state option for Reliability
        Options.Reliability = rmfield(Options.Reliability, 'LimitState') ;
    end
end

if isfield(Options.Reliability, 'Model')
    warning('The model defined at the reliability level will be ignored.');
end
if isfield(Options.Reliability, 'Input')
    warning('The input defined at the reliability level will be ignored.');
end
%% RBDO main options
% Target failure probability
[optPf, Options] = uq_process_option(Options, 'TargetPf', [], 'double');
% Reliability index
[optBeta, Options] = uq_process_option(Options, 'TargetBeta', [], 'double');

% Check consistency: Only one of the options TargetPf or TargetBeta should be provided
% Also set the default constraint type to 'beta' if TargetBeta is given by
% the user
if ~isempty(optPf.Value)
    Internal.TargetPf = optPf.Value ;
    if  ~isempty(optBeta.Value)
        error('Only the target failure probability or reliability index can be defined. Not both!');
    else
        % Compute Beta targets from given Pf
        Internal.TargetBeta = norminv(1 - optPf.Value,0,1) ;
    end
elseif ~isempty(optBeta.Value)
    Internal.TargetBeta = optBeta.Value ;
    if  ~isempty(optPf.Value)
        error('Only the target failure probability or reliability index can be defined. Not both!');
    else
        % Compute Pf targets from given Beta
        Internal.TargetPf = normcdf(-optBeta.Value,0,1) ;
        % Also set the default constrasint type to Beta
         OptimDefaults.ConstraintType = 'Beta' ;
    end
else
    % The target Pf or Beta are mandatory options!
    error('A target failure probability or reliability index must be defined')
end

%% Input definition
if isfield(Options, 'Input')
    
    %% 1. Design variables
    if isfield(Options.Input, 'DesVar')
        [desvarOpt, Options.Input] = uq_process_option(Options.Input,'DesVar') ;
        
        desvar = desvarOpt.Value ;
        M_d = length(desvar) ;
        % Save the number of design variables
        Internal.Runtime.M_d = M_d ;
        for ii = 1 : M_d
            StdIsGiven = true ;
            CovIsGiven = true ;
            
            if ~isfield(desvar(ii), 'Name') || isempty(desvar(ii).Name)
                % set a default name to each variable: d1, d2, ...
                desvar(ii).Name = sprintf('d%d',ii) ;
            end
            if ~isfield(desvar(ii), 'Type') || isempty(desvar(ii).Type)
                % Set default type: deterministic
                desvar(ii).Type = DEFAULTDesVar.Type ;
            end
            if ~isfield(desvar(ii),'Std') || isempty(desvar(ii).Std)
                % Set default standard deviation : 0 (deterministic)
                StdIsGiven = false ;
                desvar(ii).Std = DEFAULTDesVar.Std ;
            end
            if ~isfield(desvar(ii),'CoV') || isempty(desvar(ii).CoV)
                % Set default coef. of variation : 0 (deterministic)
                CovIsGiven = false ;
                desvar(ii).CoV = DEFAULTDesVar.CoV ;
            end
            
            % The dispersion measure for optimization is set as follows:
            % if Std is given but not CoV, set dispersionMeasure parameter as Std
            % If CoV is given but not Std, set dispersionMeasure parameter
            % as CoV
            % If none is given assume that DispersionMeasure is Std ( Default Std value =0)
            % If the two are given, issue an error: Only one should be defined
            if StdIsGiven && ~CovIsGiven
                desvar(ii).Runtime.DispersionMeasure = 'Std';
            elseif ~StdIsGiven && CovIsGiven
                desvar(ii).Runtime.DispersionMeasure = 'CoV';
            elseif ~StdIsGiven && ~CovIsGiven
                % Default value is Std
                desvar(ii).Runtime.DispersionMeasure = 'Std';
            else % The two are given
                error('Only one measure of variability should be given: either Std or CoV') ;
            end
        end
        
        % Assign desin variable fields to the current analysis
        Internal.Input.DesVar = desvar ;
    else
        error('Design variables must be defined!') ;
    end
    
    %% 2. Environmental variables
    
    if isfield(Options.Input, 'EnvVar')
        [envInput, Options.Input] = uq_process_option(Options.Input,'EnvVar') ;
        
        % Check that envInput is a valid input type
        try 
            EnvInputObj = uq_getInput(envInput.Value);
        catch 
            error('The provided input model for the environmental variables is not a valid UQLab INPUT model!') ;
        end


        Internal.Input.EnvVar = EnvInputObj ;
        
        % NUmber of environmental variables
        M_z = length(EnvInputObj.Marginals) ;
        
%         % Make sure moments are defined for deterministic design
%         % optimization (DDO)
%         if strcmpi(Internal.Method, 'deterministic')
%             if ~isfield(Internal.Input.EnvVar, 'Moments')
%                 Internal.Input.EnvVar = uq_MarginalFields(Internal.Input.EnvVar) ;
%             end
%         end
    else
        % Do nothing: environmental variables are optional
        M_z = 0 ;
    end
    % Save the number of environmental variables
    Internal.Runtime.M_z = M_z ;
else
    error('Design and/or Environmental variables must be defined!')
end


%% Optimization related options

% Pre-processing of optim options: Now that M_d has been defined, set the
% defaults values for those options which depend on M_d:
if M_d <= 5
OptimDefaults_Method.GA.nPop =  50 ;
OptimDefaults_Method.HGA.nPop = 50 ;
else
 OptimDefaults_Method.GA.nPop =  200;
OptimDefaults_Method.HGA.nPop =  200 ;
end
% Start procesing optim options
if isfield(Options, 'Optim')
    %% 1. Common random numbers
    [optCRN, Options.Optim] = uq_process_option(Options.Optim, 'CommonRandomNumbers', OptimDefaults.CommonRandomNumbers, {'double','logical'});
    Internal.Optim.CommonRandomNumbers = optCRN.Value ;
    if ~Internal.Optim.CommonRandomNumbers
        fprintf('Warning: Common random numbers is disabled, an appropriate optimization algorithm should be used.\n')
    end
    if Internal.Optim.CommonRandomNumbers == 1
        % Get a seed that will be used to generate samples during the
        % reliability analysis.
        Internal.Runtime.Seed = randi(1e4);
        if any(strcmpi(Internal.Reliability.Method,{'mcs','qmc'}))
            % Now if using MCS or QMC, generate some data that will
            % be consistently used between iterations. These data are generated
            % using the same distribution but with moments 0 and 1. This will
            % then be mapped into the appropriate distribution based on the
            % current design by isoprobabilistc transformation
            % 1. Design variables
            if M_d > 0
                for ii = 1:M_d
                    XOpts.Marginals(ii).Type = Internal.Input.DesVar(ii).Type ;
                    if strcmpi(XOpts.Marginals(ii).Type, 'lognormal')
                        % For lognormal distribution use moments that
                        % correspond to [lambda,zeta]=[0,1]
                        XOpts.Marginals(ii).Moments = ...
                            [exp(0.5),sqrt((exp(1)-1)*exp(1))];
                    elseif strcmpi(XOpts.Marginals(ii).Type, 'constant')
                        XOpts.Marginals(ii).Moments = [0 0];
                    else
                        XOpts.Marginals(ii).Moments = [0 1] ;
                    end
                end
                XOpts.Marginals = uq_MarginalFields( XOpts.Marginals ) ;
                XOpts.Marginals = rmfield(XOpts.Marginals, 'Moments' );
                Internal.Input.DesCRNMarginals = XOpts.Marginals ;
                Internal.Input.DesCRNInput = uq_createInput( XOpts, '-private' ) ;
                Internal.Input.DesCRNSamples = uq_getSample( ...
                    Internal.Input.DesCRNInput, ...
                    Internal.Reliability.Simulation.BatchSize, ...
                    Internal.Reliability.Simulation.Sampling ) ;
                
            end
            % 2. Environmental variables - Since they are the same throughout
            % optimization, always use the same data
            if M_z > 0
                Internal.Input.EnvCRNSamples = uq_getSample( ...
                    Internal.Input.EnvVar, ...
                    Internal.Reliability.Simulation.BatchSize, ...
                    Internal.Reliability.Simulation.Sampling ) ;
            end
        end
    end

    %% 4. Constraint Type (only valid for two level approaches)
    [opt, Options.Optim] = uq_process_option(Options.Optim, 'ConstraintType', OptimDefaults.ConstraintType, {'char'});
    if ~any( strcmpi(opt.Value,{'pf','beta'}) )
        fprintf('Warning: Unknown constraint type the default value is chosen \n') ;
        if any (strcmpi(Internal.Method,{'ria','pma'}))
            Internal.Optim.ConstraintType = 'beta' ;
        else
            Internal.Optim.ConstraintType = OptimDefaults.ConstraintType ;
        end
    else
        if ~strcmpi(opt.Value, 'beta') && any (strcmpi(Internal.Method,{'ria','pma'}))
            if ~opt.Missing
                % If the user did give a value different than beta and the
                % optmization method is ria or pma, issue a warning and switch
                % to beta
                warning('The chosen constraint type is not compatible to RIA or PMA, switching to ''beta'' \n');
            end
            Internal.Optim.ConstraintType = 'beta' ;
        else
            Internal.Optim.ConstraintType = opt.Value ;
        end

    end
    
    % For RIA and PMA make sure that beta is used as constraint type
    
    %% 5. Scale of Pf (log10 or original - Valid only when using Pf as constraint type)
    [opt, Options.Optim] = uq_process_option(Options.Optim, 'UseLogScale', 'true', {'logical', 'double'});
%     if opt.Missing || opt.Invalid
%         if strcmpi(Internal.Optim.ConstraintType,'pf')
%             fprintf('The optimization will be carried out by mapping P_f in the log10 space\n') ;
%             % Is this necessary?
%         end
%     end
    if ~opt.Missing && strcmpi(Internal.Optim.ConstraintType,'beta')
        fprintf('Option UseLogSpace is ignored when constraint type is beta\n') ;
    end
    Internal.Optim.UseLogScale = opt.Value ;
    
    %% 6. Optimization methods and related options
    [optMethod, Options.Optim] = uq_process_option(Options.Optim, ...
        'Method',OptimDefaults.Method, 'char');
    % When using SORA, PMA, RIA and SLA only local optimizers can be used...
    if any(strcmpi(Internal.Method, {'ria','sla','sora','sla'}))
        if ~optMethod.Missing && ~any(strcmpi(optMethod,{'sqp','ip'}))
            warning('Only local optimizer can be used with with approximation RBDO methods (RIA, PMA, SORA, SLA)');
            fprintf('The optimization algorithm is set to SQP.\n');
            optMethod.Value = 'SQP' ;
        end
    end
    
    if optMethod.Invalid
        msg = sprintf('Invalid Optimization method. Using the default: %s instead.',...
            optMethod.Value);
        EVT.Type = 'W';
        EVT.Message = msg;
        EVT.eventID = 'uqlab:rbdo:init:optmethod_override';
        uq_logEvent(current_analysis, EVT);
        
        Internal.Optim.Method = optMethod.Value ;
    elseif optMethod.Missing
        msg = sprintf('Using the default optimization method: %s.',...
            optMethod.Value);
        EVT.Type = 'D';
        EVT.Message = msg;
        EVT.eventID = 'uqlab:rbdo:init:optmethod_defaultsub';
        uq_logEvent(current_analysis, EVT);
        Internal.Optim.Method = optMethod.Value ;
    end
    
    % Make sure that the selected method exists and a license is
    % available to use it
    if any(strcmpi(OptimKnownMethods, optMethod.Value))
        % lbfgs is known as BFGS
        if strcmpi(optMethod.Value, 'lbfgs')
            optMethod.Value = 'BFGS';
        end
        
        % Make sure that corresponding toolbox license is available for
        % the selected optimization method
        try
            % Make sure that the optimization toolbox is avaialble
            evalc('x = fmincon(@(x)x.^2, 0.5, 1, 3);');
            optimization_check = true;
        catch
            optimization_check = false;
        end
        try
            % Make sure that the global optimization toolbox is avaialble
            GAoptions = gaoptimset;
            goptimization_check = true;
        catch
            goptimization_check = false;
        end
        if any(strcmpi(OptimKnownOptimToolboxMethods, optMethod.Value))
            % 'BFGS', 'LBFGS' and 'HGA', 'HCCMAES' all rely on the 'fmincon function which belongs to the Optimization toolbox
            if ~optimization_check
                fprintf('The selected optimization algorithm is not available\n');
                fprintf('%s requires the Optimization toolbox which is not available\n',optMethod.Value) ;
                fprintf('Please select another algorithm\n') ;
                error('RBDO initialization failed: No license for Optimization toolbox') ;
            end
        elseif any(strcmpi(OptimKnownGlobalOptimToolboxMethods,optMethod.Value))
            % 'GA' relies on the ga function which belongs to the global optimization toolbox
            if ~goptimization_check
                fprintf('The selected optimization algorithm is not available\n');
                fprintf('%s requires the Global Optimization toolbox which is not available\n',optMethod.Value) ;
                fprintf('Please select another algorithm\n') ;
                error('RBDO initialization failed: No license for Global Optimization toolbox') ;
            end
        elseif any(strcmpi(OptimKnownOptimAndGlobalToolboxMethods,optMethod.Value))
            % 'HGA' relies on ga and fmincon which belong respectively
            % to the Global Optimization toolbox and to the
            % Optimization toolbox
            if ~(optimization_check && goptimization_check)
                toolbox_result = {'Available', '*Not Available*'};
                fprintf('The selected optimization algorithm is not available\n');
                fprintf('\t Optimization toolbox: \t\t\t[%s]\n', toolbox_result{2-optimization_check}) ;
                fprintf('\t Global Optimization toolbox: \t\t[%s]\n', toolbox_result{2-goptimization_check}) ;
                fprintf('Please select another algorithm\n') ;
                error('RBDO initialization failed: No license for Optimization toolbox and/or Global Optimization toolbox') ;
            end
        else
            % do nothing. Should fall here only if 'sade', or 'ccmaes' is chosen or if the
            % 'OptimKnownMethods is extended
        end
        Internal.Optim.Method = optMethod.Value ;
        
    else
        % If the selected method is unknown raise a warning and use the default
        msg = sprintf('Invalid Optimization method. Using the default: %s instead.',...
            OptimDefaults.Method);
        EVT.Type = 'W';
        EVT.Message = msg;
        EVT.eventID = 'uqlab:rbdo:init:optmethod_override';
        uq_logEvent(current_analysis, EVT);
        
        Internal.Optim.Method = OptimDefaults.Method ;
    end
    
    
    % Get the required fields for the selected Optimization method
    optreqFields = OptimReqFields.(...
        upper(Internal.Optim.Method)) ;
    optmethreqFields = OptimDefaults_Method.(...
        upper(Internal.Optim.Method));
    
    if ~isempty(optmethreqFields)
        optmethreqFields = fieldnames(optmethreqFields) ;
    else
        optmethreqFields = [];
    end
    
    % Try to parse each of the required fields
    for ii = 1 : length(optreqFields)
        [fieldval, Options.Optim] = uq_process_option(Options.Optim, ...
            optreqFields{ii},OptimDefaults.(optreqFields{ii}), ...
            OptimFieldsDatatypes.(upper(optreqFields{ii})));
        switch lower(class(fieldval.Value))
            case 'char'
                printval = fieldval.Value ;
            case 'double'
                if iscolumn(fieldval.Value)
                    printval = uq_sprintf_mat(fieldval.Value') ;
                elseif isrow(fieldval.Value)
                    printval = uq_sprintf_mat(fieldval.Value) ;
                else
                    printval = ['\n', uq_sprintf_mat(fieldval.Value)] ;
                end
            case 'logical'
                printval = num2str(fieldval.Value) ;
            otherwise
                printval = '<not printed>';
        end
        if fieldval.Invalid
            msg = sprintf('Invalid value set at: .Optim.%s! Using the default instead: %s\n',...
                optreqFields{ii}, printval);
            EVT.Type = 'W';
            EVT.Message = msg;
            EVT.eventID = sprintf('uqlab:rbdo:init:optoptions_override_%i', ...
                ii);
            uq_logEvent(current_analysis, EVT);
        end
        if fieldval.Missing
            msg = sprintf('The default value for .Optim.%s is used: %s\n',...
                optreqFields{ii}, printval);
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = sprintf('uqlab:rbdo:init:optoptions_defaultsub_%i', ...
                ii);
            uq_logEvent(current_analysis, EVT);
        end
        
        % set the value
        Internal.Optim.(optreqFields{ii}) = fieldval.Value ;
    end
    
    % Bounds of the optimization algorithms - Handled separately
    [bounds, Options.Optim] = uq_process_option( ...
        Options.Optim, 'Bounds');
    if bounds.Invalid
        error('Invalid bound setting\n') ;
    end
    if bounds.Missing
        error('The bounds of the search space must be set\n');
    end
    % Assign default values
    Internal.Optim.Bounds = bounds.Value ;
    if size(bounds.Value,1) ~= 2
        error('The bounds should contain exactly two rows (lower and upper values)\n') ;
    end
    if size(bounds.Value,2) == 1 && M_d > 1
        % Repeat the same bounds in all directions
        Internal.Optim.Bounds = repmat(bound.Value,1,M_d) ;
    end
    if size(bounds.Value,2) > 1 && size(bounds.Value,2) ~= M_d
        error('The bounds is not consistent with the design variables\n');
    end
    
    % Starting point
    [x0opt, Options.Optim] = uq_process_option( ...
        Options.Optim, 'StartingPoint');
    % Check for inconsistencies and assign value
    if x0opt.Missing
        %Set initial point as center of the search space
        Internal.Optim.StartingPoint = (Internal.Optim.Bounds(1,:) + ...
            Internal.Optim.Bounds(2,:) ) / 2 ;
    elseif x0opt.Invalid
        %Set initial point as center of the search space
        fprintf('\nWarning: Invalid starting point: The default value is set as the center of the search space') ;
        Internal.Optim.StartingPoint = (Internal.Optim.Bounds(1,:) + ...
            Internal.Optim.Bounds(2,:) ) / 2 ;
    else
        Internal.Optim.StartingPoint = x0opt.Value ;
    end
    if size(Internal.Optim.StartingPoint,1) > 1
        error('The starting point should be a scalar or a vector with only one row\n') ;
    end
    if length(Internal.Optim.StartingPoint) ==  1 && M_d > 1
        % Replicate the value over all directions
        Internal.Optim.StartingPoint = ...
            repmat(Internal.Optim.StartingPoint,1,M_d) ;
    end
    if length(Internal.Optim.StartingPoint) >  1 && ...
            length(Internal.Optim.StartingPoint) ~= M_d
        error('The dimension of the starting points is inconsistent with the number of design variables\n') ;
    end
    
    % Try to parse optimization method-specific options
    optMethod = upper(Internal.Optim.Method);
    if isfield(Options.Optim, upper(optMethod))
        
        % Some options have been set by the user
        for ii = 1 : length(optmethreqFields)
            [fieldval, Options.Optim.(upper(optMethod))] = uq_process_option(Options.Optim.(upper(optMethod)), ...
                optmethreqFields{ii},...
                OptimDefaults_Method.(upper(optMethod)).(optmethreqFields{ii}), ...
                OptimFieldsDatatypes.(upper(optmethreqFields{ii})));
            switch lower(class(fieldval.Value))
                case 'char'
                    printval = fieldval.Value ;
                case 'double'
                    printval = uq_sprintf_mat(fieldval.Value, '%i') ;
                case 'logical'
                    if fieldval.Value
                        printval = 'true';
                    else
                        printval = 'false';
                    end
                case 'function_handle'
                    printval = func2str(fieldval.Value);
                otherwise
                    printval = '<not printed>';
            end
            if fieldval.Invalid
                msg = sprintf('Invalid value set at: .Optim.%s.%s! Using the default instead: %s\n',...
                    optMethod, optmethreqFields{ii}, printval);
                EVT.Type = 'W';
                EVT.Message = msg;
                EVT.eventID = sprintf('uqlab:rbdo:init:optmethoptions_override_%i', ...
                    ii);
                uq_logEvent(current_analysis, EVT);
            end
            if fieldval.Missing
                msg = sprintf('The default value for .Optim.%s.%s is used: %s\n',...
                    optMethod, optmethreqFields{ii}, printval);
                EVT.Type = 'D';
                EVT.Message = msg;
                EVT.eventID = sprintf('uqlab:rbdo:init:optmethoptions_defaultsub_%i', ...
                    ii);
                uq_logEvent(current_analysis, EVT);
            end
            % set the value
            Internal.Optim.(upper(optMethod)). ...
                (optmethreqFields{ii}) = fieldval.Value ;
        end
        
        
        % Check for leftover options inside Options.Optim.(upper(optMethod))
        uq_options_remainder(Options.Optim.(upper(optMethod)), ...
            sprintf(' RBDO Optim.%s options.', optMethod));
        % Remove Options.Optim.(upper(optMethod))
        Options.Optim = rmfield(Options.Optim, optMethod);
        
    else % No Options.Optim have been set by the user
        % For optMethod = 'none' nothing should happen here
        if ~isempty(OptimDefaults_Method.(...
                upper(Internal.Optim.Method)))
            msg = sprintf('The default values for .Optim.%s are used:\n',...
                upper(Internal.Optim.Method));
            
            methdefaults = fieldnames(OptimDefaults_Method.(...
                upper(Internal.Optim.Method)));
            
            for jj = 1 : length(methdefaults)
                switch class(OptimDefaults_Method.(upper(optMethod)). ...
                        (methdefaults{jj}))
                    case 'double'
                        msg = [msg, ...
                            sprintf(' %s : %s\n', methdefaults{jj},...
                            num2str(OptimDefaults_Method.(upper(optMethod)). ...
                            (methdefaults{jj})))];
                    case 'char'
                        msg = [msg, ...
                            sprintf(' %s : %s\n', methdefaults{jj},...
                            OptimDefaults_Method.(upper(optMethod)). ...
                            (methdefaults{jj}))];
                    otherwise
                        msg = [msg, ...
                            sprintf(' %s : %s\n', methdefaults{jj},...
                            ['<',class(methdefaults{jj}),'>'])];
                end
            end
            % Log the default substitution event
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = sprintf('uqlab:rbdo:init:optimsome_defaultsub');
            uq_logEvent(current_analysis, EVT);
            
            % No options have been set. Set the defaults
            Internal.Optim.(...
                upper(Internal.Optim.Method))...
                = OptimDefaults_Method.(...
                upper(Internal.Optim.Method));
        end
    end
    
    %% 7. PARSE GLOBAL DISPLAY LEVEL
    % Get the global verbosity level
    DisplayLevel = Internal.Display;
    
    [opt, Options.Optim] = uq_process_option(Options.Optim, 'Display', [], 'char');
    Internal.Optim.Display = opt.Value ;
    % If Optim.Display is not manually set update it based on the global
    % verbosity level
    if ~isempty(Internal.Optim.Display) && ~any(strcmpi(Internal.Optim.Display,{'none','iter','final'}))
        fprintf('Warning: Display Optim option invalid or missing. Using global verbosity level\n');
        switch lower(DisplayLevel)
            case 0
                Internal.Optim.Display = 'none';
            case 1
                Internal.Optim.Display = 'final';
            case 2
                Internal.Optim.Display = 'iter';
        end
    end
    if isempty(Internal.Optim.Display)
        % Silently assigns global verbosity level
        switch lower(DisplayLevel)
            case 0
                Internal.Optim.Display = 'none';
            case 1
                Internal.Optim.Display = 'final';
            case 2
                Internal.Optim.Display = 'iter';
        end
    end
else
    error('Optim options field is empty!') ;
end

%% Augmented space
if ~isfield(Options, 'AugSpace')
    Options.AugSpace = struct ;
end
[opt, Options] = uq_process_option(Options, ...
    'AugmentedSpace', DefAugSpace, 'struct') ;
AugmentedSpace = opt.Value ;

% Process the fields of Augmented space
% - Method
[opt, AugmentedSpace] = uq_process_option(AugmentedSpace, 'Method', ...
    DefAugSpace.Method, {'char','string'}) ;

% Make sur ethat the given option exist. Otherwise set the default value
if ~any(strcmpi(opt.Value, {'hypercube','hybrid'}))
    warning('Only ''hypercube'' and ''hybrid'' are recognized as augmented space methods!');
    opt.Value = DefAugSpace.Method ;
end
AugmentedSpace.Method = opt.Value ;
% - DesAlpha:
[opt, AugmentedSpace] = uq_process_option(AugmentedSpace, 'DesAlpha', ...
    DefAugSpace.DesAlpha, 'double') ;

AugmentedSpace.DesAlpha = opt.Value ;

% - EnvVar:
[opt, AugmentedSpace] = uq_process_option(AugmentedSpace, 'EnvAlpha', ...
    DefAugSpace.EnvAlpha, 'double') ;

AugmentedSpace.EnvAlpha = opt.Value ;

% Augmented space processing finishing now:
Internal.AugSpace = AugmentedSpace ;


%% Parse the filtered internal options
current_analysis.Internal = Internal;

%% Define and build models

%% 1. COST FUNCTION
% Make sure that some kind of model source is given
isMFILE = isfield(Options.Cost, 'mFile') && ~isempty(Options.Cost.mFile) ;
isMSTRING = isfield(Options.Cost, 'mString') && ~isempty(Options.Cost.mString) ;
isMHANDLE = isfield(Options.Cost, 'mHandle') && ~isempty(Options.Cost.mHandle) ;
isMODEL = isfield(Options.Cost, 'Model') && ~isempty(Options.Cost.Model) ;

if isMFILE + isMSTRING + isMHANDLE + isMODEL > 1
    error('Multiple cost function definitions found!');
end

if isMFILE + isMSTRING + isMHANDLE + isMODEL < 1
    error('The cost property mFile, or mString or mHandle or Model needs to be defined!')
else
    
    % Process the input
    if isMFILE
        [optCost, Options.Cost] = uq_process_option(Options.Cost, 'mFile') ;
        current_analysis.Internal.Cost.Options.mFile = optCost.Value ;
    elseif isMSTRING
        [optCost, Options.Cost] = uq_process_option(Options.Cost, 'mString') ;
        current_analysis.Internal.Cost.Options.mString = optCost.Value ;
    elseif isMHANDLE
        [optCost, Options.Cost] = uq_process_option(Options.Cost, 'mHandle') ;
        current_analysis.Internal.Cost.Options.mHandle = optCost.Value ;
    elseif isMODEL
        [optCost, Options.Cost] = uq_process_option(Options.Cost, 'Model') ;
        current_analysis.Internal.Cost.Options.Model = optCost.Value ;
    end
    
    % Create and/or parse the model object
    if isMODEL
        % The user gave a model object. Make sure that the model is of type
        % default_model, UQLink or Metamodel
        if ~isa(uq_getModel(current_analysis.Internal.Cost.Options.Model),'uq_default_model') &&...
                ~isa(uq_getModel(current_analysis.Internal.Cost.Options.Model),'uq_uqlink') && ...
                ~isa(uq_getModel(current_analysis.Internal.Cost.Options.Model),'uq_metamodel')
            error('Error: The given MODEL object for the cost is not a recognized MODEL object (default_model, metamodel or uq_link)!') ;
        end
        % Model is recognized: Parse it.
        current_analysis.Internal.Cost.Model =  current_analysis.Internal.Cost.Options.Model ;
    else
        % Check if optional default_model options are given and parse them
        if isfield (Options.Cost, 'Parameters')
            [optCost, Options.Cost] = uq_process_option(Options.Cost, 'Parameters') ;
            current_analysis.Internal.Cost.Options.Parameters = optCost.Value ;
        end
        if isfield (Options.Cost, 'isVectorized')
            [optCost, Options.Cost] = uq_process_option(Options.Cost, 'isVectorized') ;
            current_analysis.Internal.Cost.Options.isVectorized = optCost.Value ;
        end
        % Create the default_model
        current_analysis.Internal.Cost.Model = ...
            uq_createModel(current_analysis.Internal.Cost.Options, '-private') ;
    end
end

%% LIMI-STATE / HARD CONSTRAINT options
if ~isfield(Options, 'LimitState')
    error('A computational model needs to be defined!') ;
end
% a. Hard constraints
[optCons, Options.LimitState] = uq_process_option(Options.LimitState, 'Model');
current_analysis.Internal.LimitState.Model = uq_getModel(optCons.Value) ;
if ~isa(uq_getModel(current_analysis.Internal.LimitState.Model),'uq_default_model') &&...
        ~isa(uq_getModel(current_analysis.Internal.LimitState.Model),'uq_model') && ...
        ~isa(uq_getModel(current_analysis.Internal.LimitState.Model),'uq_uqlink') && ...
        ~isa(uq_getModel(current_analysis.Internal.LimitState.Model),'uq_metamodel')
    error('The computational model given for the limit-state is not a recognized MODEL object (default_model, metamodel or uq_link)!') ;
end

% Mapping of the parameters
PMapDef.Type = '' ;
PMapDef.Index = [] ;
[opt, Options.LimitState] = uq_process_option(Options.LimitState, 'PMap', PMapDef, 'struct');
PMap = opt.Value;

% Process the parameters mapping option:
% - Threshold:
[opt, PMap] = uq_process_option(PMap, 'Type', {}, 'char');
PMap.Type = opt.Value;

% - Comparison option (CompOp):
[opt, PMap] = uq_process_option(PMap, 'Index', [], 'double');
PMap.Index = opt.Value ;

% Check consistency of the PMAp fields
if length(PMap.Type) ~= length(PMap.Index) 
    error('The PMap.Index and PMap.Type should have the same size!');
end

% PMap finished processing now:
current_analysis.Internal.LimitState.PMap = PMap;

% Map the model
if ~isempty(PMap.Index)
% Now get all the pmaps
idx_env = strfind(lower(PMap.Type), 'e') ;
%Now renumber everything assuming the input model is concatenating design 
% then environmental variables: W = [X(D),Z]
pMapAll = PMap.Index ;
pMapAll(:,idx_env) = pMapAll(:,idx_env) + M_d ;

% Now create a new MODEL object that wraps things up
WrapOpts.mFile = 'uq_eval_LS_RBDOWrapper' ;
WrapOpts.Parameters.Model = current_analysis.Internal.LimitState.Model ;
WrapOpts.Parameters.PMap = pMapAll ;
current_analysis.Internal.LimitState.MappedModel = uq_createModel( ...
    WrapOpts, '-private') ;
else
    % If no mapping is given, it is assumed that by default th
    % ecomputationl model takes the design then the environmental variables
    % in the given order as input - No mapping needed
 current_analysis.Internal.LimitState.MappedModel = ...
     current_analysis.Internal.LimitState.Model ;
end

% Process the fields of LimitState:
% - Threshold:
[opt, Options.LimitState] = uq_process_option(Options.LimitState, 'Threshold', 0, 'double');
current_analysis.Internal.LimitState.Threshold = opt.Value;

% - Comparison option (CompOp):
[opt, Options.LimitState] = uq_process_option(Options.LimitState, 'CompOp', '<=', 'char');
switch opt.Value
    case {'<', '<=', 'leq', '>', '>=', 'geq'}
        current_analysis.Internal.LimitState.CompOp = opt.Value;
    otherwise
        current_analysis.Internal.LimitState.CompOp = opt.Default;
end

% Corresponding options for the QMC method TargetAlpha & CompOp
if any( strcmpi(current_analysis.Internal.LimitState.CompOp, {'<', '<=', 'leq'}) )
    current_analysis.Internal.Runtime.TargetAlpha = current_analysis.Internal.TargetPf ;
    current_analysis.Internal.Runtime.CompOp = 'geq' ;
else
    current_analysis.Internal.Runtime.TargetAlpha = 1 - current_analysis.Internal.TargetPf ;
    current_analysis.Internal.Runtime.CompOp = 'leq' ;
end

%% SOFT CONSTRAINTS
% Make sure that some kind of model source is given
if isfield(Options,'SoftConstraints')
    isMFILE = isfield(Options.SoftConstraints, 'mFile') && ~isempty(Options.SoftConstraints.mFile) ;
    isMSTRING = isfield(Options.SoftConstraints, 'mString') && ~isempty(Options.SoftConstraints.mString) ;
    isMHANDLE = isfield(Options.SoftConstraints, 'mHandle') && ~isempty(Options.SoftConstraints.mHandle) ;
    isMODEL = isfield(Options.SoftConstraints, 'Model') && ~isempty(Options.SoftConstraints.Model) ;
    
    if isMFILE + isMSTRING + isMHANDLE + isMODEL > 1
        error('Multiple soft constraint functions definitions found!');
    end
    
    % Process the input
    if isMFILE
        [optConstraint, Options.SoftConstraints] = uq_process_option(Options.SoftConstraints, 'mFile') ;
        current_analysis.Internal.SoftConstraints.Options.mFile = optConstraint.Value ;
    elseif isMSTRING
        [optConstraint, Options.SoftConstraints] = uq_process_option(Options.SoftConstraints, 'mString') ;
        current_analysis.Internal.SoftConstraints.Options.mString = optConstraint.Value ;
    elseif isMHANDLE
        [optConstraint, Options.SoftConstraints] = uq_process_option(Options.SoftConstraints, 'mHandle') ;
        current_analysis.Internal.SoftConstraints.Options.mHandle = optConstraint.Value ;
    elseif isMODEL
        [optConstraint, Options.SoftConstraints] = uq_process_option(Options.SoftConstraints, 'Model') ;
        current_analysis.Internal.SoftConstraints.Options.Model = optConstraint.Value ;
    end
    
    % Create and/or parse the model object
    if isMODEL
        % The user gave a model object. Make sure that the model is of type
        % default_model, UQLink or Metamodel
        if ~isa(uq_getModel(current_analysis.Internal.SoftConstraints.Options.Model),'uq_default_model') &&...
                ~isa(uq_getModel(current_analysis.Internal.SoftConstraints.Options.Model),'uq_uqlink') && ...
                ~isa(uq_getModel(current_analysis.Internal.SoftConstraints.Options.Model),'uq_metamodel')
            error('Error: The given MODEL object for the soft constraint is not a recognized MODEL object (default_model, metamodel or uq_link)!') ;
        end 
        current_analysis.Internal.SoftConstraints.SoftConstModel = ...
            current_analysis.Internal.SoftConstraints.Options.Model ;
    else
        % Check if optional default_model options are given and parse them
        if isfield (Options.SoftConstraints, 'Parameters')
            [optConstraints, Options.SoftConstraints] = uq_process_option(Options.SoftConstraints, 'Parameters') ;
            current_analysis.Internal.SoftConstraints.Options.Parameters = optConstraints.Value ;
        end
        if isfield (Options.SoftConstraints, 'isVectorized')
            [optConstraints, Options.SoftConstraints] = uq_process_option(Options.SoftConstraints, 'isVectorized') ;
            current_analysis.Internal.SoftConstraints.Options.isVectorized = optConstraints.Value ;
        end
        % Create the default_model
        current_analysis.Internal.Constraints.SoftConstModel = ...
            uq_createModel(current_analysis.Internal.SoftConstraints.Options) ;
    end
else
    % Do nothing - Soft constraints are optional
end

%% Metamodel options, if any
% By default assume no active learning
current_analysis.Internal.Runtime.AL = false ;

if isfield(Options, 'Metamodel') && ~isempty(Options.Metamodel)
        current_analysis.Internal.Runtime.Metamodel = true  ; 
else  
%     Options.Metamodel = struct ;
    current_analysis.Internal.Runtime.Metamodel = false ;
end

if current_analysis.Internal.Runtime.Metamodel
    
    %% Parse Metamodel type
    [opt, Options.Metamodel] = uq_process_option(Options.Metamodel, 'Type', {'char','string'});
    if ~any(strcmpi(opt.Value, KnownMetamodels))
        error('Metamodel type is unknown\n') ;
    else
        current_analysis.Internal.Metamodel.Type = opt.Value ;
    end
    
    switch lower(current_analysis.Internal.Metamodel.Type)
        case 'kriging'
            current_analysis.Internal.Metamodel.Type = 'Kriging' ;
            
        case 'pce'
            current_analysis.Internal.Metamodel.Type = 'PCE' ;
            
        case 'pck'
            current_analysis.Internal.Metamodel.Type = 'PCK' ;
            
        case 'lra'
            current_analysis.Internal.Metamodel.Type = 'LRA' ;
            
        case 'svr'
            current_analysis.Internal.Metamodel.Type = 'SVR' ;
            
        case 'svc' % Normally shouldn't use SVC in the module
            current_analysis.Internal.Metamodel.Type = 'SVC' ;
    end
    
    %% Parse Metamodel options
    [opt, Options.Metamodel] = uq_process_option(Options.Metamodel, ...
        current_analysis.Internal.Metamodel.Type, 'struct');
    if opt.Missing
        error('Options corresponding to the selected metamodel type should be given!');
    elseif opt.Invalid
        error('Invalid Metamodel option!');
    end
    current_analysis.Internal.Metamodel.(current_analysis.Internal.Metamodel.Type) = opt.Value ;
    
    
%% Enrichment options

if isfield(Options.Metamodel, 'Enrichment')
    % For enrichment a metamodel is need. Check that a metamodel has been defined
    if ~isfield(current_analysis.Internal.Metamodel, 'Type') || ...
            isempty(current_analysis.Internal.Metamodel.Type)
        error('Enrichmennt is defined but no metamodel has been selected.');
    end
    % Flag that active metamodlling is used
    current_analysis.Internal.Runtime.AL = true ;
    
    % Set some default values, which depend on the metamodel type
    if isfield(current_analysis.Internal.Metamodel,'Type')
        % Normally should be the only possible case if enrichment is made
        switch lower(current_analysis.Internal.Metamodel.Type)
            case {'kriging','pck'}
                DEFAULTENRICH.LF = 'U' ;
                DEFAULTENRICH.Conv = 'stopPf' ;
            case 'pce'
                DEFAULTENRICH.LF = 'FBR' ;
                DEFAULTENRICH.Conv = 'StopDf' ;
            case {'svr','lra'}
                DEFAULTENRICH.LF = 'CMM' ;
                DEFAULTENRICH.Conv = 'StopDf' ;
            case 'svc'
                % not implemented yet
            otherwise
                error(' A metamodel type needs to be selected for enrichment!' );
        end
%     else
%         error(' A metamodel type needs to be selected for enrichment!' );
    end
    % 1. Enrichment type
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'Type', DEFAULTENRICH.Type, {'char','string'});
    current_analysis.Internal.Metamodel.Enrichment.Type  = opt.Value ;
    % Check that the chosen type exists...
    
    
    % 2. Number of samples to add per iteration
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'Points', DEFAULTENRICH.NSamplesToAddPerIter, {'double'});
    current_analysis.Internal.Metamodel.Enrichment.Points  = opt.Value ;
    
    % 3. Learning function
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'LearningFunction', DEFAULTENRICH.LF, {'char','string'});
    current_analysis.Internal.Metamodel.Enrichment.LearningFunction  = opt.Value ;
    
    % 4. Convergence criterion
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'Convergence', DEFAULTENRICH.Conv, {'char','string','cell'});
    if ~iscell(opt.Value)
        opt.Value = {opt.Value} ;
    end
    current_analysis.Internal.Metamodel.Enrichment.Convergence  = opt.Value ;

    % 5. Convergence threshold
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'ConvThreshold', DEFAULTENRICH.ConvThreshold, {'double'});
    current_analysis.Internal.Metamodel.Enrichment.ConvThreshold  = opt.Value ;
    
    % 6. Maximum points to add
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'MaxAdded', DEFAULTENRICH.MaxAddedPoints, {'double'});
    current_analysis.Internal.Metamodel.Enrichment.MaxAdded  = opt.Value ;
    if opt.Missing || opt.Invalid
        fprintf('Warning: Maximum number of enrichment points is set to %s.\n', DEFAULTENRICH.MaxAddedPoints ) ;
        current_analysis.Internal.Metamodel.Enrichment.MaxAdded = DEFAULTENRICH.MaxAddedPoints ;
    end
    
    % 7. Sampling method
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'Sampling', DEFAULTENRICH.Sampling, {'char','string'});
    current_analysis.Internal.Metamodel.Enrichment.Sampling  = opt.Value ;
    
    % 8. Batch Size
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'SampleSize', DEFAULTENRICH.BatchSize, {'double'});
    current_analysis.Internal.Metamodel.Enrichment.SampleSize  = opt.Value ;
    
    % 9. PC-bootstrap specific option: Number of replication
    if strcmpi(current_analysis.Internal.Metamodel.Enrichment.LearningFunction,'fbr')
        [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'BootstrapRep', DEFAULTENRICH.BR, {'double'});
        current_analysis.Internal.Metamodel.Enrichment.BootstrapRep  = opt.Value ;
    end
    
    % 9.b Multiple constraints
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'MOStrategy', DEFAULTENRICH.MOStrategy, {'char','string'});
    if ~any(strcmpi(opt.Value,{'max','mean','oat'}))
        fprintf('The selected multi-output strategy is unknwon. Using default value instead.\n');
        opt.Value = DEFAULTENRICH.MOStrategy ;
    end
    current_analysis.Internal.Metamodel.Enrichment.MOStrategy  = opt.Value ;
    
    % 10. Coupled optim-enrichment specific method
    
    % 10.1  Number of maximum points to add locally
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'LocalMaxAdded', DEFAULTENRICH.LocalMaxAdded, {'double'});
    current_analysis.Internal.Metamodel.Enrichment.LocalMaxAdded = opt.Value ;
    
    % 10.2 Number of points of points to add in parallell
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'LocalNPoints', DEFAULTENRICH.LocalNPoints, {'double'});
    current_analysis.Internal.Metamodel.Enrichment.LocalNPoints = opt.Value ;
    
    % 10.3 Accuracy critetion threshold: (beta+ - beta-)/beta < eps
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'LocalConvThreshold', DEFAULTENRICH.LocalConvThreshold, {'double'});
    current_analysis.Internal.Metamodel.Enrichment.LocalConvThreshold  = opt.Value ;

    % 10.4 When to try enrichment
    [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'LocalTryEnr', DEFAULTENRICH.LocalTryEnr, {'double','integer'});
    current_analysis.Internal.Metamodel.Enrichment.LocalTryEnr = opt.Value ;    

        % 10.4 When to try enrichment
        [opt, Options.Metamodel.Enrichment] = uq_process_option(Options.Metamodel.Enrichment, 'LocalRestart', DEFAULTENRICH.LocalRetsart, {'logical','double'});
        current_analysis.Internal.Metamodel.Enrichment.LocalRestart = opt.Value ;
        
        current_analysis.Internal.Runtime.LocalEnrichConv = [] ;
end

%% Build the models and the metamodel


%% Build the augmented space
uq_buildAugmentedSpace( current_analysis ) ;

%% Build the metamodel
if current_analysis.Internal.Runtime.AL
    % Build adaptively the metamodel according to the enrichment scheme
    uq_activeMetamodel( current_analysis );
else
    % No enrichment, just build the surrogate model
    uq_buildInitialMetamodel( current_analysis ) ;
end
else
    % Use the full model as default model, if no metamodel is defined
    current_analysis.Internal.Constraints.Model = ...
        current_analysis.Internal.LimitState.MappedModel ;
end

%% Run the RBDO analysis
uq_runAnalysis(current_analysis);

% Return success if everything went smoothly
success = 1 ;
end


%% Helper functions for the (SVR) SVR initialization
% (To be moved elsewhere)

function sout = merge_structures(varargin)
%MERGE_STRUCTURES merges structure variables given that there are no
%overlap on their fields

% collect the names of the fields
fnames = [];
for k = 1:nargin
    try
        fnames = [fnames ; fieldnames(varargin{k})];
    catch
        % do nothing
    end
end

% Make sure the field names are unique
if numel(fnames) ~= numel(unique(fnames))
    error('Internal RBDO initialization error: Field names must be unique!');
end

% Now concatenate the data from each structure into a cell array
cellarr = {};
for k = 1:nargin
    cellarr = [cellarr ; struct2cell(varargin{k})];
end

% transform the concatenated data from cell to struct
sout = cell2struct(cellarr, fnames, 1);
end


function msg = printfields(S, tabs)
% PRINTFIELDS prints the names of the fields of a structure depending on their data
% type
if nargin < 2
    tabs = '';
end
msg = '';
fnames = fieldnames(S);
for jj = 1 : length(fnames)
    switch class(S.(fnames{jj}))
        case 'char'
            msg_new = sprintf('%s %s : %s\n', tabs, fnames{jj}, ...
                S.(fnames{jj})) ;
        case 'double'
            msg_new = sprintf('%s %s : %s\n', tabs, fnames{jj}, ...
                uq_sprintf_mat(S.(fnames{jj}))) ;
        case 'struct'
            msg_new = sprintf('%s %s(contents) : \n', tabs, fnames{jj});
            tabs = sprintf('%s\t',tabs);
            msg_new = [msg_new, printfields(S.(fnames{jj}), tabs)] ;
            tabs = '';
        otherwise
            msg_new = sprintf('%s %s : %s\n', tabs, fnames{jj}, ...
                '<not printed>') ;
    end
    msg = [msg, msg_new];
end

end
