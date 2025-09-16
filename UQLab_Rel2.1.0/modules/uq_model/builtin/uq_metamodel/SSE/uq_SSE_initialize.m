function success = uq_SSE_initialize(currentModel)
% UQ_SSE_INITIALIZE initializes an SSE metamodel in UQLab by going through 
%   the user specified and default options.
%
%   See also: 

%% Success
success = 0;

%% Defaults

% option fields that should be ignored by the option parser. THEY WILL BE
% REMOVED FROM THE PROCESSED OPTIONS!!
IGNORE_OPTIONS = {'Type', 'MetaType', 'Name', 'FullModel', 'Display', 'Input','ValidationSet','ExpDesign'};

% Expansion
ExpOptionsDefaults.Type = 'Metamodel';
ExpOptionsDefaults.MetaType = 'PCE';
ExpOptionsDefaults.Method = 'LARS';
ExpOptionsDefaults.Degree = 0:4;
ExpOptionsDefaults.Display = 0;

% Stopping
StoppingDefaults.MaxRefine = 1000;
StoppingDefaults.Criterion = @(obj) false;

% Refinement
RefineDefaults.Score  = @(obj, subIdx) uq_SSE_refineScore_LOO(obj, subIdx);
RefineDefaults.Threshold  = -inf;
RefineDefaults.NExp = 10;

% Post Expansion Action
PostExpansionDefaults = @(obj, nodeIdx) obj.Graph.Nodes;

% Partitioning
PartitioningDefaults = @(obj, subIdx) uq_SSE_partitioning_Sobol(obj, subIdx);

% Post processing
PostProcessingDefaults.Flatten = false;
PostProcessingDefaults.OutputMoments = false;

%% Options
% User options
Options = currentModel.Options;

%% Input
if ~isfield(Options,'Input') ||...
        (~isa(Options.Input,'uq_input') &&...
        ~ischar(Options.Input) )
    currentModel.Internal.Input = uq_getInput;
    if isempty(currentModel.Internal.Input)
        error('Error: the specified input does not seem to be either a string nor a recognized object!')
    end
else
    currentModel.Internal.Input = uq_getInput(Options.Input);
end    

%% Make sure that the constant inputs are correctly dealt with
% Book-keeping of non-constant variables
% Find the non-constant variables
[NonConstInput, nonConstIdx, constInput, constIdx] = ...
    uq_remove_constants_from_input(currentModel.Internal.Input,'-private');
MnonConst = numel(nonConstIdx);

% Store the non-constant variables
currentModel.Internal.Runtime.MnonConst = MnonConst;
currentModel.Internal.Runtime.nonConstIdx = nonConstIdx;
currentModel.Internal.Runtime.constIdx = constIdx;
if ~isempty(constInput)
    currentModel.Internal.Runtime.constVal = [constInput.Marginals.Parameters];
end
currentModel.Internal.NonConstInput = NonConstInput;

% Remove constants from ExpDesign
if isfield(currentModel.ExpDesign,'X') && size(currentModel.ExpDesign.X,2) > MnonConst
    % remove constants
    currentModel.ExpDesign.X = currentModel.ExpDesign.X(:,nonConstIdx);
end
if isfield(currentModel.ExpDesign,'U') && size(currentModel.ExpDesign.U,2) > MnonConst
    % remove constants
    currentModel.ExpDesign.U = currentModel.ExpDesign.U(:,nonConstIdx);
end

%% Refinement
[Refine, Options] = uq_process_option(Options, 'Refine', RefineDefaults);
if Refine.Invalid
    error('The Refine field must be a structure!')
else
    currentModel.Internal.SSE.Refine = Refine.Value;
end

% For sequential ED, abort if NExp is larger than NEnrich
if strcmpi(currentModel.ExpDesign.Sampling, 'sequential')
    NExp = currentModel.Internal.SSE.Refine.NExp;
    NEnrich = currentModel.ExpDesign.NEnrich;
    if NExp > NEnrich
        error('For sequential experimental designs, NExp needs to be smaller than or equal to NEnrich for the algorithm to construct an initial expansion.')
    end
end

%% Post Expansion
[PostExpansion, Options] = uq_process_option(Options, 'PostExpansion', PostExpansionDefaults);
if PostExpansion.Invalid
    error('The PostExpansion field must be a structure!')
else
    currentModel.Internal.SSE.PostExpansion = PostExpansion.Value;
end

%% Partitioning
[Partitioning, Options] = uq_process_option(Options, 'Partitioning', PartitioningDefaults);
if Partitioning.Invalid
    error('The Partitioning field must be a structure!')
else
    currentModel.Internal.SSE.Partitioning = Partitioning.Value;
end

%% Expansion
[ExpOptions, Options] = uq_process_option(Options, 'ExpOptions', ExpOptionsDefaults);
if ExpOptions.Invalid
    error('The ExpOptions field must be a structure!')
else
    if ~strcmpi(ExpOptions.Value.MetaType,'pce')
        error('Only PCE residual expansions are currently supported.')
    end
    % assign to options
    currentModel.Internal.SSE.ExpOptions = ExpOptions.Value;
end

%% Post processing
[PostProcessing, Options] = uq_process_option(Options, 'PostProcessing', PostProcessingDefaults);
if PostProcessing.Invalid
    error('The PostProcessing field must be a structure!')
else
    if PostProcessing.Value.Flatten && ~PostProcessing.Value.OutputMoments && strcmpi(currentModel.Internal.SSE.ExpOptions.MetaType,'pce')
        % just turn on output moments
        PostProcessing.Value.OutputMoments = true;
    elseif PostProcessing.Value.OutputMoments && ~PostProcessing.Value.Flatten
        % warn and then turn on flattening because it might take some time
        fprintf('\nWarning: Flattened representation necessary for requested\n         output moments, turning it on!\n\n')
        PostProcessing.Value.Flatten = true;
    end     
    % OutputMoments are only available for PCE expansions
    if PostProcessing.Value.OutputMoments && ~strcmpi(currentModel.Internal.SSE.ExpOptions.MetaType,'pce')
        error('Output moments can only be computed with PCEs')
    end  
    % OutputMoments are only available for independent inputs
    if PostProcessing.Value.OutputMoments && ~strcmpi(currentModel.Internal.Input.Copula.Type,'independent')
        error('Output moments can only be computed for independent inputs')
    end
    % assign to options    
    currentModel.Internal.SSE.PostProcessing = PostProcessing.Value;
end

%% Stopping
[Stopping, Options] = uq_process_option(Options, 'Stopping', StoppingDefaults);
if Stopping.Invalid
    error('The Stopping field must be a structure!')
else
    currentModel.Internal.SSE.Stopping = Stopping.Value;
end

currentModel.Internal.SSE.Stopping.NSamples = currentModel.ExpDesign.NSamples;    

%% Graph
% initialize graph
initBounds = [zeros(1, MnonConst);ones(1, MnonConst)];
initGraph = digraph();     
initGraph = addnode(initGraph, 1);
initGraph.Nodes.neighbours = cell(1);
initGraph.Nodes.bounds = {initBounds};
initGraph.Nodes.inputMass = uq_SSE_volume(initBounds);
initGraph.Nodes.ref = 0;
initGraph.Nodes.level = 0;
initGraph.Nodes.idx = 1;
initGraph.Nodes.expansions = cell(1,0);

% store in currentModel
currentModel.Internal.SSE.Graph = initGraph;

%% final checks and return values
% Check if any field was not recognized here.
uq_options_remainder(Options, currentModel.Name, IGNORE_OPTIONS, currentModel);

% success
success = 1;

% log events
EVT.Type = 'II';
EVT.Message = 'Metamodel initialized correctly';
EVT.eventID = 'uqlab:metamodel:SSE_initialized';
uq_logEvent(currentModel, EVT);
end