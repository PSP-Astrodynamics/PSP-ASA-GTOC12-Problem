function success = uq_LRA_initialize(current_model)
% Initialization for the LRA module.
% Handling of default values and consistency checks.

%% UNPROCESSED FIELDS
skipFields = {'Type','Name','MetaType','Input','FullModel','ExpDesign','Display'};

%% LARS
% lars defaults:
LARSDefaults.KeepIterations = false;
LARSDefaults.HybridLars = true;
LARSDefaults.ModifiedLoo = true;

%% Update and correction step defaults
UpdateStepDefaults.Method = 'OLS';
CorrStepDefaults.Method = 'OLS';
CorrStepDefaults.MinDerrStop = 1e-6;
CorrStepDefaults.MaxIterStop = 100;

GenErrorDefaults.Method = 'CV';
GenErrorDefaults.Parameters.NFolds = 3;

% Keep initialization messages. If user wants information on initialization
% 
init_message = {};

% Keep track of the original options:
Options = current_model.Options;

if isfield(Options,'GenError')
    GenError = Options.GenError;
else
    GenError = GenErrorDefaults;
end

%% Prepare Degree and Rank Selection and defaults:
% Check the computational method related options and set them to defaults
% if needed.

% RankSelection relevant options
% Methods/Options/early stop
if isfield (Options, 'RankSelection')
    % In case other methods than CV are implemented later, adjust
    % accordingly. Now if the parameters are skipped and the method is
    % simply CV the NFolds parameter will be 3.
    RankSelection = Options.RankSelection;
	
    % In case there is no display level specific to the rank selection, use
    % the global display level.
    if ~isfield(RankSelection,'Display')
        RankSelection.Display = current_model.Internal.Display;
    end
    
    if ~isfield(RankSelection,'Method')
        RankSelection.Method = GenError.Method;
        RankSelection.Parameters.NFolds = GenError.Parameters.NFolds;
    end
    
    if ~isfield(RankSelection,'Parameters') && ...
            strcmpi(RankSelection.Method,'CV')
        RankSelection.Parameters.NFolds = GenError.Parameters.NFolds;
    end
    
    if isfield(RankSelection,'Parameters') && ...
            rem(RankSelection.Parameters.NFolds,1) ~= 0 && ...
            length(RankSelection.Parameters.NFolds) ~= 1
        error('The CV parameter NFolds should be a single integer value.');
    end
    
    if ~isfield(RankSelection,'EarlyStop')
        RankSelection.EarlyStop = true;
    end
    
    if RankSelection.EarlyStop
        % This can be adjusted to allow for more general and advanced 
        % early stopping later.
        if isfield(RankSelection,'EarlyStopSteps')
            es_steps = RankSelection.EarlyStopSteps;
        else
            es_steps = 2;
        end
        RankSelection.EarlyStopFunction = @(errs) EarlyStopStepsFunction(errs,es_steps);
    end
else
    RankSelection = GenError;
	RankSelection.Display = current_model.Internal.Display;
    RankSelection.EarlyStop = true;
    RankSelection.EarlyStopFunction = @(errs) EarlyStopStepsFunction(errs,2);
end

% Options relevant to the degree selection:
% Criteria/Options for selection/early stop
if isfield (Options, 'DegSelection')
    
    DegSelection = Options.DegSelection;
    if ~isfield(DegSelection,'Display')
        DegSelection.Display = current_model.Internal.Display;
    end
    
    if ~isfield(DegSelection,'Method')
        DegSelection.Method = GenError.Method;
        DegSelection.Parameters.NFolds = GenError.Parameters.NFolds;
    end
    
    % Currently only the CV based degree selection is supported and it is
    % set by default. For future implementations adjust accordingly.    
    if ~isfield(DegSelection,'Parameters') && ...
            strcmpi(DegSelection.Method,'CV')
        DegSelection.Parameters.NFolds = GenError.Parameters.NFolds;
    end
    
    if ~isfield(DegSelection,'EarlyStop')
        DegSelection.EarlyStop = true;
    end
    
	if DegSelection.EarlyStop
        if isfield(DegSelection,'EarlyStopSteps')
            es_steps = DegSelection.EarlyStopSteps;
        else
            es_steps = 2;
        end
        DegSelection.EarlyStopFunction = @(errs) EarlyStopStepsFunction(errs,es_steps);
    end
else
    DegSelection = GenError;
    DegSelection.Display = current_model.Internal.Display;
    DegSelection.EarlyStop = true;
    DegSelection.EarlyStopFunction = @(errs) EarlyStopStepsFunction(errs,2);
end

%% Make sure that the constant inputs are correctly dealt with
% Book-keeping of non-constant variables
% INPUT
if ~isfield(Options,'Input') ||...
        (~isa(Options.Input,'uq_input') &&...
        ~ischar(Options.Input) )
    current_model.Internal.Input = uq_getInput;
    if isempty(current_model.Internal.Input)
        error('Error: the specified input does not seem to be either a string nor a recognized object!')
    end
else
    current_model.Internal.Input = uq_getInput(Options.Input);
end

% Find the non-constant variables
if isprop(current_model.Internal.Input, 'nonConst') && ~isempty(current_model.Internal.Input.nonConst)
    nonConst = current_model.Internal.Input.nonConst;
else
    %  find the constant marginals
    Types = {current_model.Internal.Input.Marginals(:).Type}; % 1x3 cell array of types
    % get all the marginals that are non-constant
    nonConst =  find(~strcmpi(Types, 'constant'));
end
% Store the non-constant variables
current_model.Internal.Runtime.MnonConst = numel(nonConst);
current_model.Internal.Runtime.nonConstIdx = nonConst;

% update quadrature defaults if M < 4
if length(current_model.Internal.Input.Marginals) < 4
   QuadratureDefaults.Type = 'Full';
end


%% Prepare the model for computation:
% Add a field where LRA computation results and some setup information will
% be stored:
uq_addprop(current_model, 'LRA');

%% Internal field
% The internal field will keep the computational method information in the
% .Method. It will also keep intermediate computation results (iterations
% for correction step and LARS steps if needed)
uq_addprop(current_model,'Internal')

%% INPUT
% Keep the Input also in the internal field
if ~isfield(Options,'Input') ||...
        (~isa(Options.Input,'uq_input') &&...
        ~ischar(Options.Input) )
    current_model.Internal.Input = uq_getInput;
    if isempty(current_model.Internal.Input)
        error('Error: the specified input does not seem to be neither a string nor a recognized object!')
    end
else
    current_model.Internal.Input = uq_getInput(Options.Input);
end

%% Manage basis defaults 
% Manage the required parameters for the basis (for example create the
% PolyTypesAB for 'Arbitrary' polynomials)
% current_model.Internal.Method = [];
[current_model, Options] = uq_initialize_uq_metamodel_univ_basis(current_model,Options);

%% Remove the constant variables from the inputs
UnivBasis = current_model.LRA.Basis;
nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
FNames = {'PolyTypes','PolyTypesParams','PolyTypesAB'};
for fn = 1:length(FNames)
    UnivBasis.(FNames{fn}) = UnivBasis.(FNames{fn})(nonConstIdx);
end

%% The regression method relevant options:
% it is either OLS or LARS. In case of LARS there should be an additional
% field LARS options. In case this field does not exist, throw a warning
% stating the defaults. In case the user did not provide anything for the
% correction step and the update step set some defaults.

[CorrStep,Options] = uq_process_option(Options, 'CorrStep',CorrStepDefaults,'struct');
[UpdateStep, Options] = uq_process_option(Options,'UpdateStep',UpdateStepDefaults,'struct');

if CorrStep.Invalid
    error('The provided .CorrStep was invalid. Please provide a field that contains .Method, .MinDerrStop, .MaxIterStop')
end

if UpdateStep.Invalid
    error('The provided .CorrStep was invalid. Please provide a field that contains .Method (OLS or LARS)')
end

if CorrStep.Missing && current_model.Internal.Display>2
        warning('The .CorrStep field was missing from the options. The defaults are chosen: Method = OLS, MinDerrStop = %2.1e, MaxIterStop = %2.1e',...
            CorrStepDefaults.MinDerrStop,...
            CorrStepDefaults.MaxIterStop);
end

if UpdateStep.Missing && current_model.Internal.Display>2
    warning('The .UpdateStep field was missing from the options. The defaults are chosen: Method = OLS.')
end

CorrStep = CorrStep.Value;
UpdateStep = UpdateStep.Value;

%% Manage LARS defaults where needed:
if strcmpi(CorrStep.Method ,'LARS')
    [LARS,CorrStep] = uq_process_option(CorrStep,'LARS',LARSDefaults,'struct');
    if LARS.Missing && current_model.Internal.Display>2
        warning('Using default LARS options for the correction step.');    
    end
    % This is to let the user simply specify 'LARS' and then uqlab will
    % perform LARS with the defaults.
    CorrStep.LARS = LARS.Value;
end

if strcmpi(UpdateStep.Method ,'LARS')
    [LARS,UpdateStep] = uq_process_option(UpdateStep,'LARS',LARSDefaults,'struct');
    if LARS.Missing && current_model.Internal.Display>2
        warning('Using default LARS options for the update step.');
    end
    UpdateStep.LARS = LARS.Value;
end


%% Adaptation options:
% Adaptation is based on a CV score. In order to allow for more
% flexibility for future implementations the rank and degree adaptation 
% functions are separated.
% 
% The rank and degree adaptation/selection function consists of two
% components:
%
% 1) A function handle that accepts an ED and an array of degrees/ranks
%
% 2) An 'Options' field that contains possible useful information for the
%    computation of the scores. The parameters include a handle to an
%    'EarlyStopFunction', 'ReportStep', 'ReportResults'

% RANK selection
switch RankSelection.Method
    case 'CV'
        
        % All options relevant to max rank selection with CV are set since
        % they are needed for the computation of the scores for different
        % ranks.
        
        % These are generic options for the method managed earlier in
        % initialization
        RankCVOpts = RankSelection;
        RankCVOpts.Degree = max(Options.Degree);
        RankCVOpts.CorrStep = CorrStep;
        RankCVOpts.UpdateStep = UpdateStep;
        RankCVOpts.UnivBasis = UnivBasis;
        RankCVOpts.Rank = Options.Rank;

        RankSelectionOptions.ScoreFunction = ...
            @(U ,Y , CVOpts) uq_LRA_CV(U ,Y , CVOpts);
        
        RankSelectionOptions.Options = RankCVOpts;
        
        RankSelectionOptions.Options.ReportStep = ...
            @(StepInfo)...
            fprintf('Rank %i - Degree %i CV score %5.2e \n',...
            StepInfo.Rank, StepInfo.p, StepInfo.CVScore);
        
        RankSelectionOptions.Options.ReportResults = ...
            @(DegSelectionResults) ...
            fprintf('%s rank %i with CV %5.2e \n',...
            DegSelectionResults.isSelected,...
            DegSelectionResults.Rank,...
            DegSelectionResults.CVScore);
        
        
    otherwise
        error('The requested rank selection method is not supported.')
end

% DEGREE selection
switch DegSelection.Method
    case 'CV'
        % These are generic options for the method managed earlier in
        % initialization
        DegreeCVOpts = DegSelection;
        
        % This is an array of degrees - if there was a single degree it
        % will be treated the same later in computation.
        DegreeCVOpts.Degree = Options.Degree;
        DegreeCVOpts.CorrStep = CorrStep;
        DegreeCVOpts.UpdateStep = UpdateStep;
        DegreeCVOpts.UnivBasis = UnivBasis;
        
        % To allow for more flexibility in the internal usage, the 
        % CVOptions are passed to the ScoreFunction when it is used.
        DegSelectionOptions.ScoreFunction = ...
            @(U ,Y , CVOpts) uq_LRA_CV(U ,Y , CVOpts);
        
        DegSelectionOptions.Options = DegreeCVOpts;
        
        % The DegSelectionOptions includes also reporting functions.
        DegSelectionOptions.Options.ReportResults = ...
            @(DegSelectionResults) ...
            fprintf('%s degree %i with CV %5.2e for rank %i \n\n',...
            DegSelectionResults.isSelected,...
            DegSelectionResults.Degree,...
            DegSelectionResults.CVScore,...
            DegSelectionResults.Rank);
        
        DegSelectionOptions.Options.ReportStep = @(StepInfo)...
            fprintf('Degree %i - cv score %5.7e for rank %i \n\n',...
            StepInfo.p, StepInfo.CVScore, StepInfo.Rank);
            
    otherwise
        error('The requested rank selection method is not supported.')
end

%% Rank and Degree adaptation strategy
% The combination of rank and degree adaptation is performed throught the 
% uq_LRA_adaptive_[method].m functions.
% 
SelectionStrategy.RankSelectionOpts = RankSelectionOptions;
SelectionStrategy.DegSelectionOpts = DegSelectionOptions;

if isfield(Options,'Adaptivity')
    SelectionStrategy.Method = Options.Adaptivity;
else
    SelectionStrategy.Method = 'all_d_adapt_r';
end

switch lower(SelectionStrategy.Method)
    case 'rank_first'
        SelectionStrategy.SelectionFunction = ...
            @(strat,U,Y) uq_LRA_adaptive_rank_first(strat,U,Y);
        
	case 'all_r_adapt_d'
        SelectionStrategy.SelectionFunction = ...
            @(strat,U,Y) uq_LRA_adaptive_all_r_adapt_d(strat,U,Y);
        
	case 'all_d_adapt_r'
        SelectionStrategy.SelectionFunction = ...
            @(strat,U,Y) uq_LRA_adaptive_all_d_adapt_r(strat,U,Y);
    case 'adapt_r_d'
        SelectionStrategy.SelectionFunction = ...
            @(strat,U,Y) uq_LRA_adaptive_grad(strat, U, Y);
        
    otherwise
    	error('The requested adaptive strategy for LRA does not exist.');
end


ComputationalOptions.SelectionStrategy = SelectionStrategy;

%% Preparation of final LRA computation options:
ComputationalOptions.FinalLRA.CorrStep = CorrStep;
ComputationalOptions.FinalLRA.UpdateStep = UpdateStep;

%% Store all the computational options in a field of the uq_model:
current_model.Internal.ComputationalOpts = ComputationalOptions;
current_model.Internal.ComputationalOpts.GenError = GenError;

%% Return success and log initialization event
success = 1;

EVT.Type = 'II';
EVT.Message = 'Metamodel initialized correctly';
EVT.eventID = 'uqlab:metamodel:LRA_initialized';
uq_logEvent(current_model, EVT);
end

function res = EarlyStopStepsFunction(errs,numsteps)
    % This checks that the last "numsteps" of the "errs" are increasing:
    if length(errs)<(numsteps+1)
        res = 0;
    else
        res = issorted(errs((end-numsteps):end));
    end
end
