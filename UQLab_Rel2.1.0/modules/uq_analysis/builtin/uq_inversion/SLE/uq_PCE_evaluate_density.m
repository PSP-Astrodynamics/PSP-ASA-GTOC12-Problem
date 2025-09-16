function [X, YPrior, YPosterior] = uq_PCE_evaluate_density(obj, varargin)
% UQ_PCE_EVALUATE_DENSITY evaluates the PCE-based prior and posterior 
%    density
%
%    UQ_PCE_EVALUATE_DENSITY(OBJ, NAME, VALUE) allows to choose
%    more advanced evaluation options by specifying Name/Value pairs:
%
%       Name               VALUE
%
%       'dimensions'       Which dimensions to consider
%                          - Integer or 'all'
%                          default : 'all'
%
%       'NDiscr'           Number of discretization points
%                          - Integer
%                          default : 100
%
%       'evidence'         Supply evidence for normalization
%                          - Integer
%                          default : 1
%
%       [X, YPRIOR, YPOSTERIOR] = UQ_PCE_EVALUATE_DENSITY(...) returns the 
%       evaluations and axis
%       handles.
%                          
% See also: UQ_DISPLAY_UQ_INVERSION_SSLE

%% Default behavior
% dimensions
Default.dimensions = 1:length(obj.Internal.Input.Marginals); %all
% discretization
Default.NDiscr = 100;
% evidence
Default.evidence = 1;

%% Check for input arguments
%set optional arguments
if nargin > 1
    % vargin given
    parse_keys = {'dimensions','discretization','evidence'};
    parse_types = {'p','p','p'};
    % make NAME lower case
    varargin(1:2:end) = lower(varargin(1:2:end));
    [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
else
    % no varargin, use default options
    uq_cline{1} = Default.dimensions;
    uq_cline{2} = Default.NDiscr;
    uq_cline{3} = Default.evidence;
end

% 'dimensions'
if ~strcmp(uq_cline{1}, 'false')
    dimensions = uq_cline{1};
else
    dimensions = Default.dimensions;
end

% 'discretization'
if ~strcmp(uq_cline{2}, 'false')
    NDiscr = uq_cline{2};
else
    NDiscr = Default.NDiscr;
end

% 'evidence'
if ~strcmp(uq_cline{3}, 'false')
    evidence = uq_cline{3};
else
    evidence = Default.evidence;
end

%% Initialize
% extract PCE
myPCE = obj;
myInput = myPCE.Internal.Input;

% properties
NDisplayDim = length(dimensions);

%% Prepare display data
% xvals matrix
X = zeros(NDiscr, NDisplayDim);
QuantileLimit = 1e-6;
for ii = 1:length(dimensions)
    dd = dimensions(ii);
    %define initial bounds by inverse cdf of the marginal
    lowerBound = uq_invcdfFun(QuantileLimit, myInput.Marginals(dd).Type, myInput.Marginals(dd).Parameters);
    upperBound = uq_invcdfFun(1-QuantileLimit, myInput.Marginals(dd).Type, myInput.Marginals(dd).Parameters);
    X(:,ii) = linspace(lowerBound,upperBound,NDiscr)';
end

% evaluate SSLE
YPrior = cell(NDisplayDim,NDisplayDim);
YPosterior = cell(NDisplayDim,NDisplayDim);
for ii = 1:length(dimensions)
    for jj = 1:length(dimensions)
        if ii == jj
            % extract dimension
            dd = dimensions(ii);
            % evaluate
            currXVals = X(:,ii);
            % prior
            priorVals = uq_pdfFun(currXVals, myInput.Marginals(dd).Type, myInput.Marginals(dd).Parameters);
            % evaluate likelihood
            likeliVals = evalPCE_custom(myPCE, currXVals, 'vardim', dd);
            % yVals
            currYVals = likeliVals.*priorVals/evidence;

            % store
            YPrior{ii,jj} = priorVals;
            YPosterior{ii,jj} = currYVals;
        elseif ii > jj
            % extract dimension
            dd = dimensions(ii);
            ee = dimensions(jj);
            % evaluate
            currX1Vals = X(:,ii);
            currX2Vals = X(:,jj);
            [X1,X2] = meshgrid(currX1Vals,currX2Vals);
            % Prepare X matrix
            x1 = reshape(X1,[],1);
            x2 = reshape(X2,[],1);
            currx = [x1, x2];
            % prior
            priorVals = uq_pdfFun(x1, myInput.Marginals(dd).Type, myInput.Marginals(dd).Parameters)...
                .*uq_pdfFun(x2, myInput.Marginals(ee).Type, myInput.Marginals(ee).Parameters);
            % evaluate likelihood
            likeliVals = evalPCE_custom(myPCE, currx, 'vardim', [dd,ee]);
            % yVals
            currYVals = likeliVals.*priorVals/evidence;
            
            % store
            YPrior{ii,jj} = reshape(priorVals, NDiscr, NDiscr);
            YPosterior{ii,jj} = reshape(currYVals, NDiscr, NDiscr);
        end
    end
end
end

%% Additional functions
function Y = evalPCE_custom(myPCE, X, varargin)
% evaluate PCE at points X and possibly marginalize over the non-DIM 
% dimensions
if nargin > 2 && ~isempty(varargin)
    % vargin given
    parse_keys = {'vardim'};
    parse_types = {'p'};
    % make NAME lower case
    varargin(1:2:end) = lower(varargin(1:2:end));
    [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
else
    % no vargin, use default options
    nOpts = 1;
    uq_cline = cell(nOpts,1);
    for ii = 1:nOpts
        uq_cline{ii} = 'false';
    end
end

% 'varDim' option includes only the specified dimensions
if ~strcmp(uq_cline{1}, 'false')
    % dimensions to consider
    varDim_flag = true;
    dims = uq_cline{1};
else
    % consider all dimensions
    varDim_flag = false;
    dims = 1:myPCE.Input.Dim;
end

if ~varDim_flag
    % check whether X includes constants or not and remove constants if yes
    if size(X,2) > myPCE.Runtime.MnonConst 
        X = X(:,myPCE.Runtime.nonConstIdx);
    end
end

% scale currY with normalization depending on
% excluded dimensions
if varDim_flag
    % prepare subexpansion
    subExpansion = createSubExpansion(myPCE, dims);

    % evaluate subexpansion
    Y = uq_evalModel(subExpansion,X);
else
    % evaluate Expansion
    Y = uq_evalModel(myPCE,X);
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