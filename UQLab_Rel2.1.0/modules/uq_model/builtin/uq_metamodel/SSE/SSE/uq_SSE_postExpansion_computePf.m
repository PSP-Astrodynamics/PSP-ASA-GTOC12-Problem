function Nodes = uq_SSE_postExpansion_computePf(obj, subIdx)
% UQ_SSE_POSTEXPANSION_COMPUTEPF returns the conditional failure 
%    probabilities in the domains defined by subIdx and stores them in the
%    right nodes of the graph

% initialize nodes and expansions
Nodes = obj.Graph.Nodes;

% check if Bootstrapping is available
if ~isfield(obj.ExpOptions,'Bootstrap') || obj.ExpOptions.Bootstrap.Replications < 1
    error('uq_SSE_postExpansion_computePf requires bootstrap Expansions!')
end

% loop over subidx
for idx = subIdx'
    % get current bounds
    currBounds = obj.Graph.Nodes.bounds{idx};
    
    % compute conditional failure probability
    [Pf, History, PfRepl] = computePf(obj, currBounds);
    
    % store in Graph
    if ~strcmp('Pf',Nodes.Properties.VariableNames)
        Nodes.Pf = Pf;
        Nodes.History = History;
        Nodes.PfRepl = PfRepl;
    else
        Nodes.Pf(idx,:) = Pf;
        Nodes.History(idx) = History;
        Nodes.PfRepl(idx,:) = PfRepl;
    end
    
    % check whether all siblings of IDX have nonconstant expansions and parent
    % replications are thus no longer required
    parentIdx = predecessors(obj.Graph, idx);
    if ~isempty(parentIdx)
        parentExpansion = obj.Graph.Nodes.expansions{parentIdx};
        if ~isempty(parentExpansion) && isfield(parentExpansion.Internal,'Bootstrap')
            if siblingsNonZeroExpansion(obj, idx)
                % remove bootstrap replications in parent
                obj.Graph.Nodes.expansions{parentIdx}.Internal = rmfield(parentExpansion.Internal,'Bootstrap');

                % remove history field from parent
                if any(strcmp(obj.Graph.Nodes.Properties.VariableNames,'History'))
                    Nodes.History(parentIdx).Y = [];
                    Nodes.History(parentIdx).Yrepl = [];
                    Nodes.History(parentIdx).U = [];
                end
            end
        end
    end
end

end

function bool = siblingsNonZeroExpansion(obj, idx)
% determines whether all siblings of/and IDX have non-zero expansions
% init
siblingsIdx = successors(obj.Graph,predecessors(obj.Graph, idx));
bool = true;

% loop over siblings
for ss = siblingsIdx'
    currExpansion = obj.Graph.Nodes.expansions{ss};
    % check for expansion
    if isempty(currExpansion)
        bool = false;
        break
    elseif all(currExpansion.PCE.Coefficients == 0)
    % check for nonzero expansion
        bool = false;
        break
    end
end
end

function [Pf, History, Pfrepl] = computePf(obj, bounds)
% compute failure probability
% dummy uq model of sse
modelopts.mHandle = @(F) evalSSE(obj,uq_invRosenblattTransform(F, obj.Input.Original.Marginals, obj.Input.Original.Copula));
modelopts.isVectorized = true;
currSSEmodel = uq_createModel(modelopts,'-private');
% dummy truncated distribution in unit hypercube
currInput = uq_uniformDist(bounds,'-private');

% create reliability model
BatchSize = 1e3; % 1e4
PfSimOptions.Type = 'Reliability';     
PfSimOptions.Model = currSSEmodel;   
PfSimOptions.Input = currInput;  
PfSimOptions.Simulation.TargetCoV = 0.05;  
PfSimOptions.Simulation.BatchSize = BatchSize;
PfSimOptions.Simulation.MaxSampleSize = 1e4;% 1e5;
PfSimOptions.Display = 'quiet';

% Use subset simulation
PfSimOptions.Method = 'Subset';
PfSimOptions.Subset.Componentwise = 1;
myRelAnalysis = uq_createAnalysis(PfSimOptions,'-private');

switch PfSimOptions.Method
    case 'MCS'
        Xhist = uq_invRosenblattTransform(myRelAnalysis.Results.History.X, obj.Input.Original.Marginals, obj.Input.Original.Copula);
        nSamples = size(Xhist,1);
    case 'Subset'        
        for ss = 1:length(myRelAnalysis.Results.History.X)
            Xhist{ss} = uq_invRosenblattTransform(myRelAnalysis.Results.History.X{ss}, obj.Input.Original.Marginals, obj.Input.Original.Copula);
        end
        nSamples = myRelAnalysis.Results.History.ModelEvaluationsNom;
end
nBatch = ceil(nSamples/BatchSize);
batchIdx = repmat((1:nBatch)',1,BatchSize);
batchIdx = batchIdx(1:nSamples);
% init
Y_all = zeros(nSamples,1); Yconf_all = zeros(nSamples,2);
Yrepl_all = zeros(nSamples,obj.ExpOptions.Bootstrap.Replications);
F_all = zeros(nSamples,obj.Input.Dim);
switch PfSimOptions.Method
    case 'MCS'
        % Monte Carlo
        for bb = 1:nBatch
            currX = Xhist(batchIdx == bb,:);
            currIdx = batchIdx == bb;
            [Y,~,Yconf,Yrepl,F] = evalSSE(obj, currX);
            % assign replications to container
            Y_all(currIdx) = Y;
            Yconf_all(currIdx,:) = Yconf;
            Yrepl_all(currIdx,:) = Yrepl; 
            F_all(currIdx,:) = F;
        end
        % compute Pf
        Pf = computePfOnSample(Y_all, Yconf_all, 0);
        Pfrepl = mean(Yrepl_all < 0);
        % store in History
        History.Y = Y_all; 
        History.Yrepl = Yrepl_all; 
        History.U = F_all; 
    case 'Subset'
        nSubsets = myRelAnalysis.Results.NumberSubsets;
        PfSub = []; PfSubRepl = [];
        History.Y = [];History.Yrepl = []; History.U = [];
        for ii = 1:nSubsets
            currX = Xhist{ii};
            currThresh = myRelAnalysis.Results.History.q(ii);
            [Y,~,Yconf,Yrepl,F] = evalSSE(obj, currX);
            currPf = computePfOnSample(Y, Yconf, currThresh);
            PfSub(end+1,:) = currPf(1:3);
            PfSubRepl(end+1,:) = mean(Yrepl < currThresh);

            % assign replications to History as well
            History.Y = [History.Y; Y];
            History.Yrepl = [History.Yrepl; Yrepl];
            History.U = [History.U; F];
        end
        % combine Pfs
        Pf = prod(PfSub,1);
        Pfrepl = prod(PfSubRepl,1);
end
end

function Pf = computePfOnSample(Y, Yconf, thresh)
% set thresh to 0 if not passed
Pf = [mean(Y<thresh), mean(Yconf(:,2)<thresh), mean(Yconf(:,1)<thresh)];
end