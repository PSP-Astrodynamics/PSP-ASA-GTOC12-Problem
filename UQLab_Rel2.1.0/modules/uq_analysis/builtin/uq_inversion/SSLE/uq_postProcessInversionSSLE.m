function module = uq_postProcessInversionSSLE(module, varargin)
% UQ_POSTPROCESSINVERSIONSSLE post-processes an inverse analysis carried out
%    with the Bayesian inversion module of UQLab and the SSLE solver.
%
%    UQ_POSTPROCESSINVERSIONSSLE(MODULE, NAME, VALUE) allows to choose
%    more post processing options by specifying Name/Value pairs:
%
%       Name                  VALUE
%       'evidence'            Should the evidence be computed. 
%                             - Logical
%                             default : true
%       'pointEstimate'       Computes a point estimate based on the
%                             supplied sample.
%                             - String : ('Mean','None')
%                             - n x M Double 
%                             - Cell array of the above
%       'dependence'          Estimates the posterior correlation and
%                             coviariance matrix
%                             - Logical 
%                             default : false
%       'parameters'          Which parameters to consider 
%                             - Integer vector
%                             default : 1:M
%       'maxrefine'           Maximum refinement step. If more than one are
%                             given as a vector, the SSLE is post-processed
%                             for each.
%                             - Integer vector
%                             default : Inf
%
% See also: UQ_PRINT_UQ_INVERSION, UQ_DISPLAY_UQ_INVERSION

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_inversion')
    error('uq_postProcessInversionSSLE only operates on objects of type ''Inversion''') 
end

%check if SSLE Solver
if ~strcmp(module.Internal.Solver.Type, 'SSLE')
    error('No results to post-process')
end

%% Initialization
% extract sse
mySSE = module.Results.SSLE.SSE;
M = mySSE.Input.Dim;

%% Default behavior
% Evidence
Default.evidence_flag = true;
% Point estimate
Default.pointEstimate_flag = true;
Default.pointEstimate = {'Mean'};
% Dependence indices
Default.dependence_flag = false;
% Parameters
Default.parameters = 1:M;
% Dependence indices
Default.maxRefine = inf;

%% Check for input arguments
%set optional arguments
parse_keys = {'evidence', 'pointestimate','dependence','parameters', 'maxrefine'};
parse_types = {'p','p','p','p','p'};

if nargin > 1
    % vargin given
    % make NAME lower case
    varargin(1:2:end) = lower(varargin(1:2:end));
    [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
else
    % no vargin, use default options
    nOpts = length(parse_keys);
    uq_cline = cell(nOpts,1);
    for ii = 1:nOpts
        uq_cline{ii} = 'false';
    end
end

% 'evidence' option determines whether the evidence should be computed
if ~strcmpi(uq_cline{1}, 'false')
    evidence_flag = uq_cline{1};
else
    % use defaults
    evidence_flag = Default.evidence_flag;
end

% point estimate
[pointEstimate, pointEstimate_flag, pointParamIn, Results] = .....
    uq_postProcessInversion_initPointEstimate(uq_cline{2}, Default, module.Results, M);
module.Results = Results;
if ~any(strcmpi(pointEstimate, 'mean'))
    if ~evidence_flag
        error('Evidence is required to compute mean')
    end
end
if any(strcmpi(pointEstimate, 'map'))
    error('MAP is not yet supported for SSLE')
end

% dependence
if ~strcmp(uq_cline{3}, 'false')
    dependence_flag = uq_cline{3};
    if dependence_flag == false
        % remove possibly existing dependence field
        if isfield(module.Results,'PostProc')
            if isfield(module.Results.PostProc,'Dependence')
                module.Results.PostProc = rmfield(module.Results.PostProc,'Dependence');
            end
        end
    end
else
    dependence_flag = Default.dependence_flag;
end
if dependence_flag
    if ~any(strcmpi(pointEstimate, 'mean'))
        error('Mean is required to compute dependence')
    end
end

% 'parameters' option determines which dimensions to consider
if ~strcmpi(uq_cline{4}, 'false')
    params = sort(uq_cline{4});
    if any(params > M)
        error('One of the supplied parameters exceeds the problem dimensionality!')
    end    
else
    % use defaults
    params = Default.parameters;
end

% 'maxrefine' option determines which maximum refinement step to consider
if ~strcmpi(uq_cline{5}, 'false')
    maxRefine = uq_cline{5};
    if ~iscolumn(maxRefine)
        % turn into column vector
        maxRefine = maxRefine.';
    end    
else
    % use defaults
    maxRefine = Default.maxRefine;
end

% Choose flat or full graph
if numnodes(mySSE.FlatGraph) == 0 || any(~isinf(maxRefine))
    % FullGraph
    myGraph = mySSE.Graph;
else
    % FlatGraph
    myGraph  = mySSE.FlatGraph;
end

%% Computing QoIs
% EVIDENCE
if evidence_flag
    % compute evidence
    Evidence = zeros(length(maxRefine),1);

    % loop over nodes
    for ii = 1:myGraph.numnodes
        if ~isempty(myGraph.Nodes.expansions{ii})
            % get current reference level
            currRef = myGraph.Nodes.ref(ii);

            % init
            currExpansion = myGraph.Nodes.expansions{ii};
            currPriorMass = myGraph.Nodes.inputMass(ii);

            % get constant poly coefficient
            constPoly = currExpansion.PCE.Coefficients(1);

            % add constant term to evidence for applicable ids
            idVector = currRef <= maxRefine;
            Evidence(idVector) = Evidence(idVector) + constPoly*currPriorMass;
        end
    end
% Return QoI
postProc.Evidence = Evidence;
    
% Also return handle to posterior
postProc.Posterior = @(x) uq_evalModel(module.Results.SSLE, x).*module.Prior(x)./Evidence;
end

% MEAN
% loop over nodes
if any(strcmpi(pointEstimate,'mean'))
    Mean = nan(length(maxRefine),M);
    Mean(:, params) = 0;
    for ii = 1:myGraph.numnodes
        if ~isempty(myGraph.Nodes.expansions{ii})
            % get current reference level
            currRef = myGraph.Nodes.ref(ii);

            % init
            currExpansion = myGraph.Nodes.expansions{ii};
            currCoeffs = currExpansion.PCE.Coefficients;
            currIndices = currExpansion.PCE.Basis.Indices;
            currPriorMass = myGraph.Nodes.inputMass(ii);

            % loop over dimensions
            for mm = params
                % create uqlab model for the quantity of interest
                QoIModelOpts.mString = sprintf('X(%i)',mm);
                QoIModel = uq_createModel(QoIModelOpts, '-private');

                % project QoI
                QoIIndices = zeros(2,M); QoIIndices(2,mm) = 1;
                QoICoeffs = projectQoI(currExpansion,QoIModel,QoIIndices);

                % normalize c coefficient
                QoICoeffs = QoICoeffs*currPriorMass;

                % keep only polynomials present in QoIIndices basis
                QoIMatchIndex = ismember(QoIIndices,currIndices,'rows');
                currMatchIndex = ismember(currIndices,QoIIndices,'rows');

                % compute mean
                idVector = currRef <= maxRefine;
                Mean(idVector,mm) = Mean(idVector,mm) + QoICoeffs(QoIMatchIndex)'*currCoeffs(currMatchIndex);
            end
        end
    end
    Mean = Mean./Evidence;
% Return QoI
postProc.Mean = Mean;
end

% point estimates
if pointEstimate_flag
    % loop over point estimators
    for pp = 1:length(pointEstimate)
        switch lower(pointEstimate{pp})
            case 'mean'
                % set to posterior mean
                pointParam{pp} = Mean(end,:);          
            case 'custom'
                % do nothing
                pointParam{pp} = pointParamIn{pp};
        end
    end
    
% Return to analysis object
postProc.PointEstimate.X = pointParam;
postProc.PointEstimate.Type = pointEstimate;
end

% COVARIANCE
% loop over maxRefine
if dependence_flag
    Covariance = nan(M,M,length(maxRefine));
    Covariance(params, params, :) = 0;
    for rr = 1:length(maxRefine)
        for ii = 1:myGraph.numnodes
            if ~isempty(myGraph.Nodes.expansions{ii})
                % get current reference level
                currRef = myGraph.Nodes.ref(ii);
                if currRef > maxRefine(rr)
                    % go to next loop step
                    continue
                end

                % init
                currExpansion = myGraph.Nodes.expansions{ii};
                currCoeffs = currExpansion.PCE.Coefficients;
                currIndices = currExpansion.PCE.Basis.Indices;
                currPriorMass = myGraph.Nodes.inputMass(ii);

                % loop over dimensions
                for mm = params
                    for nn = params
                        if mm == nn % variance terms
                            % create uqlab model for the quantity of interest
                            QoIModelOpts.mString = sprintf('(X(%i)-%.5e).^2',mm,Mean(rr,mm));
                            QoIModel = uq_createModel(QoIModelOpts, '-private');

                            % project QoI
                            QoIIndices = zeros(3,M);
                            QoIIndices(2,mm) = 1; QoIIndices(3,mm) = 2;
                            QoICoeffs = projectQoI(currExpansion,QoIModel,QoIIndices);

                            % normalize c coefficient
                            QoICoeffs = QoICoeffs*currPriorMass;

                            % keep only polynomials present in QoIIndices basis
                            QoIMatchIndex = ismember(QoIIndices,currIndices,'rows');
                            currMatchIndex = ismember(currIndices,QoIIndices,'rows');

                            % compute variance (diagonal term)
                            Covariance(mm,mm,rr) = Covariance(mm,mm,rr) + QoICoeffs(QoIMatchIndex)'*currCoeffs(currMatchIndex);

                        elseif mm > nn % covariance terms, copy to mm < nn
                            % create uqlab model for the quantity of interest
                            QoIModelOpts.mString = sprintf('(X(%i)-%.5e).*(X(%i)-%.5e)',mm,Mean(rr,mm),nn,Mean(rr,nn));
                            QoIModel = uq_createModel(QoIModelOpts, '-private');

                            % project QoI
                            QoIIndices = zeros(4,M);
                            QoIIndices(2,mm) = 1; QoIIndices(3,nn) = 1;
                            QoIIndices(4,mm) = 1; QoIIndices(4,nn) = 1;
                            QoICoeffs = projectQoI(currExpansion,QoIModel,QoIIndices);

                            % normalize c coefficient
                            QoICoeffs = QoICoeffs*currPriorMass;

                            % keep only polynomials present in both bases
                            QoIMatchIndex = ismember(QoIIndices,currIndices,'rows');
                            currMatchIndex = ismember(currIndices,QoIIndices,'rows');

                            % compute covariance (off-diagonal term)
                            Covariance(mm,nn,rr) = Covariance(mm,nn,rr) + QoICoeffs(QoIMatchIndex)'*currCoeffs(currMatchIndex);
                            Covariance(nn,mm,rr) = Covariance(mm,nn,rr); % symmetry of covariance matrix
                        end
                    end
                end
            end
        end
        Covariance(:,:,rr) = Covariance(:,:,rr)/Evidence(rr);
    end
% return QoI
postProc.Covariance = Covariance;

% compute correlation matrix (max refine only)
Cov = Covariance(:,:,end);
D = diag(sqrt(diag(Cov)));
Corr = D*Cov*D;

% return results
postProc.Dependence.Cov = Cov;
postProc.Dependence.Corr = Corr;
end

%% Return to Results field
module.Results.PostProc = postProc;
end

function coeffsQoI = projectQoI(currPCE,QoIModel,indices)
% project the quantity of interest model onto the polynomial basis
% init
metaOptsCurr.Type = 'Metamodel';
metaOptsCurr.MetaType = 'PCE';
metaOptsCurr.FullModel = QoIModel;
metaOptsCurr.Input = currPCE.Internal.Input;
metaOptsCurr.Method = 'OLS';%'Quadrature';
metaOptsCurr.ExpDesign.NSamples = 1000;
metaOptsCurr.Display = 0; %turn off diplay

% multi-indices
metaOptsCurr.Degree = max(sum(indices,2));
metaOptsCurr.TruncOptions.MaxInteraction = max(sum(indices ~= 0,2));
%metaOptsCurr.TruncOptions.Custom = indices;

% project
QoIPCE = uq_createModel(metaOptsCurr,'-private');

% extract coeffs and basis
coeffsQoI = QoIPCE.PCE.Coefficients;
indicesQoI = QoIPCE.PCE.Basis.Indices;

% keep only relevant indices
matchIndex = ismember(indicesQoI,indices,'rows');
coeffsQoI = coeffsQoI(matchIndex);
end