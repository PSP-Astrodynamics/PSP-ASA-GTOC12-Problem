function success = uq_SVC_initialize( current_model )
%SUCCESS = UQ_SVC_INITIALIZE(SVCMODEL): Initialize a SVC model based on
%user-specified options.

success = 0;

M = current_model.Internal.Runtime.M;

uq_retrieveSession;

%% UNPROCESSED FIELDS
skipFields = {'Type','Name','MetaType','Input','FullModel','ExpDesign', 'Display', 'ValidationSet'};

%% DEFAULT VALUES
% ExpDesign (TEMPORARY)
ScalingDefaults = 1 ;
keepCache = 1; %flag to keep the cached matrices after the metamodel has been calculated

% QP problem
%alpha computation
QPSolverDefault = 'IP';
PenalDefault = 'linear';
Alpha_CutOffDefault = 1e-6;
knownQPSolvers = {'IP', 'interior-point', 'qpc', 'smo', 'isda'} ;
knownPenalty = {'linear','quadratic'} ;

% Kernel
KernelDefaults.Handle = @uq_eval_Kernel ;
KernelDefaults.Family = 'Gaussian' ;
KernelDefaults.Isotropic = true ;
KernelDefaults.Type = 'ellipsoidal' ;
% KernelDefaults.Nugget = 0 ; % Nugget should not be initialized for SVM but is added as the kernel lbrary needs it (Kriging).

% Estimation method
EstMethodDefaults.EstimMethod = 'SpanLOO' ;
EstMethodDefaults.CV.Folds = 3 ;
EstMethodDefaults.SmoothLOO.eta = 0.1 ; % Same as in Chang and Lin (2005) or Chapelle et al. (2002)

% Hyperparameters default: NaN means the default values will be set up once the ED is known
HyperparamDefault.C = 10 ;
HyperparamDefault.theta = NaN ;
HyperparamDefault.polyorder = 2 ;
% Optimization
OptimFieldsDatatypes.MAXFUNEVALS = 'double';
OptimFieldsDatatypes.NUMSTARTPOINTS = 'double';
OptimFieldsDatatypes.NLM = 'double';
OptimFieldsDatatypes.NPOP = 'double';
OptimFieldsDatatypes.NSTALL = 'double';
OptimFieldsDatatypes.QELITE = 'double';
OptimFieldsDatatypes.TOLFUN = 'double';
OptimFieldsDatatypes.SIGMA = 'double';
OptimFieldsDatatypes.ALPHA = 'double';
OptimFieldsDatatypes.BETA = 'double';
OptimFieldsDatatypes.Q = 'double';
OptimFieldsDatatypes.PARENTNUMBER = 'double';
OptimFieldsDatatypes.MAXITER = 'double';
OptimFieldsDatatypes.TOL = 'double';
OptimFieldsDatatypes.TOLX = 'double';
OptimFieldsDatatypes.TOLSIGMA = 'double';
OptimFieldsDatatypes.FVALMIN = 'double';
OptimFieldsDatatypes.INITIALVALUE = 'double';
OptimFieldsDatatypes.BOUNDS = 'double';
OptimFieldsDatatypes.DISPLAY = 'char';
OptimFieldsDatatypes.DISCPOINTS = 'double';

% Known optimization methods
OptimKnownMethods = {'None','CE','CMAES','GS', 'BFGS', 'GA'} ;
% Known optimization methods with respect to toolbox
OptimKnownOptimToolboxMethods = {'LBFGS','BFGS','HGA','HCE','HCMAES'} ;
OptimKnownGlobalOptimToolboxMethods = 'GA' ;
OptimKnownOptimAndGlobalToolboxMethods = 'HGA' ;

% Required field for each method:
% NOTE: The required fields for the SPECIFIC method are set below in OptimDefaults_Method
OptimReqFields.NONE = {};
OptimReqFields.GA   = {'MaxIter', 'Tol', 'Display'} ;
OptimReqFields.CMAES   = {'MaxIter', 'Tol', 'Display'} ;
OptimReqFields.CE   = {'MaxIter', 'Tol', 'Display'} ;
OptimReqFields.GS   = {'Display'} ;
OptimReqFields.BFGS   = {'MaxIter', 'Tol', 'Display'} ;

% Method-specific default values
% None
OptimDefaults_Method.NONE = [];
% BFGS related options
OptimDefaults_Method.BFGS.nLM = 5;
OptimDefaults_Method.BFGS.NumStartPoints = 1;
% GA related options
OptimDefaults_Method.GA.nPop =  NaN ;
OptimDefaults_Method.GA.nStall = 2;
% CE related options
OptimDefaults_Method.CE.nPop = 50 ;
OptimDefaults_Method.CE.qElite = 0.05 ;
OptimDefaults_Method.CE.TolFun = 1e-2 ;
OptimDefaults_Method.CE.TolSigma = 1e-2 ;
OptimDefaults_Method.CE.nStall = 2 ;
OptimDefaults_Method.CE.sigma = [NaN NaN NaN] ; % aussi provisoire - Should be computed again once the true values of the bounds are set!!!
OptimDefaults_Method.CE.alpha = 0.4 ;
OptimDefaults_Method.CE.beta = 0.4 ;
OptimDefaults_Method.CE.q = 10 ;
% CMAES related options
OptimDefaults_Method.CMAES.nPop =  NaN;
OptimDefaults_Method.CMAES.ParentNumber = NaN ;
OptimDefaults_Method.CMAES.sigma = [NaN NaN NaN] ; % aussi provisoire - Should be computed again once the true values of the bounds are set!!!
OptimDefaults_Method.CMAES.TolFun = 1e-2 ;
OptimDefaults_Method.CMAES.TolX = 1e-2 ;
OptimDefaults_Method.CMAES.FvalMin = 0 ;
OptimDefaults_Method.CMAES.nStall = NaN ;
% GS related options
OptimDefaults_Method.GS.DiscPoints = 5;

% Default values when nothing is set by the user
OptimDefaults.InitialValue.C = NaN ;
OptimDefaults.InitialValue.epsilon = NaN ;
OptimDefaults.InitialValue.theta = NaN ;

OptimDefaults.Method = 'CMAES';
OptimDefaults.MaxIter = 10 ;
OptimDefaults.Display = 'none' ;
OptimDefaults.Tol = 1e-2 ;



% Bounds of the optimization
minC = 2^(0) ;
maxC = 2^16 ;
minTheta = NaN ;
maxTheta = NaN ;
OptimDefaults.Bounds.C  = [ minC ; maxC ] ;
OptimDefaults.Bounds.theta = [ minTheta ; maxTheta ] ;
% Bounds for specific kernels
BoundsPolyKernel = [1e-3; 10] ;
BoundsSigmoidKernel = [1e-3 -5; 10 0] ;
BoundsUserDefinedKernel = [0.1;5];

% Calibrarion of some parameters
OptimDefaults.Calibrate.C = true ;
OptimDefaults.Calibrate.theta = true ;

%% RETRIEVE THE OPTIONS AND PARSE THEM
Options = current_model.Options;

%% PARSE GLOBAL DISPLAY LEVEL
% Get the global verbosity level
% DisplayLevel = current_model.Internal.Display ;
DisplayLevel = current_model.Internal.Display;

% If Optim.Display is not manually set update it based on the global
% verbosity level
OptimDisplay_EXISTS = isfield(Options, 'Optim') && isfield(Options.Optim, 'Display') &&...
    ~isempty(Options.Optim.Display);
OptimMethod_NONE = isfield(Options, 'Optim') && isfield(Options.Optim, 'Method') &&...
    ~isempty(Options.Optim.Method) && ...
    strcmpi(Options.Optim.Method, 'none');

switch lower(DisplayLevel)
    case 0
        if ~OptimDisplay_EXISTS && ~OptimMethod_NONE
            Options.Optim.Display = 'none';
        end
    case 1
        if ~OptimDisplay_EXISTS && ~OptimMethod_NONE
            Options.Optim.Display = 'final';
        end
    case 2
        if ~OptimDisplay_EXISTS && ~OptimMethod_NONE
            Options.Optim.Display = 'iter';
        end
    otherwise
        EVT.Type = 'W';
        EVT.Message = sprintf('Unknown display option: %s. Using the default value instead.', ...
            num2str(DisplayLevel));
        EVT.eventID = 'uqlab:metamodel:kriging:init:display_invalid';
        uq_logEvent(current_model, EVT);
        % Set the default display level
        DisplayLevel = 1;
end

%% METATYPE
% Meta Type
if ~isfield(Options, 'MetaType') || isempty(Options.MetaType)
    error('MetaType must be specified.');
end
uq_addprop(current_model, 'MetaType', Options.MetaType);
uq_addprop(current_model, 'Internal');

%% INPUT 
% Check whether an INPUT object has been defined
INPUT_EXISTS = false;
if isfield(Options, 'Input') && ~isempty(Options.Input)
    switch class(Options.Input)
        case {'uq_input', 'char'}
            current_model.Internal.Input = uq_getInput(Options.Input);
        case 'struct'
            current_model.Internal.Input = Options.Input;
        otherwise
            error('Unexpected data type of specified input object!');
    end
    INPUT_EXISTS = true;
end
% When an input module is specified it can be due to one (or more) of the
% following reasons:
% - An experimental design needs to be generated according to the
% probability distribution of the INPUT
% - A special type of scaling needs to take place (by isoprobabilistic
% transform)
if INPUT_EXISTS
    if any(strcmpi(current_model.ExpDesign.Sampling, {'user', 'data'}))
        % do a consistency check of the input dimension
        if length(current_model.Internal.Input.Marginals) ~= ...
                size(current_model.ExpDesign.X, 2)
            error('Input dimension inconsistency!')
        end
    end
end

%%
% Handle constants
if INPUT_EXISTS
    % Check non-constant variables
    if isprop(current_model.Internal.Input, 'nonConst') && ~isempty(current_model.Internal.Input.nonConst)
        nonConst = current_model.Internal.Input.nonConst;
    else
        %  find the constant marginals
        Types = {current_model.Internal.Input.Marginals(:).Type}; % 1x3 cell array of types
        % get all the marginals that are non-constant
        nonConst =  find(~strcmpi(Types, 'constant'));
    end
    
else
    current_model.Internal.ExpDesign.muX = mean(current_model.ExpDesign.X);
    current_model.Internal.ExpDesign.sigmaX = std(current_model.ExpDesign.X);
    nonConst = find(current_model.Internal.ExpDesign.sigmaX ~= 0);
end

% Store the non-constant variables
current_model.Internal.Runtime.MnonConst = numel(nonConst);
current_model.Internal.Runtime.nonConstIdx = nonConst;

%% SCALING (Auxiliary space)
% The struct case is included for the case of having a user defined
% auxiliary space (not yet implemented!)
[scale, Options] = uq_process_option(Options, 'Scaling',...
    ScalingDefaults, {'struct','logical','double', 'uq_input'});
if scale.Invalid
    EVT.Type = 'W';
    EVT.Message = 'The Scaling option was invalid. Using the default value instead.';
    EVT.eventID = 'uqlab:metamodel:SVC:init:scaling_invalid';
    uq_logEvent(current_model, EVT);
end
if scale.Missing
    EVT.Type = 'D';
    EVT.Message = 'The Scaling option was missing. Assigning the default value.';
    EVT.eventID = 'uqlab:metamodel:SVC:init:scaling_missing';
    uq_logEvent(current_model, EVT);
end

% get and store the Scaling value
current_model.Internal.Scaling = scale.Value;
SCALING = scale.Value ;
SCALING_BOOL = isa(SCALING, 'double') || isa(SCALING, 'logical') || isa(SCALING, 'int');

if SCALING_BOOL && SCALING
    if INPUT_EXISTS
        % scale the data as U = (X - muX)/stdX where muX,stdX are computed from the specified input distribution
        input_moments = reshape([current_model.Internal.Input.Marginals(:).Moments],2,[]);
        current_model.Internal.ExpDesign.muX = input_moments(1,:); % mean
        current_model.Internal.ExpDesign.sigmaX = input_moments(2,:);% standard deviation
    else
        % scale the data as U = (X - muX)/stdX where muX,stdX are computed from the available data
        current_model.Internal.ExpDesign.muX = mean(current_model.ExpDesign.X);
        current_model.Internal.ExpDesign.sigmaX = std(current_model.ExpDesign.X);
    end
end

if ~SCALING_BOOL
    if ~INPUT_EXISTS
       error('An Input object needs to be specified for the scaling option selected!') 
    end
    if isa(SCALING, 'uq_input')
        % do nothing
    else
       current_model.Internal.Scaling = uq_createInput(SCALING, '-private');
    end
end

%% Keep cache? - This is not used in SVC as far as I know
[ckeep, Options] = uq_process_option(Options, 'KeepCache',...
    keepCache, {'logical','double'});
if ckeep.Invalid
    EVT.Type = 'W';
    EVT.Message = 'The KeepCache option was invalid. Using the default value instead.';
    EVT.eventID = 'uqlab:metamodel:kriging:init:keepcache_invalid';
    uq_logEvent(current_model, EVT);
end
if ckeep.Missing
    %do nothing, just silently assign the default value
end
current_model.Internal.KeepCache = ckeep.Value ;


%% Parse kernel function related options
if isfield(Options,'Kernel')
    % Some kernel related options have been set by the user so
    % parse them
    
    % check whether a non-default function handle is selected for
    % evaluating K:
    [evalKhandle, Options.Kernel] = ...
        uq_process_option(Options.Kernel, 'Handle',...
        KernelDefaults.Handle, 'function_handle');
    % just silently assign the default handle if the user has not specified
    % something
    if evalKhandle.Missing
        % do nothing
    end
    if evalKhandle.Invalid
        error('Invalid definition of Kernel function handle!')
    end
    % The rest of the options are only relevant to the default
    % evalK-handle. So only parse them in case the default handle is used:
    if strcmp(char(evalKhandle.Value),'uq_eval_Kernel')
        % first set the handle option
        current_model.Internal.SVC(1).Kernel.Handle = evalKhandle.Value ;

        % Kernel function *type*
        [ktype, Options.Kernel] = uq_process_option(Options.Kernel, 'Type',...
            KernelDefaults.Type, 'char');
        if ktype.Invalid
            error('Invalid definition of kernel function type!')
        end
        
        current_model.Internal.SVC(1).Kernel.Type = ktype.Value ;
        
        if ktype.Missing
            msg = sprintf('Kernel function type was set to : %s', ....
                current_model.Internal.SVC(1).Kernel.Type) ;
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = 'uqlab:metamodel:SVC:init:kerfuntype_defaultsub';
            uq_logEvent(current_model, EVT);
            
        end    
        
        % Kernel function *family* (it can be either a string for using
        % the built-in ones or a function handle for using a user-defined
        % one
        [kfamily, Options.Kernel] = uq_process_option(Options.Kernel, 'Family',...
            KernelDefaults.Family, {'char','function_handle'});
        if kfamily.Invalid
            error('Invalid definition of kernel function family!')
        end
        
        current_model.Internal.SVC(1).Kernel.Family = kfamily.Value ;
        if kfamily.Missing
            if strcmpi(class(kfamily.Value),'function_handle')
                msg = sprintf('Kernel function family was set to : %s', ....
                    func2str(current_model.Internal.SVC(1).Kernel.Family)) ;
            else
                msg = sprintf('Correlation family was set to : %s', ....
                    current_model.Internal.SVC(1).Kernel.Family) ;
            end
            EVT.Type = 'D';
            EVT.Message = msg;
            % This has to be set later!!!!!!
            EVT.eventID = 'uqlab:metamodel:SVC:init:kerfamtype_defaultsub';
            uq_logEvent(current_model, EVT);
        end
        
        % Isotropic
        [kisotropic, Options.Kernel] = uq_process_option(Options.Kernel, 'Isotropic',...
            KernelDefaults.Isotropic, {'double','logical'});
        if kisotropic.Invalid
            error('Invalid definition of kernel function''s Isotropic option!')
        end
        if any(strcmpi(kfamily.Value,{'linear_ns','polynomial','sigmoid'})) && kisotropic.Value == 0
            kisotropic.Value = 1 ;
            warning('The selected kernel cannot be chosen anistropic. Setting parameter to isotropy') ;
        end
        current_model.Internal.SVC(1).Kernel.Isotropic = logical(kisotropic.Value) ;
        
        if kisotropic.Missing
            if current_model.Internal.SVC(1).Kernel.Isotropic
                msg = sprintf('Kernel function is set to *Isotropic* (default)');
            else
                msg = sprintf('Kernel function is set to *Anisotropic* (default)');
            end
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = 'uqlab:metamodel:SVC:init:kerisotropy_defaultsub';
            uq_logEvent(current_model, EVT);
        end

%         [nuggetopts, Options.Corr] = uq_process_option(Options.Corr, 'Nugget',...
%             CorrDefaults.Nugget, {'double','struct'});
%         if nuggetopts.Invalid
%             error('Invalid Nugget definition!')
%         end
        current_model.Internal.SVC(1).Kernel.Nugget = 0 ;
        
        % Check for leftover options inside Options.Kernel
        uq_options_remainder(Options.Kernel, ...
            ' SVC Kernel function options(.Kernel field).');
    else
        % If some non-default evalR handle is used, treat all options that
        % are set within the Corr structure as correct and store them
        %
        EVT.Type = 'N';
        EVT.Message = sprintf('Using the user-defined function handle: %s',...
            char(evalKhandle.Value));
        EVT.eventID = 'uqlab:metamodel:SVC:init:kerhandle_custom';
        uq_logEvent(current_model, EVT);
        
        % all the options that were set by the user inside .Corr are stored
        current_model.Internal.SVC(1).Kernel = Options.Kernel;
        % make sure that the handle option is there
        current_model.Internal.SVC(1).Kernel.Handle = evalKhandle.Value ;
    end
    % Remove Options.Kernel
    Options = rmfield(Options,'Kernel');
else
    %Default substitution of all options related to the kernel
    %function
    msg = sprintf('The default kernel function options are used:\n%s',...
        printfields(KernelDefaults));
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:SVC:init:kerfun_defaultsub';
    uq_logEvent(current_model, EVT);
    
    % No kerneloptions have been selected so set the default values
    current_model.Internal.SVC(1).Kernel = KernelDefaults ;
    % Add the Nugget option (not accessible to the user)
    current_model.Internal.SVC(1).Kernel.Nugget = 0 ;
end
if isfield(current_model.Internal.SVC(1).Kernel, 'Family')
    if strcmpi(current_model.Internal.SVC(1).Kernel.Family,'linear_ns')
        HyperparamDefault.theta = [] ;
        OptimDefaults.Bounds.theta = [] ;
    elseif strcmpi(current_model.Internal.SVC(1).Kernel.Family,'polynomial')
        HyperparamDefault.theta = 1 ; % d= 1 
        OptimDefaults.Bounds.theta = BoundsPolyKernel ;
    elseif strcmpi(current_model.Internal.SVC(1).Kernel.Family,'sigmoid')
        HyperparamDefault.theta = [1 -1] ;
        OptimDefaults.Bounds.theta = BoundsSigmoidKernel ;
    else   % For rbf kernels: gaussian, matern 3/2 & 5/2, exponential
        % Do nothing, default value is the one set above
        % HyperparamDefault.theta = NaN ;
        % OptimDefaults.Bounds = [minC minEpsilon minTheta; maxC maxEpsilon
        % maxTheta] ;
    end
    current_model.Internal.Runtime.isStationary = ...
        strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'gaussian') ...
        || strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'matern-3_2') ...
        || strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'matern-5_2') ...
        || strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'exponential') ...
        || strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'linear') ;

else
    % Meaning it is a user-defined kernel
    % Assumes there is only one parameter for the kernel by default
    HyperparamDefault.theta = 1 ;
    OptimDefaults.Bounds.theta = BoundsUserDefinedKernel ;
    current_model.Internal.Runtime.isStationary = false ;
end

%% Hyperparameters values
%
if isfield(Options,'Hyperparameters')
    % Some hyperparameters options have been set by the user  so parse them
    % Check whether C is set
    [paramC, Options.Hyperparameters] = uq_process_option( ...
        Options.Hyperparameters, 'C',HyperparamDefault.C, {'double'});
    if paramC.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The Hyperparameter option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_invalid';
        uq_logEvent(current_model, EVT);
    end
    if paramC.Missing
        EVT.Type = 'D';
        EVT.Message = 'The Hyperparameters option was missing. Assigning the default (initial) values.';
        EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_missing';
        uq_logEvent(current_model, EVT);
    end
    % Assign default values
    current_model.Internal.SVC(1).Hyperparameters.C = paramC.Value ;
    
    % Check whether the kernel parameterss are set
    [paramKernel, Options.Hyperparameters] = uq_process_option( ...
        Options.Hyperparameters, 'theta',HyperparamDefault.theta, {'double'});
    if paramKernel.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The Hyperparameter option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_invalid';
        uq_logEvent(current_model, EVT);
    end
    if paramKernel.Missing
        EVT.Type = 'D';
        EVT.Message = 'The Hyperparameters option was missing. Assigning the default (initial) values.';
        EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_missing';
        uq_logEvent(current_model, EVT);
    end
    % Assign default values
    current_model.Internal.SVC(1).Hyperparameters.theta = paramKernel.Value ;
 
    % Check whether the kernel parameterss are set
    [ polyorder, Options.Hyperparameters] = uq_process_option( ...
        Options.Hyperparameters, 'polyorder',HyperparamDefault.polyorder, {'double'});
    if polyorder.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The Polynomial order option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_invalid';
        uq_logEvent(current_model, EVT);
    end
    if polyorder.Missing
        EVT.Type = 'D';
        EVT.Message = 'The polynomial order option was missing. Assigning the default value.';
        EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_missing';
        uq_logEvent(current_model, EVT);
    else
        if ~strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'polynomial')
            warning('SVC Initialization: The selected kernel is not polynomial. The given polynomial kernel degree(s) will be ignored!') ;
        end
    end
    % Assign default values
    current_model.Internal.SVC(1).Hyperparameters.polyorder = polyorder.Value ;
    
%     % If kernel is polynomial merge the parameters  in the same struct...
%     if isfield(current_model.Internal.SVC(1).Kernel, 'Family') && ...
%             strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'polynomial')
%       current_model.Internal.SVC(1).Hyperparameters.theta = [ ...
%           current_model.Internal.SVC(1).Hyperparameters.theta, ...
%           current_model.Internal.SVC(1).Hyperparameters.polyorder] ;
%     end
    
else
    [hyperparam, Options] = uq_process_option( ...
        Options,'Hyperparameters',HyperparamDefault, {struct'});
    if hyperparam.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The Hyperparameter option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_invalid';
        uq_logEvent(current_model, EVT);
    end
    if hyperparam.Missing
        EVT.Type = 'D';
        EVT.Message = 'The Hyperparameters option was missing. Assigning the default (initial) values.';
        EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_missing';
        uq_logEvent(current_model, EVT);
    end
    % Assign default values
    current_model.Internal.SVC(1).Hyperparameters = hyperparam.Value ;
    
%     % Merge kernel params and poly order in case of polynomial kernel
%     if isfield(current_model.Internal.SVC(1).Kernel, 'Family') && ...
%             strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'polynomial')
%         current_model.Internal.SVC(1).Hyperparameters.theta = [ ...
%             current_model.Internal.SVC(1).Hyperparameters.theta, ...
%             current_model.Internal.SVC(1).Hyperparameters.polyorder] ;
%     end
end

% Handle remaining options
if isfield(Options, 'Hyperparameters')
    % Check for leftover options inside Options.Trend
    uq_options_remainder(Options.Hyperparameters, ' SVC Hyperparameters default/initial values.');
    % Remove Options.Trend
    Options = rmfield(Options,'Hyperparameters');
end

% Post-process the kernel options (account for anisotropy)
if current_model.Internal.Runtime.isStationary
    % Check for anisotropy
    if isfield(current_model.Internal.SVC(1).Kernel,'Isotropic') ...
            && ~current_model.Internal.SVC(1).Kernel.Isotropic
        if length(current_model.Internal.SVC(1).Hyperparameters.theta) == 1
            % If anisotropic and only one parameter, replicate this
            % parameter to all dimensions
            current_model.Internal.SVC(1).Hyperparameters.theta = ...
                current_model.Internal.SVC(1).Hyperparameters.theta*ones(1,M);
        end
    end
end
% Check that proper number of parameters have been set for linear_ns and
% sigmoid kernels
if isfield(current_model.Internal.SVC(1).Kernel, 'Family')
    if strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'linear_ns') && ...
            ~isempty(current_model.Internal.SVC(1).Hyperparameters.theta)
        error('The non-stationary linear kernel should not have any parameter');
    end
    if strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'sigmoid') && ...
            length(current_model.Internal.SVC(1).Hyperparameters.theta) ~= 2
        error('The sigmoid kernel should have only one parameter');
    end
end

%% Optimization options
%% Parse Optimization-Related Options
if isfield(Options, 'Optim')
    % Optimization method
    [optimMethod, Options.Optim] = uq_process_option(Options.Optim, ...
        'Method',OptimDefaults.Method, 'char');
    if optimMethod.Invalid
        msg = sprintf('Invalid Optimization method. Using the default: %s instead.',...
            optimMethod.Value);
        EVT.Type = 'W';
        EVT.Message = msg;
        EVT.eventID = 'uqlab:metamodel:SVC:init:optmethod_override';
        uq_logEvent(current_model, EVT);
        
        current_model.Internal.SVC(1).Optim.Method = optimMethod.Value ;
    elseif optimMethod.Missing
        msg = sprintf('Using the default optimization method: %s.',...
            optimMethod.Value);
        EVT.Type = 'D';
        EVT.Message = msg;
        EVT.eventID = 'uqlab:metamodel:SVC:init:optmethod_defaultsub';
        uq_logEvent(current_model, EVT);
        current_model.Internal.SVC(1).Optim.Method = optimMethod.Value ;
    else
        %make sure that the selected method exists
        if any(strcmpi(OptimKnownMethods, optimMethod.Value))  
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
            if any(strcmpi(OptimKnownOptimToolboxMethods, optimMethod.Value))
                % 'BFGS', 'LBFGS' and 'HGA', 'HCE', 'HCMAES' all rely on the 'fmincon function which belongs to the Optimization toolbox
                if ~optimization_check
                    fprintf('The algorithm selected to calibrate the SVC model is not available\n');
                    fprintf('%s requires the Optimization toolbox which is not available\n',optimMethod.Value) ;
                    fprintf('Please select another algorithm or run custom SVC\n') ;
                    error('SVC initialization failed: No license for Optimization toolbox') ;
                end
            elseif any(strcmpi(OptimKnownGlobalOptimToolboxMethods,optimMethod.Value))
                % 'GA' reliwa on the ga function which belongs to the global optimization toolbox
                if ~goptimization_check
                    fprintf('The algorithm selected to calibrate the SVC model is not available\n');
                    fprintf('%s requires the Global Optimization toolbox which is not available\n',optimMethod.Value) ;
                    fprintf('Please select another algorithm or run custom SVC\n') ;
                    error('SVC initialization failed: No license for Global Optimization toolbox') ;
                end
            elseif any(strcmpi(OptimKnownOptimAndGlobalToolboxMethods,optimMethod.Value))
                % 'HGA' relies on ga and fmincon which belong respectively
                % to the Global Optimization toolbox and to the
                % Optimization toolbox
                if ~(optimization_check && goptimization_check)
                    toolbox_result = {'Available', '*Not Available*'};
                    fprintf('The algorithm selected to calibrate the SVC model is not available\n');
                    fprintf('\t Optimization toolbox: \t\t\t[%s]\n', toolbox_result{2-optimization_check}) ;
                    fprintf('\t Global Optimization toolbox: \t\t[%s]\n', toolbox_result{2-goptimization_check}) ;
                    fprintf('Please select another algorithm or run custom SVC\n') ;
                    error('SVC initialization failed: No license for Optimization toolbox and/or Global Optimization toolbox') ;
                end
            else
                % do nothing. Should fall here only if 'sade' is chosen or if the
                % 'OptimKnownMethods is extended
            end
            current_model.Internal.SVC.Optim.Method = optimMethod.Value ;

        else
            % If the selected method is unknown raise a warning and use the default
            msg = sprintf('Invalid Optimization method. Using the default: %s instead.',...
                OptimDefaults.Method);
            EVT.Type = 'W';
            EVT.Message = msg;
            EVT.eventID = 'uqlab:metamodel:SVC:init:optmethod_override';
            uq_logEvent(current_model, EVT);
            
            current_model.Internal.SVC.Optim.Method = ...
                OptimDefaults.Method ;
        end
    end
    
    % Get the required fields for the selected Optimization method
    optreqFields = OptimReqFields.(...
        upper(current_model.Internal.SVC.Optim.Method)) ;
    optmethreqFields = OptimDefaults_Method.(...
        upper(current_model.Internal.SVC.Optim.Method));
    
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
            EVT.eventID = sprintf('uqlab:metamodel:SVC:init:optoptions_override_%i', ...
                ii);
            uq_logEvent(current_model, EVT);
        end
        if fieldval.Missing
            msg = sprintf('The default value for .Optim.%s is used: %s\n',...
                optreqFields{ii}, printval);
            EVT.Type = 'D';
            EVT.Message = msg;
            EVT.eventID = sprintf('uqlab:metamodel:SVC:init:optoptions_defaultsub_%i', ...
                ii);
            uq_logEvent(current_model, EVT);
        end
        
        % set the value
        current_model.Internal.SVC.Optim.(optreqFields{ii}) = ...
            fieldval.Value ;
    end
    
    % Set parameters that need to be calibrated - By default all
    % hyperparameters will be calibrated
    if isfield(Options.Optim,'Calibrate')
        [calibrateC, Options.Optim.Calibrate] = uq_process_option( ...
            Options.Optim.Calibrate, 'C',OptimDefaults.Calibrate.C, {'logical','bool','double'});
        if calibrateC.Invalid
            EVT.Type = 'W';
            EVT.Message = 'The C calibration option was invalid. Using the default value instead.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:calibC_invalid';
            uq_logEvent(current_model, EVT);
        end
        if calibrateC.Missing
            EVT.Type = 'D';
            EVT.Message = 'The C calibration option was missing. Assigning the default values.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:calibC_missing';
            uq_logEvent(current_model, EVT);
        end
        current_model.Internal.SVC(1).Optim.Calibration.C = calibrateC.Value ;

        [calibrateKP, Options.Optim.Calibrate] = uq_process_option( ...
            Options.Optim.Calibrate, 'theta',OptimDefaults.Calibrate.theta, {'logical','bool','double'});
        if calibrateC.Invalid
            EVT.Type = 'W';
            EVT.Message = 'The kernel param calibration option was invalid. Using the default value instead.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:calibKP_invalid';
            uq_logEvent(current_model, EVT);
        end
        if calibrateC.Missing
            EVT.Type = 'D';
            EVT.Message = 'The kernel param calibration option was missing. Assigning the default values.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:calibKP_missing';
            uq_logEvent(current_model, EVT);
        end
        current_model.Internal.SVC(1).Optim.Calibration.theta = calibrateKP.Value ;
        
        % Now set a number that will represent the combination of
        % hyperparameters to optimize
        % 0 = None of the parameters , 1 = optimize C, 2 = optimize KP , 3
        % = optimize all (default)
        current_model.Internal.Runtime.CalibrateNo = calibrateC.Value * 2^0 + calibrateKP.Value * 2^1 ;
    else
        [calibrate, Options.Optim] = uq_process_option( ...
            Options.Optim, 'Calibrate',OptimDefaults.Calibrate, {'struct'});
        if calibrate.Invalid
            EVT.Type = 'W';
            EVT.Message = 'The Calibration option was invalid. Using the default value instead.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:calibration_invalid';
            uq_logEvent(current_model, EVT);
        end
        if calibrate.Missing
            EVT.Type = 'D';
            EVT.Message = 'The Calibration option was missing. Assigning the default values.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:calibration_missing';
            uq_logEvent(current_model, EVT);
        end
        current_model.Internal.SVC(1).Optim.Calibrate = calibrate.Value ;
        % Now set a number that will represent the combination of
        % hyperparameters to optimize
        % 0 = None of the parameters , 1 = optimize C, 2 = optimize KP , 3
        % = optimize all (default)
        current_model.Internal.Runtime.CalibrateNo = calibrate.Value.C * 2^0 + calibrate.Value.theta * 2^1 ;

    end
    
    % Bounds of the optimization algorithms - Handled separately
    if isfield(Options.Optim,'Bounds')
        [boundsC, Options.Optim.Bounds] = uq_process_option( ...
            Options.Optim.Bounds, 'C',OptimDefaults.Bounds.C, 'double');
        if boundsC.Invalid
            EVT.Type = 'W';
            EVT.Message = 'The Hyperparameter C bounds option was invalid. Using the default value instead.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_invalid';
            uq_logEvent(current_model, EVT);
        end
        if boundsC.Missing
            EVT.Type = 'D';
            EVT.Message = 'The Hyperparameters C bounds option was missing. Assigning the default values.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_missing';
            uq_logEvent(current_model, EVT);
            current_model.Internal.Runtime.UserGivenUpperC = false ;
        else
            current_model.Internal.Runtime.UserGivenUpperC = true ;
        end
        
        [boundsKP, Options.Optim.Bounds] = uq_process_option( ...
            Options.Optim.Bounds, 'theta',OptimDefaults.Bounds.theta, 'double');
        if boundsKP.Invalid
            EVT.Type = 'W';
            EVT.Message = 'The kernel parameters bounds option was invalid. Using the default value instead.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_invalid';
            uq_logEvent(current_model, EVT);
        end
        if boundsC.Missing
            EVT.Type = 'D';
            EVT.Message = 'The kernel parameters C bounds option was missing. Assigning the default values.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_missing';
            uq_logEvent(current_model, EVT);
        end
        
        % Now concatenate all the bounds into a single vector and in the same
        % time make sure the sub-strcutures in a runtime variable
        current_model.Internal.Runtime.Optim.Bounds.C = boundsC.Value ;
        current_model.Internal.Runtime.Optim.Bounds.theta = boundsKP.Value ;
        current_model.Internal.SVC(1).Optim.Bounds = [boundsC.Value, boundsKP.Value ] ;

    else
        
        [bounds, Options.Optim] = uq_process_option( ...
            Options.Optim, 'Bounds',OptimDefaults.Bounds, {'struct'});
        if bounds.Invalid
            EVT.Type = 'W';
            EVT.Message = 'The Bounds Optim option was invalid. Using the default value instead.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:optimbounds_invalid';
            uq_logEvent(current_model, EVT);
        end
        if bounds.Missing
            EVT.Type = 'D';
            EVT.Message = 'The Bounds Optim option was missing. Assigning the default values.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:optimbounds_missing';
            uq_logEvent(current_model, EVT);
        end
        % Now concatenate all the bounds into a single vector and in the same
        % time make sure the sub-strcutures in a runtime variable
        current_model.Internal.Runtime.Optim.Bounds.C = bounds.Value.C ;
        current_model.Internal.Runtime.Optim.Bounds.theta = bounds.Value.theta ;
        current_model.Internal.SVC(1).Optim.Bounds = [ bounds.Value.C, bounds.Value.theta ] ;
        
        % Specify that the user did not provide any value for C (This
        % information is needed in case the default upper C is changed
        % because of N_ED > 300)
        current_model.Internal.Runtime.UserGivenUpperC = false ;

    end
    

    
    if current_model.Internal.Runtime.isStationary
        % Check for anisotropy
        if isfield(current_model.Internal.SVC(1).Kernel,'Isotropic') ...
                && ~current_model.Internal.SVC(1).Kernel.Isotropic
            if size(current_model.Internal.Runtime.Optim.Bounds.theta,2) == 1
                % If anisotropic and only one parameter, replicate this
                % parameter to all dimensions
                boundsC =  current_model.Internal.SVC(1).Optim.Bounds(:,1) ;
                boundsSigma = repmat( current_model.Internal.SVC(1).Optim.Bounds(:,2),1,M) ;
                newbounds = [boundsC boundsSigma] ;
                current_model.Internal.SVC(1).Optim.Bounds = newbounds ;
            end
        end
    end
    
    if isfield(current_model.Internal.SVC(1).Kernel, 'Family')
        if strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'linear_ns') && ...
                length(current_model.Internal.SVC(1).Optim.Bounds(1,:))~= 1
            error('For the non-stationary linear kernel,the bounds should be of size 2x1');
        end
        if strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'sigmoid') && ...
                length(current_model.Internal.SVC(1).Optim.Bounds(1,:))~= 3
            error('For the sigmoid kernel,the kernel bounds should be of size 2x2');
        end
    end
    
    % InitialValue of the optimization algorithms - Handled separately
    if isfield(Options.Optim,'InitialValue')
        [InitialValueC, Options.Optim.InitialValue] = uq_process_option( ...
            Options.Optim.InitialValue, 'C',OptimDefaults.InitialValue.C, 'double');
        if InitialValueC.Invalid
            EVT.Type = 'W';
            EVT.Message = 'The Hyperparameter C InitialValue option was invalid. Using the default value instead.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_invalid';
            uq_logEvent(current_model, EVT);
        end
        if InitialValueC.Missing
            EVT.Type = 'D';
            EVT.Message = 'The Hyperparameters C InitialValue option was missing. Assigning the default values.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_missing';
            uq_logEvent(current_model, EVT);
        end
        current_model.Internal.SVC(1).Optim.InitialValue.C = InitialValueC.Value ;

        [InitialValueKP, Options.Optim.InitialValue] = uq_process_option( ...
            Options.Optim.InitialValue, 'theta',OptimDefaults.InitialValue.theta, 'double');
        if InitialValueKP.Invalid
            EVT.Type = 'W';
            EVT.Message = 'The kernel parameters InitialValue option was invalid. Using the default value instead.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_invalid';
            uq_logEvent(current_model, EVT);
        end
        if InitialValueKP.Missing
            EVT.Type = 'D';
            EVT.Message = 'The kernel parameters C InitialValue option was missing. Assigning the default values.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:hyperparam_missing';
            uq_logEvent(current_model, EVT);
        end
        current_model.Internal.SVC(1).Optim.InitialValue.theta = InitialValueKP.Value ;
        
    else
        [InitialValue, Options.Optim] = uq_process_option( ...
            Options.Optim, 'InitialValue',OptimDefaults.InitialValue, {'struct'});
        if InitialValue.Invalid
            EVT.Type = 'W';
            EVT.Message = 'The InitialValue Optim option was invalid. Using the default value instead.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:optimInitialValue_invalid';
            uq_logEvent(current_model, EVT);
        end
        if InitialValue.Missing
            EVT.Type = 'D';
            EVT.Message = 'The InitialValue Optim option was missing. Assigning the default values.';
            EVT.eventID = 'uqlab:metamodel:SVC:init:optimInitialValue_missing';
            uq_logEvent(current_model, EVT);
        end
        
        current_model.Internal.SVC(1).Optim.InitialValue = InitialValue.Value ;

    end
    
    % Now check that
    if current_model.Internal.Runtime.isStationary
        % Check for anisotropy
        if isfield(current_model.Internal.SVC(1).Kernel,'Isotropic') ...
                && ~current_model.Internal.SVC(1).Kernel.Isotropic
            if length(current_model.Internal.SVC(1).Optim.InitialValue.theta) == 1
                % If anisotropic and only one parameter, replicate this
                % parameter to all dimensions
                current_model.Internal.SVC(1).Optim.InitialValue.theta = ...
                    repmat(current_model.Internal.SVC(1).Optim.InitialValue.theta,1,M) ;
            end
        end
    end
    
    
    % Try to parse optimization method-specific options
    optMethod = upper(current_model.Internal.SVC.Optim.Method);
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
                EVT.eventID = sprintf('uqlab:metamodel:SVC:init:optmethoptions_override_%i', ...
                    ii);
                uq_logEvent(current_model, EVT);
            end
            if fieldval.Missing
                msg = sprintf('The default value for .Optim.%s.%s is used: %s\n',...
                    optMethod, optmethreqFields{ii}, printval);
                EVT.Type = 'D';
                EVT.Message = msg;
                EVT.eventID = sprintf('uqlab:metamodel:SVC:init:optmethoptions_defaultsub_%i', ...
                    ii);
                uq_logEvent(current_model, EVT);
            end
            % set the value
            current_model.Internal.SVC.Optim.(upper(optMethod)). ...
                (optmethreqFields{ii}) = fieldval.Value ;
        end
        
        
        % Check for leftover options inside Options.Optim.(upper(optMethod))
        uq_options_remainder(Options.Optim.(upper(optMethod)), ...
            sprintf(' SVC Optim.%s options.', optMethod));
        % Remove Options.Optim.(upper(optMethod))
        Options.Optim = rmfield(Options.Optim, optMethod);
        
    else % No Options.Optim have been set by the user
        % For optMethod = 'none' nothing should happen here
        if ~isempty(OptimDefaults_Method.(...
                upper(current_model.Internal.SVC.Optim.Method)))
            msg = sprintf('The default values for .Optim.%s are used:\n',...
                upper(current_model.Internal.SVC.Optim.Method));
            
            methdefaults = fieldnames(OptimDefaults_Method.(...
                upper(current_model.Internal.SVC.Optim.Method)));
            
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
            EVT.eventID = sprintf('uqlab:metamodel:SVC:init:optimsome_defaultsub');
            uq_logEvent(current_model, EVT);
            
            % No options have been set. Set the defaults
            current_model.Internal.SVC.Optim.(...
                upper(current_model.Internal.SVC.Optim.Method))...
                = OptimDefaults_Method.(...
                upper(current_model.Internal.SVC.Optim.Method));
        end
    end
    
    % Additional checks for some specific fields
    %     current_model = validateOptimOptions(current_model);
    if isfield(Options.Optim, 'InitialValue')
        Options.Optim = rmfield(Options.Optim, 'InitialValue');
    end
    if isfield(Options.Optim, 'Bounds')
        Options.Optim = rmfield(Options.Optim, 'Bounds');
    end
    if isfield(Options.Optim, 'Calibrate')
        Options.Optim = rmfield(Options.Optim, 'Calibrate');
    end    
    
    % Check for leftover options inside Options.Optim
    uq_options_remainder(Options.Optim, ' SVC Optim options.');
    % Remove Options.Optim
    Options = rmfield(Options, 'Optim');
    
else
    current_model.Internal.SVC.Optim = OptimDefaults ;
    % Additional checks for some specific fields
    %     current_model = validateOptimOptions(current_model);
    % No Optimization options have been selected so set the defaults
    msg = sprintf('The default values for .Optim are used:\n%s', ...
        printfields(current_model.Internal.SVC.Optim));
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = sprintf('uqlab:metamodel:SVC:init:optimall_defaultsub');
    uq_logEvent(current_model, EVT);
end

% Set optimization method to 'none' or 'polyonly' if the user sets
% off all calibration parameters
if current_model.Internal.Runtime.CalibrateNo == 0
    if ~strcmpi(optimMethod, 'none')
        if ~optimMethod.Missing
            warning('The calibration is set off for all parameters, the optimization algorithm is set to ''none''');
        end
        if strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'polynomial') ...
                && length(current_model.Internal.SVC(1).Hyperparameters.polyorder) > 1
            optimMethod.Value = 'polyonly' ;
        else
            optimMethod.Value = 'none' ;
        end
    end
else
    % Also set the optimization method to polyonly if there are multiple
    % polynomial orders while the chosen optim method by the user is none
    if isfield(current_model.Internal.SVC(1).Kernel, 'Family') && ...
            strcmpi(current_model.Internal.SVC(1).Kernel.Family, 'polynomial') ...
            && length(current_model.Internal.SVC(1).Hyperparameters.polyorder) > 1 ...
            && strcmpi(current_model.Internal.SVC(1).Optim.Method,'none')            
        optimMethod.Value = 'polyonly' ;
    end
end
% Update the optim method field in case it is updated...
current_model.Internal.SVC.Optim.Method = optimMethod.Value ;

%% Quadratic optimization problem
% QP solver
[optQPSolver, Options] = uq_process_option(Options, 'QPSolver', ...
    QPSolverDefault, 'char');
if optQPSolver.Invalid
    msg = sprintf('Invalid QP Solver. Using the default: %s instead.',...
        optQPSolver.Value);
    EVT.Type = 'W';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:svc:init:qpsolver_override';
    uq_logEvent(current_model, EVT);
end
if optQPSolver.Missing
    msg = sprintf('Using the default QP solver: %s.',...
        optQPSolver.Value);
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:svc:init:qpsolver_defaultsub';
    uq_logEvent(current_model, EVT);
    current_model.Internal.Runtime.UserGivenQPSolver = false ;
else
    current_model.Internal.Runtime.UserGivenQPSolver = true ;
end
if ~any(strcmpi(optQPSolver.Value, knownQPSolvers) )
    % The QP solvers should be interior-point or active set
    error('Unknown QP solver') ;
end
% Check that license exists if the user sets quadprog as optimization
% algorithm
if any(strcmpi(optQPSolver.Value, {'ip','as'}))
    try
        % Make sure that the optimization toolbox is avaialble
        evalc('x = fmincon(@(x)x.^2, 0.5, 1, 3);');
        optimization_check = true;
    catch
        optimization_check = false;
    end
    if ~optimization_check
        % Set warning only if the user expressly selected ip
        if ~optQPSolver.Missing
            fprintf('The algorithm selected to solve the SVM QP problem model is not available\n');
            fprintf('%s requires the Optimization toolbox which is not available\n',optQPSolver.Value) ;
            warning('Switching to ''SMO'' solver for the SVM QP problem') ;
        end
       optQPSolver.Value = 'smo' ;
    end
end

current_model.Internal.SVC(1).QPSolver = optQPSolver.Value ;


% Loss function
[optPenal, Options] = uq_process_option(Options, 'Penalization', PenalDefault, 'char');
if optPenal.Invalid
    msg = sprintf('Invalid penalization type. Using the default: %s instead.',...
        optPenal.Value);
    EVT.Type = 'W';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:SVC:init:penalty_override';
    uq_logEvent(current_model, EVT);
end
if optPenal.Missing
    msg = sprintf('Using the default loss function: %s.',...
        optPenal.Value);
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:SVC:init:loss_defaultsub';
    uq_logEvent(current_model, EVT);
    current_model.Internal.Runtime.UserGivenLoss = false ;
else
    current_model.Internal.Runtime.UserGivenLoss = true ;
end
if ~any(strcmpi(optPenal.Value, knownPenalty) )
    % The penalization type should be 'linear' or 'quadratic'
    error('Unknown penalization type') ;
end
if any(strcmpi(optQPSolver.Value, {'smo','isda','l1qp'})) && ...
        strcmpi(optPenal.Value, 'quadratic')
    % Issue a warning only if the user expressly selected a quadratic
    % penalization type
    if ~optPenal.Missing
        warning('''SMO'' and ''ISDA'' only apply to L1-SVC: The penalization type is switched to ''linear''') ;
    end
    optPenal.Value = 'linear' ;
end
    
current_model.Internal.SVC(1).Penalization = optPenal.Value ;


% Alpha cut-off (how to separate the vectors (Support, bounded, unbounded)
[optCutOff, Options] = uq_process_option(Options, 'Alpha_CutOff', ...
    Alpha_CutOffDefault, 'double');
if optCutOff.Invalid
    msg = sprintf('Invalid Alpha Cut-Off option. Using the default: %s instead.',...
        optCutOff.Value);
    EVT.Type = 'W';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:SVC:init:alphacutoff_override';
    uq_logEvent(current_model, EVT);
end
if optCutOff.Missing
    msg = sprintf('Using the default value of alpha cut-off: %s.',...
        optCutOff.Value);
    EVT.Type = 'D';
    EVT.Message = msg;
    EVT.eventID = 'uqlab:metamodel:SVC:init:alphacutoff_defaultsub';
    uq_logEvent(current_model, EVT);
end
current_model.Internal.SVC(1).Alpha_CutOff = optCutOff.Value ;

%% Parse  Estimation Method - related options
if isfield(Options, 'EstimMethod')
    % The Estimation method has been set by the user so parse the related
    % options
    [estmethod, Options] = uq_process_option(Options, 'EstimMethod',...
        EstMethodDefaults.EstimMethod, 'char');
    if estmethod.Invalid
        error('Invalid Hyperparameter estimation method!')
    end
    
    current_model.Internal.SVC(1).EstimMethod = estmethod.Value ;
    
    if estmethod.Missing
        msg = sprintf('Hyperparameters estimation method was set to : %s', ...
            current_model.Internal.SVC.EstimMethod) ;
        EVT.Type = 'D';
        EVT.Message = msg;
        EVT.eventID = 'uqlab:metamodel:SVC:init:estmethod_defaultsub';
        uq_logEvent(current_model, EVT);
    end
    
    switch lower(current_model.Internal.SVC.EstimMethod)
        % If method is CV make sure that K (is properly defined)
        case 'cv'
            [cvopts, Options] = uq_process_option(Options, 'CV',...
                EstMethodDefaults.CV, 'struct');
            
            if cvopts.Invalid
                error('Invalid Cross-Validation method options!')
            end
            current_model.Internal.SVC.CV = cvopts.Value ;
            % Make sure that Folds <= NSamples
            current_model.Internal.SVC.CV.Folds = min(current_model.Internal.SVC.CV.Folds,...
                current_model.ExpDesign.NSamples);
            if current_model.Internal.SVC.CV.Folds == 1
                error('For cross-validation, the number of folds should be larger than 1') ;
            end
            if cvopts.Missing
                msg = sprintf('Using Cross-Validation method, with: %i-fold (default).',...
                    current_model.Internal.SVC.CV.Folds);
                EVT.Type = 'D';
                EVT.Message = msg;
                EVT.eventID = 'uqlab:metamodel:SVC:init:estmethod_cvk_defaultsub';
                uq_logEvent(current_model, EVT);
            end
        case 'smoothloo'
            if isfield(Options, 'SmoothLOO')
                [smlooopts, Options.SmoothLOO] = uq_process_option(Options.SmoothLOO, 'eta',...
                    EstMethodDefaults.SmoothLOO.eta, 'double');
                if smlooopts.Invalid
                    msg = sprintf('Invalid eta option for smooth loo. Using the default: %s instead.',...
                        smlooopts.Value);
                    EVT.Type = 'W';
                    EVT.Message = msg;
                    EVT.eventID = 'uqlab:metamodel:SVC:init:smoothlooeta_override';
                    uq_logEvent(current_model, EVT);
                end
                if smlooopts.Missing
                    msg = sprintf('Using the default value of eta (smooth loo): %s.',...
                        optCutOff.Value);
                    EVT.Type = 'D';
                    EVT.Message = msg;
                    EVT.eventID = 'uqlab:metamodel:SVC:init:smoothlooeta_defaultsub';
                    uq_logEvent(current_model, EVT);
                end
                current_model.Internal.SVC(1).SmoothLOO.eta = smlooopts.Value ;
                
                Options = rmfield(Options,'SmoothLOO') ;
            else
                current_model.Internal.SVC(1).SmoothLOO = EstMethodDefaults.SmoothLOO ;
                % Additional checks for some specific fields
                %     current_model = validateOptimOptions(current_model);
                % No Optimization options have been selected so set the defaults
                msg = sprintf('The default values for .SmoothLOO are used:\n%s', ...
                    printfields(current_model.Internal.SVC.SmoothLOO));
                EVT.Type = 'D';
                EVT.Message = msg;
                EVT.eventID = sprintf('uqlab:metamodel:SVC:init:smoothlooeta_defaultsub');
                uq_logEvent(current_model, EVT);
            end
    end
else
    % No Estimation method has been set by the user so use the default
    % values
    current_model.Internal.SVC(1).EstimMethod = EstMethodDefaults.EstimMethod ;
end

%% Check for unused options
% Remove some fields that are not processed here:
fieldsToRemove = skipFields(isfield(Options,skipFields)) ;

Options = rmfield(Options, fieldsToRemove);

% Check if there was something else provided:
uq_options_remainder(Options, ...
    current_model.Name, ...
    skipFields, current_model);

%% Add the property where the main SVC results are stored
uq_addprop(current_model, 'SVC');
%% Initialization succesfully finished
success = 1;

end

%% Helper functions for the (SVC) SVC initialization
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
    error('Internal SVC initialization error: Field names must be unique!');
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