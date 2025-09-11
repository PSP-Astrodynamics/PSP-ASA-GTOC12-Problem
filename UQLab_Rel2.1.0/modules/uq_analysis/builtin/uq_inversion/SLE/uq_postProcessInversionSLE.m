function module = uq_postProcessInversionSLE(module, varargin)
% UQ_POSTPROCESSINVERSIONSLE post-processes an inverse analysis carried out
%    with the Bayesian inversion module of UQLab and the SLE solver.
%
%    UQ_POSTPROCESSINVERSIONSLE(MODULE, NAME, VALUE) allows to choose
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
%                             default: 'Mean'
%       'dependence'          Estimates the posterior correlation and
%                             coviariance matrix
%                             - Logical 
%                             default : false
%       'parameters'          Which parameters to consider 
%                             - Integer vector
%                             default : 1:M
%
% See also: UQ_PRINT_UQ_INVERSION, UQ_DISPLAY_UQ_INVERSION

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_inversion')
    error('uq_postProcessInversionSLE only operates on objects of type ''Inversion''') 
end

%check if SLE Solver
if ~strcmp(module.Internal.Solver.Type, 'SLE')
    error('No results to post-process')
end

%% Initialization
% extract PCE
myPCE = module.Results.SLE;
M = length(myPCE.Internal.Input.Marginals);

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

%% Check for input arguments
%set optional arguments
parse_keys = {'evidence', 'pointestimate','dependence','parameters'};
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

%% Computing QoIs
% EVIDENCE
if evidence_flag
    % get constant poly coefficient
    constPoly = myPCE.PCE.Coefficients(1);
    
    % compute evidence
    Evidence = constPoly;
    
    % Return QoI
    postProc.Evidence = Evidence;
    
    % Also return handle to posterior
    postProc.Posterior = @(x) uq_evalModel(myPCE, x).*module.Prior(x)./Evidence;
end

% MEAN
% loop over nodes
if any(strcmpi(pointEstimate,'mean'))
    Mean = nan(1, M);

    % init
    coeffs = myPCE.PCE.Coefficients;
    indices = myPCE.PCE.Basis.Indices;

    % loop over dimensions
    for mm = params        
        % create uqlab model for the quantity of interest
        QoIModelOpts.mString = sprintf('X(%i)',mm);
        QoIModel = uq_createModel(QoIModelOpts, '-private');

        % project QoI
        QoIIndices = zeros(2,M); QoIIndices(2,mm) = 1;
        QoICoeffs = projectQoI(myPCE, QoIModel,QoIIndices);

        % keep only polynomials present in QoIIndices basis
        QoIMatchIndex = ismember(QoIIndices,indices,'rows');
        currMatchIndex = ismember(indices,QoIIndices,'rows');

        % compute mean
        Mean(1,mm) = QoICoeffs(QoIMatchIndex)'*coeffs(currMatchIndex);
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
    Covariance = nan(M, M);
    
    % init
    coeffs = myPCE.PCE.Coefficients;
    indices = myPCE.PCE.Basis.Indices;

    % loop over dimensions
    for mm = params
        for nn = params
            if mm == nn % variance terms
                % create uqlab model for the quantity of interest
                QoIModelOpts.mString = sprintf('(X(%i)-%.5e).^2',mm,Mean(1,mm));
                QoIModel = uq_createModel(QoIModelOpts, '-private');

                % project QoI
                QoIIndices = zeros(3,M);
                QoIIndices(2,mm) = 1; QoIIndices(3,mm) = 2;
                QoICoeffs = projectQoI(myPCE,QoIModel,QoIIndices);

                % keep only polynomials present in QoIIndices basis
                QoIMatchIndex = ismember(QoIIndices,indices,'rows');
                currMatchIndex = ismember(indices,QoIIndices,'rows');

                % compute variance (diagonal term)
                Covariance(mm,mm) = QoICoeffs(QoIMatchIndex)'*coeffs(currMatchIndex);

            elseif mm < nn % covariance terms, compute only once and copy to mm > nn
                % create uqlab model for the quantity of interest
                QoIModelOpts.mString = sprintf('(X(%i)-%.5e).*(X(%i)-%.5e)',mm,Mean(1,mm),nn,Mean(1,nn));
                QoIModel = uq_createModel(QoIModelOpts, '-private');

                % project QoI
                QoIIndices = zeros(4,M);
                QoIIndices(2,mm) = 1; QoIIndices(3,nn) = 1;
                QoIIndices(4,mm) = 1; QoIIndices(4,nn) = 1;
                QoICoeffs = projectQoI(myPCE,QoIModel,QoIIndices);

                % keep only polynomials present in both bases
                QoIMatchIndex = ismember(QoIIndices,indices,'rows');
                currMatchIndex = ismember(indices,QoIIndices,'rows');

                % compute covariance (off-diagonal term)
                Covariance(mm,nn) = QoICoeffs(QoIMatchIndex)'*coeffs(currMatchIndex);
                Covariance(nn,mm) = Covariance(mm,nn); % symmetry of covariance matrix
            end
        end
    end
    Covariance = Covariance/Evidence;
    
    % return QoI
    postProc.Covariance = Covariance;

    % compute correlation matrix, only if all dimensions were considered
    if all(params == 1:M)
        Cov = Covariance;
        D = diag(sqrt(diag(Cov)));
        Corr = D*Cov*D;
    else
        Corr = nan(M, M);
    end

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