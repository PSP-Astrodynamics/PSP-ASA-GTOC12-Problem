classdef sseClass
    % Value class for SSE construction
    
    properties
        isInitialised = false;
        currRef = 0;
        Input = [];     
        FullModel = [];
        ExpOptions = [];
        Refine = [];
        ExpDesign = [];
        Stopping = [];
        Partitioning = [];
        Runtime = [];
        Graph = [];
        FlatGraph = digraph();
        PostExpansion = [];
        Moments = [];
    end
    
    methods
        % Constructor
        function obj = sseClass(SSEProperties, Input, ExpDesign, FullModel, Runtime)
            % handle no input arguments
            if nargin == 0
                error('Default options are handled by uq_SSE_initialize')
            end
            
            % Input
            % Remove constants
            obj.Input.Original = Input;
            % address dependent inputs
            indepInpOpts.Marginals = rmfield(obj.Input.Original.Marginals,'Moments');
            indepInpOpts.Copula.Type = 'Independent';
            obj.Input.Independent = uq_createInput(indepInpOpts,'-private');
            % get dimension of problem
            obj.Input.Dim = length(obj.Input.Original.Marginals);
                                       
            % Expansion
            obj.ExpOptions = SSEProperties.ExpOptions;
            
            % Stopping
            obj.Stopping = SSEProperties.Stopping;
            
            % Partitioning
            obj.Partitioning = SSEProperties.Partitioning;
            
            % Refine
            obj.Refine = SSEProperties.Refine;
            
            % Post expansion
            obj.PostExpansion = SSEProperties.PostExpansion;

            % Runtime
            obj.Runtime = Runtime;
            obj.Runtime.absWREEvolution = [];
            obj.Runtime.relWREEvolution = [];
            obj.Runtime.termDomEvolution = [];
            obj.Runtime.continue = true;

            % Experimental design 
            obj.ExpDesign = ExpDesign;
            obj.ExpDesign.Res = obj.ExpDesign.Y;
            obj.ExpDesign.ref = zeros(size(obj.ExpDesign.Y));
            if strcmpi(obj.ExpDesign.Sampling,'Sequential')
                % enrichment, assign the full model
                obj.FullModel = FullModel;
            end            
            
            % Graph
            obj.Graph = SSEProperties.Graph;
            
            % is initialized true
            obj.isInitialised = true;
        end
        
        function obj = enrichExpDesign(obj, currBounds, nEnrich)
         % enrich the experimental design and store the new points
        [U_new, X_new] = obj.ExpDesign.Enrichment(obj, currBounds, nEnrich);

        % evaluate the actual model
        % add constants to X_new
        if obj.Runtime.MnonConst ~= obj.Runtime.M
            % add constants
            X_full(:,obj.Runtime.nonConstIdx) = X_new;
            X_full(:,obj.Runtime.constIdx) = obj.Runtime.constVal;
        else
            X_full = X_new;
        end
        Y_new = uq_evalModel(obj.FullModel, X_full);

        % compute residual Y_new by subtracting all previously created PCEs
        Res_new = Y_new - evalSSE(obj,X_new);

        % assemble output
        obj.ExpDesign.U = [obj.ExpDesign.U; U_new];
        obj.ExpDesign.X = [obj.ExpDesign.X;X_new];
        obj.ExpDesign.Res = [obj.ExpDesign.Res;Res_new];
        obj.ExpDesign.Y = [obj.ExpDesign.Y;Y_new];
        obj.ExpDesign.ref = [obj.ExpDesign.ref;ones(nEnrich,1)*obj.currRef];
        end
        
        function obj = refine(obj)
        % Refine the SSE     
        
        % find next refinement subdomain
        [obj, refineIdx, newDomains] = findRefinementSub(obj);
        
        % check if refinement domain has been found
        obj.Runtime.continue = evaluateStoppingCriteria(refineIdx);
        if obj.Runtime.continue
            if obj.currRef == 0
                % add baseline expansions
                fprintf('Building baseline %s...\n', obj.ExpOptions.MetaType)
            else
                % add next level of expansions
                fprintf('Refinement step %i...\n', obj.currRef)
            end

            % construct Expansions
            obj = constructExpansions(obj, refineIdx, newDomains);

            % get stopping metric
            [currAbsWREError, currTermDoms] = computeConvergenceError(obj);
            obj.Runtime.absWREEvolution = [obj.Runtime.absWREEvolution; currAbsWREError];
            obj.Runtime.termDomEvolution{end+1} = currTermDoms;
            % compute also relative error if global sampling
            if ~any(strcmpi(obj.ExpDesign.Sampling,{'sequential','user'}))
                currRelWRE = currAbsWREError/var(obj.ExpDesign.Y);
                obj.Runtime.relWREEvolution = [obj.Runtime.relWREEvolution; currRelWRE];
            end
            
            % check other stopping criteria
            obj.Runtime.continue = evaluateStoppingCriteria(obj);
            
            if obj.Runtime.continue
                % update current reference
                obj.currRef = obj.currRef + 1;
            end
        else
            % reduce currRef by one
            obj.currRef = obj.currRef - 1;
        end
        end
        
        function varargout = evalSSE(obj, X, varargin)
            % evaluate SSE at points X considering the maximum refinement
            % level to consider MAXREFINE and possibly inlcude only the DIM
            % dimensions
            if nargin > 2 && ~isempty(varargin)
                % vargin given
                parse_keys = {'maxrefine', 'vardim'};
                parse_types = {'p','p'};
                % make NAME lower case
                varargin(1:2:end) = lower(varargin(1:2:end));
                [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
            else
                % no vargin, use default options
                nOpts = 2;
                uq_cline = cell(nOpts,1);
                for ii = 1:nOpts
                    uq_cline{ii} = 'false';
                end
            end

            % 'maxRefine' option evaluates only until the specified
            % refinement level
            if ~strcmp(uq_cline{1}, 'false')
                maxRefine = uq_cline{1};
            else
                maxRefine = inf;
            end
            
            % 'varDim' option includes only the specified dimensions
            if ~strcmp(uq_cline{2}, 'false')
                % dimensions to consider
                varDim_flag = true;
                dims = uq_cline{2};
            else
                % consider all dimensions
                varDim_flag = false;
                dims = 1:obj.Input.Dim;
            end
            
            if ~varDim_flag
                % check whether X includes constants or not and remove constants if yes
                if size(X,2) > obj.Runtime.MnonConst 
                    X = X(:,obj.Runtime.nonConstIdx);
                end
            end

            % transform X to quantile space
            if varDim_flag
                % extract sub-input object
                mySubInput = uq_extractInputs(obj.Input.Original, dims,'-private');
                U = uq_RosenblattTransform(X, mySubInput.Marginals, mySubInput.Copula);
            else
                U = uq_RosenblattTransform(X, obj.Input.Original.Marginals, obj.Input.Original.Copula);
            end
            
            % init
            Y = zeros(size(X,1),1);
            if nargout > 1
                Yvar = Y; Yrepl = zeros(size(X,1), obj.ExpOptions.Bootstrap.Replications);
            end
            
            if numnodes(obj.FlatGraph) > 0 && isinf(maxRefine) 
                % use FLAT graph
                % loop over flatgraph indices
                for ii = 1:numnodes(obj.FlatGraph)
                    % get current bounds
                    currBounds = obj.FlatGraph.Nodes.bounds{ii};
                    
                    % get indices of current points 
                    % only check for subdimensions DIMS
                    currIdx = uq_SSE_inBound(U,currBounds(:, dims));
                    pointsInside = sum(currIdx);

                    % do only if points are inside domain
                    if pointsInside > 0
                        % init
                        currX = X(currIdx,:);
                        currExpansion = obj.FlatGraph.Nodes.expansions{ii};

                        % scale currY with normalization depending on
                        % excluded dimensions
                        if varDim_flag
                            % prepare subexpansion
                            subExpansion = createSubExpansion(currExpansion, dims);

                            % evaluate subexpansion
                            currY = uq_evalModel(subExpansion,currX);

                            % get excluded dimensions
                            exDim = 1:obj.Input.Dim; exDim(dims) = [];

                            % get input mass inside bounds
                            normalizer = uq_SSE_volume(currBounds,exDim);

                            % normalize currY
                            currY = currY*normalizer;
                        else
                            % evaluate Expansion
                            if nargout > 1
                                % also get variancc
                                [currY,  Yvar(currIdx), Yrepl(currIdx,:)] = uq_evalModel(currExpansion,currX);
                            else
                                % evaluate full Expansion
                                currY = uq_evalModel(currExpansion,currX);
                            end
                        end
                         
                        % update Y
                        Y(currIdx) = Y(currIdx) + currY;
                    end
                end
            else
                % use FULL graph
                outGoing = outdegree(obj.Graph);
                terminalIndices = find(outGoing==0);
                % loop over individual Expansions using the full graph
                for ii = 1:obj.Graph.numnodes
                    % retrieve current bounds
                    currExpansion = obj.Graph.Nodes.expansions{ii};
                    currRefine = obj.Graph.Nodes.ref(ii);
                    if and(~isempty(currExpansion), currRefine <= maxRefine) % does the current node have an Expansion
                        % get current indices for X
                        currBounds = obj.Graph.Nodes.bounds{ii};
                        
                        % only check for subdimensions dIMS
                        currIdx = uq_SSE_inBound(U,currBounds(:,dims));
                        
                        % do only if points are inside domain
                        if sum(currIdx) > 0
                            % init
                            currX = X(currIdx,:);
                            
                            % scale currY with normalization depending on
                            % excluded dimensions
                            if varDim_flag
                                % prepare subexpansion
                                subExpansion = createSubExpansion(currExpansion,dims);
                                
                                % evaluate subexpansion
                                currY = uq_evalModel(subExpansion,currX);
                                
                                % get excluded dimensions
                                exDim = 1:obj.Input.Dim; exDim(dims) = [];
                                
                                % get input mass inside bounds
                                normalizer = uq_SSE_volume(currBounds,exDim);
                                
                                % normalize currY
                                currY = currY*normalizer;
                            else
                                % evaluate full Expansion
                                if nargout > 1 && any(ii == terminalIndices)
                                    % evalute variance as well
                                    [currY,  Yvar(currIdx), Yrepl(currIdx,:)] = uq_evalModel(currExpansion,currX);
                                    % if currExpansion has only a zero, use parent
                                    % Expansion for variance
                                    if all(currExpansion.PCE.Coefficients == 0) && ii > 1
                                       %error('Review this conditional - it seems to be unneccessary legacy code')
                                       % if this conditional is to be
                                       % removed, simplify also uq_SSE_postExpansion_computePf
                                       ParentIdx = predecessors(obj.Graph,ii);
                                       parentExpansion =  obj.Graph.Nodes.expansions{ParentIdx};
                                       % evaluate parent
                                       [~,  Yvar(currIdx), Yrepl(currIdx,:)] = uq_evalModel(parentExpansion,currX);
                                    end
                                    % normalize Yrepl
                                    Yrepl(currIdx,:) = Yrepl(currIdx,:) - currY;
                                else
                                    % evaluate full Expansion
                                    currY = uq_evalModel(currExpansion,currX);
                                end
                            end
                            
                            % update Y
                            Y(currIdx) = Y(currIdx) + currY;
                        end
                    end
                end
                
                if nargout > 1
                    % add Y to replication bounds
                    Yrepl = Yrepl + Y;
                end
            end
            
            if nargout
                varargout{1} = Y;
            end
            if nargout > 1
                varargout{2} = Yvar;
            end
            if nargout > 2
                Yconf = quantile(Yrepl,[0.025 0.975],2);
                varargout{3} = Yconf;
            end
            if nargout > 3
                varargout{4} = Yrepl;
            end
            if nargout > 4
                varargout{5} = U;
            end
        end
        
        function [Y,F,X,Yconf,Yrepl] = evalSSEInDomain(obj, currBounds, NPoints)
        % sample from input distribution and evaluate SSE
        if nargin < 3
            NPoints = 1e6;
        end
        samplingDist = uq_uniformDist(currBounds,'-private');

        F = uq_getSample(samplingDist,NPoints,'MC');
        X = uq_invRosenblattTransform(F, obj.Input.Original.Marginals, obj.Input.Original.Copula);
        if nargout <= 3
            Y = evalSSE(obj, X);
        elseif nargout <= 4
            [Y,~,Yconf] = evalSSE(obj, X);
        else
            [Y,~,Yconf,Yrepl] = evalSSE(obj, X);
        end
        end
        
        % experimental function - remove in release version
        function obj = forcePositivity(obj,NPoints)
        % determine SSE regions that return negative values and recompute
        % local Expansions there, subsequently reducing polynomial degree until
        % all points are positive
        
        % init
        if isempty(obj.FlatGraph)
            error('forcePositivity only works with flattened graph')
        end
        
        if nargin == 1
            % use default number of points
            NPoints = 1e4;
        end
        
        % loop over FlatExpansions
        FlGraph = obj.FlatGraph;
        for tt = 1:numnodes(FlGraph)
            currExpansion = FlGraph.Nodes.expansions{tt};
            X = uq_getSample(currExpansion.Internal.Input,NPoints);
            % evaluate from Expansion
            Y = uq_evalModel(currExpansion,X);
            % check if positive
            if any(Y < 0)
                % extract metaOpts and input
                metaOpts = obj.ExpOptions;
                input = currExpansion.Internal.Input;
                
                % get quantities 
                currBounds = FlGraph.Nodes.bounds{tt};
                currIdx = uq_SSE_inBound(obj.ExpDesign.U,currBounds);
                currX = obj.ExpDesign.X(currIdx,:);
                currY = obj.ExpDesign.Y(currIdx,:);
                
                % recompute Expansion, reducing maximum degree until all points
                % are >=0
                degrees = metaOpts.Degree;
                for ii = 0:length(degrees)-1
                    % update maximum degree
                    metaOpts.Degree = degrees(1:end-ii);
                    % compute Expansion
                    trialExpansion = computeExpansion(metaOpts,input,currX,currY);
                    % check if all >= 0
                    Y = uq_evalModel(trialExpansion,X);
                    if all(Y >= 0)
                        break
                    end
                    % at maxDegree 0, break condition is fulfilled
                    % automatically
                end
                
                % assign trialExpansion
                FlGraph.Nodes.expansions{tt} = trialExpansion;
            end
        end
        
        % assign to obj
        obj.FlGraph = FlGraph;
        end
    end
end

%% Utility functions
function [obj, newExpansion] = createResidualExpansion(obj, currBounds)
% function that creates expansion on the residual and returns the UQLab
% expansion object

% get indices of points in bounds
currIdx = uq_SSE_inBound(obj.ExpDesign.U, currBounds);

% extract current X and residual
currX = obj.ExpDesign.X(currIdx,:);
currRes = obj.ExpDesign.Res(currIdx);

% compute PCE
% if too few points in bounds return
if sum(currIdx) < obj.Refine.NExp
    newExpansion = [];
else
    % prepare input object
    myInput = getExpansionInput(currBounds, obj.Input);

    % compute expansion
    newExpansion = computeExpansion(obj.ExpOptions, myInput, currX, currRes);  
end
end

function myInput = getExpansionInput(currBounds, InputProperties)
if all(currBounds(1,:)==0) && all(currBounds(2,:)==1)
    % initial full domain
    myInput = InputProperties.Independent;
else
    % subdomain
    % sample at boundary, transform to physical space and take envelope as
    % new bounds
    NPoints = 1e3;
    UFace = rand(NPoints, InputProperties.Dim - 1);
    UBounds = [];
    for currDim = 1:InputProperties.Dim
        % get non curr dim
        nonCurrDim = setdiff(1:InputProperties.Dim,currDim);
        % transform UFace
        currDimBounds = currBounds(:,currDim);
        nonCurrDimBounds = currBounds(:,nonCurrDim);
        % transform to fit nonCurrDimBounds
        UFaceCurr(:,nonCurrDim) = nonCurrDimBounds(1,:) + UFace.*diff(nonCurrDimBounds);
        % Add currDim Bounds and store lower and upper bounds
        UFaceCurr(:,currDim) = currDimBounds(1);
        UBounds = [UBounds; UFaceCurr];
        UFaceCurr(:,currDim) = currDimBounds(2);
        UBounds = [UBounds; UFaceCurr];
    end

    % truncate input
    XBounds = uq_invRosenblattTransform(UBounds, InputProperties.Original.Marginals, InputProperties.Original.Copula);
    currBounds_X = [min(XBounds); max(XBounds)];
    myInput = uq_SSE_truncateDist(InputProperties.Independent, currBounds_X);
end
end

function newExpansion = computeExpansion(metaOpts, input, X,Y)
% compute uqlab expansion object
if ~strcmpi(metaOpts.MetaType,'PCE')
    error('Currently only PCE expansions supported!')
end

% change lognormal type to arbitrary not hermite! (leads to problems upon flatttening)
% get default poly types based on input
marginals = {input.Marginals.Type}';
isLogNormal = strcmpi(marginals,'lognormal');
if any(isLogNormal)
    % at least one marginal is lognormal, set polyType to arbitrary
    polyTypes = uq_auto_retrieve_poly_types(input);
    polyTypes(isLogNormal) = {'Arbitrary'};
    % assign non-default poly types
    metaOpts.PolyTypes = polyTypes;
end

% setup PCE
metaOpts.ExpDesign.X = X;
metaOpts.ExpDesign.Y = Y;
metaOpts.Input = input;

if size(X,1) == 1
    % only one point - use OLS
    metaOpts.Method = 'OLS';
end

% Try with LARS, if it fails, switch to OLS
try
    newExpansion = uq_createModel(metaOpts,'-private');
catch
    metaOpts.Method = 'OLS';
    newExpansion = uq_createModel(metaOpts,'-private');
end
end

function continueRefine = evaluateStoppingCriteria(varargin)
% evaluates the various stopping critera
% initialize
continueRefine = true;
% switch which stopping criteria are evaluated based on the input arguments
if isnumeric(varargin{1})
    refineIdx = varargin{1};
    if refineIdx == 0
        continueRefine = false;
        fprintf('Terminating algorithm, no more refinement domains found...\n')
    end
else
    obj = varargin{1};
    if obj.currRef >= obj.Stopping.MaxRefine
        continueRefine = false;
        fprintf('Terminating algorithm, maximum number of refinement steps exhausted...\n')
    elseif obj.Stopping.Criterion(obj)
        continueRefine = false;
        fprintf('Terminating algorithm, stopping criterion met...\n')
    end
end
end

function [obj, createdExpansions, ExpansionContainer] = createExpansionsInDomains(obj, newDomains)
% creates expansions in newDomains after enriching the experimental design
% init
nNewDomains = length(newDomains);

% create Expansions in new domains 
createdExpansions = false(1,nNewDomains); domains = 1:nNewDomains;
ExpansionContainer = cell(nNewDomains,1);

% loop over domains
for dd = domains
    currBounds = newDomains(dd).bounds;
    
    % enrich experimental design
    if obj.currRef == 0
        % at first step, do not enrich. Enrichment happened already in 
        % uq_SSE_initialize
        NEnrich = 0;
    else
        NEnrich = obj.ExpDesign.NEnrich;
    end

    % check if number of model evaluations not reached yet and adjust
    % NENRICH
    maxModelEvals = obj.Stopping.NSamples;
    if (length(obj.ExpDesign.Y) + NEnrich) > maxModelEvals
        NEnrich = maxModelEvals - length(obj.ExpDesign.Y);
    end

    % enrich experimental design
    if NEnrich > 0
        obj = enrichExpDesign(obj, currBounds, NEnrich);
    end
    
    % create residual expansion
    [obj, currExpansion] = createResidualExpansion(obj,currBounds);
    createdExpansions(dd) = ~isempty(currExpansion);

    if createdExpansions(dd)
        % assign new PCE to container
        ExpansionContainer{dd} = currExpansion;
    end 
end
end

function obj = constructExpansions(obj,parentIdx,newDomains)
% Create expansions. If no expansion exists in NEWDOMAINS, create one.
% Otherwise, partition domain of PARENTIDX into subdomains and compute 
% expansions in each.

% first check if NEWDOMAINS is empty or not
if isempty(newDomains)
    % No new domains, create expansion in PARENTIDX domain
    % extract bounds and mass
    newDomains.bounds = obj.Graph.Nodes.bounds{parentIdx};
    newDomains.inputMass = obj.Graph.Nodes.inputMass(parentIdx);
end

% create Expansions in new domains
[obj, createdExpansion, ExpansionContainer] = createExpansionsInDomains(obj, newDomains);
    
% created Expansion logical
createdExpansionLog = logical(any(createdExpansion,1));
if ~any(createdExpansionLog)
    error('No new Expansion generated, something wrong in findRefinementSub(obj)')
end
    
% create new nodes in graph
nNewDomains = length(newDomains);
for dd = 1:nNewDomains
    if createdExpansionLog(dd)
        % new Expansion, add to graph
        obj = addDomainToSSE(obj, newDomains(dd), parentIdx, ExpansionContainer{dd});
    else
        % no new Expansion, just add domain
        obj = addDomainToSSE(obj, newDomains(dd), parentIdx);
    end
end
% post expansion actions
newIdx = find(obj.Graph.Nodes.ref == obj.currRef); 

% update residual
obj = updateRes(obj, newIdx);

% update neighbours
currNeighbours = obj.Graph.Nodes.neighbours;
bounds = obj.Graph.Nodes.bounds;
obj.Graph.Nodes.neighbours = updateNeighbours(currNeighbours, bounds, newIdx, parentIdx);

% run custom post-expansion operation
obj.Graph.Nodes = obj.PostExpansion(obj, newIdx);
end

function obj = addDomainToSSE(obj, newDomain, parentIdx, expansion)
% store a new domain in SSE graph

% init
bounds = newDomain.bounds;
inputMass = newDomain.inputMass;

% if not initial expansion (i.e., currRef == 0), add to Graph
if obj.currRef ~= 0
    % add new node to graph
    obj.Graph = addedge(obj.Graph,parentIdx,obj.Graph.numnodes + 1);
    % fill new node
    obj.Graph.Nodes.bounds(end) = {bounds};
    obj.Graph.Nodes.ref(end) = obj.currRef;
    obj.Graph.Nodes.level(end) = obj.Graph.Nodes.level(parentIdx) + 1;
    % determine index and assign
    maxIdxCurrLevel = max(obj.Graph.Nodes.idx(obj.Graph.Nodes.level==obj.Graph.Nodes.level(end)));
    obj.Graph.Nodes.idx(end) = maxIdxCurrLevel + 1;
    obj.Graph.Nodes.inputMass(end) = inputMass;

    if nargin == 4
        % store expansion in Expansions structure
        obj.Graph.Nodes.expansions(end) = {expansion};
    end
else
    % store initial expansion
    obj.Graph.Nodes.expansions = {expansion};
end
end

function updatedNeighbours = updateNeighbours(currNeighbours, bounds, newIdx, parentIdx)
% update the list of neighbours
% get neighbours of parent
parentNeighbours = currNeighbours{parentIdx};
% init
updatedNeighbours = currNeighbours;

% loop over newIdx
for ii = newIdx'
    % init
    newNeighbours = [];
    bounds1 = bounds{ii};
    % loop over parent neighbours, the neighbours of ii are a subset of the
    % neighbours of pp
    for pp = parentNeighbours
        % check, whether pp is also a neighbour of ii
        bounds2 = bounds{pp};
        if any(bounds1(1,:) == bounds2(2,:)) || any(bounds1(2,:) == bounds2(1,:))
            % pp is also a neighbour of ii
            newNeighbours = [newNeighbours, pp];
            % remove parent idx from pp and replace with ii
            updatedNeighbours{pp} = unique([updatedNeighbours{pp}(updatedNeighbours{pp} ~= parentIdx),currNeighbours{pp}(currNeighbours{pp} ~= parentIdx),ii]);
        end
    end
    % loop over other newIdx and determine if they are neighbours
    for jj = newIdx(newIdx ~= ii)
        bounds2 = bounds{jj};
        if any(bounds1(1,:) == bounds2(2,:)) || any(bounds1(2,:) == bounds2(1,:))
            % jj is also a neighbour of ii
            newNeighbours = [newNeighbours, jj];
        end
    end
    % store ii updated neighbours
    updatedNeighbours{ii} = newNeighbours;
end
end

function obj = updateRes(obj,subIdx)
% update residual
for ii = 1:length(subIdx)
    % get current bounds
    currBounds = obj.Graph.Nodes.bounds{subIdx(ii)};
    % get indices of points in bounds
    currIdx = uq_SSE_inBound(obj.ExpDesign.U,currBounds);
    currExpansion = obj.Graph.Nodes.expansions{subIdx(ii)};
    if  ~isempty(currExpansion)
        expansionEvaluation = uq_evalModel(currExpansion, obj.ExpDesign.X(currIdx,:));
        obj.ExpDesign.Res(currIdx) = obj.ExpDesign.Res(currIdx) - expansionEvaluation;
    end
end
end

function subExpPCE = createSubExpansion(currPCE, dims)
% Modifies the currPCE UQLab object to include only basis functions
% that are constant in non current dimensions

% extract basis of currPCE and compute subexpansion indices
basisIndices = currPCE.PCE.Basis.Indices;
if length(dims) == 1
    polyIndices = logical(basisIndices(:,dims) == sum(basisIndices,2));
elseif length(dims) == 2
    dims1 = dims(1);
    dims2 = dims(2);
    polyIndices = logical(basisIndices(:,dims1) + basisIndices(:,dims2) == sum(basisIndices,2));
else
    error('Not supported')
end

% build custom PCE from currPCE
subExpOpts.Input = uq_extractInputs(currPCE.Internal.Input, dims,'-private');
subExpOpts.Type = 'Metamodel';
subExpOpts.MetaType = 'PCE';
subExpOpts.Method = 'Custom';
subExpOpts.PCE.Basis.PolyTypes = currPCE.PCE.Basis.PolyTypes(dims);

% keep only relevant subexpansion
subExpOpts.PCE.Basis.Indices = currPCE.PCE.Basis.Indices(polyIndices,dims);
subExpOpts.PCE.Coefficients = currPCE.PCE.Coefficients(polyIndices);
subExpPCE = uq_createModel(subExpOpts,'-private');
end

function [obj, refineIdx, newDomain] = findRefinementSub(obj)
% find subdomain with maximum error (only consider terminal domains)
outGoing = outdegree(obj.Graph);
termDomsIdx = find(outGoing==0);

% update refinement scores
obj = updateRefineScores(obj);

% normalize refinement scores
refineScores = obj.Graph.Nodes.refineScore(termDomsIdx);
normalizer = sum(refineScores);
if normalizer ~= 0
    % avoid division by 0
    relRefineScores = refineScores/sum(refineScores);

    % consider only subdomains that have a relative refinement score above
    % certain threshold
    threshComb = obj.Refine.Threshold;
    isRelev = relRefineScores > threshComb;
    relevDomsIdx = termDomsIdx(isRelev);
    relRefineScores = relRefineScores(isRelev);
else
    relRefineScores = refineScores;
    relevDomsIdx = termDomsIdx;
end

% sort refinement scores
sortIdx = uq_SSE_sortValues(relRefineScores,'descend',false);
sortTerminalIdx = relevDomsIdx(sortIdx);

% get number of available refinement samples
NAvailRefinePoints = obj.Stopping.NSamples - size(obj.ExpDesign.X,1);
refineIdx = 0;
% loop over the terminal nodes and determine whether refinement is possible
if ~isempty(sortTerminalIdx)
    % at least one terminal domain might be refineable
    for ii = sortTerminalIdx'
        % switch refinement type
        if numel(obj.Graph.Nodes.expansions)== 0 || isempty(obj.Graph.Nodes.expansions{ii}) 
            % No Expansion in current node
            currIdx = uq_SSE_inBound(obj.ExpDesign.U, obj.Graph.Nodes.bounds{ii});
            if sum(currIdx) + NAvailRefinePoints >= obj.Refine.NExp
                refineIdx = ii; % refinement subdomain
                newDomain = [];
                break
            end
        else
            % current node has an Expansion
            newDomain = obj.Partitioning(obj, ii);   
            if ~isempty(newDomain)
                % number of points inside new domains
                for dd = 1:length(newDomain)
                    currIdx = uq_SSE_inBound(obj.ExpDesign.U, newDomain(dd).bounds);
                    if sum(currIdx) + NAvailRefinePoints >= obj.Refine.NExp
                        % enough points available for expansion
                        refineIdx = ii;
                        break
                    end
                end
            end
        end
        if refineIdx > 0
            break
        end
    end
else
    % no terminal domain is refineable
    newDomain = [];
end
end

function [convergenceError, terminalIndices] = computeConvergenceError(obj)
% average loo-errors of PCEs in terminal domain
% get terminal domains
outGoing = outdegree(obj.Graph);
terminalIndices = find(outGoing==0);

% loop over terminal domains
convergenceError = 0;
for ii = terminalIndices'
    if isempty(obj.Graph.Nodes.expansions{ii})
        % no PCE in domain, take parent
        ParentIdx = predecessors(obj.Graph,ii);
        currExpansion = obj.Graph.Nodes.expansions{ParentIdx};
    else
        currExpansion = obj.Graph.Nodes.expansions{ii};
    end
    currLOO = currExpansion.Error.ModifiedLOO*var(currExpansion.ExpDesign.Y,1,1);
    currMass = obj.Graph.Nodes.inputMass(ii);
    convergenceError = convergenceError + currLOO*currMass;
end
end

function obj = updateRefineScores(obj)
% loop over terminal nodes and update refinement score
outGoing = outdegree(obj.Graph);
terminalIndices = find(outGoing==0);

% loop over terminal indices
if obj.currRef == 0
    obj.Graph.Nodes.refineScore(1) = 1;
else
    for ii = terminalIndices'
        obj.Graph.Nodes.refineScore(ii) = obj.Refine.Score(obj, ii);
    end
end
end