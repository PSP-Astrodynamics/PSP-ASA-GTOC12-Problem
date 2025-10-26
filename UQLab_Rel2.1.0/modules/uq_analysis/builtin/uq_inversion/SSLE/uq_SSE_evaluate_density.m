function [X, YPrior, YPosterior] = uq_SSE_evaluate_density(obj, varargin)
% UQ_SSE_EVALUATE_DENSITY evaluates the SSE-based prior and posterior 
%    density
%
%    UQ_SSE_EVALUATE_DENSITY(OBJ, NAME, VALUE) allows to choose
%    more advanced evaluation options by specifying Name/Value pairs:
%
%       Name               VALUE
%       'maxrefine'        Maximum considered refinement stage
%                          - Integer
%                          default : Inf
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
%       [X, YPRIOR, YPOSTERIOR] = UQ_SSE_EVALUATE_DENSITY(...) returns the 
%       evaluations and axis
%       handles.
%                          
% See also: UQ_DISPLAY_UQ_INVERSION_SSLE

%% Default behavior
% maxrefine
Default.MaxRefine = Inf;
% dimensions
Default.dimensions = 1:obj.SSE.Input.Dim; %all
% discretization
Default.NDiscr = 100;
% evidence
Default.evidence = 1;

%% Check for input arguments
%set optional arguments
if nargin > 1
    % vargin given
    parse_keys = {'maxrefine','dimensions','discretization','evidence'};
    parse_types = {'p','p','p','p'};
    % make NAME lower case
    varargin(1:2:end) = lower(varargin(1:2:end));
    [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
else
    % no varargin, use default options
    uq_cline{1} = Default.MaxRefine;
    uq_cline{2} = Default.dimensions;
    uq_cline{3} = Default.NDiscr;
    uq_cline{4} = Default.evidence;
end

% 'maxrefine' 
if ~strcmp(uq_cline{1}, 'false')
    maxrefine = uq_cline{1};
else
    maxrefine = Default.MaxRefine;
end

% 'dimensions'
if ~strcmp(uq_cline{2}, 'false')
    dimensions = uq_cline{2};
else
    dimensions = Default.dimensions;
end

% 'discretization'
if ~strcmp(uq_cline{3}, 'false')
    NDiscr = uq_cline{3};
else
    NDiscr = Default.NDiscr;
end

% 'evidence'
if ~strcmp(uq_cline{4}, 'false')
    evidence = uq_cline{4};
else
    evidence = Default.evidence;
end

%% Initialize
% extract SSE
mySSE = obj.SSE;
myInput = mySSE.Input.Original;

% properties
NDim = mySSE.Input.Dim;
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
            likeliVals = evalSSE(mySSE, currXVals, 'maxrefine', maxrefine, 'vardim', dd);
            % yVals
            currYVals = likeliVals.*priorVals/evidence;

            % store
            YPrior{ii,jj} = priorVals;
            YPosterior{ii,jj} = currYVals;
        elseif ii > jj %&& 1 == 3
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
            likeliVals = evalSSE(mySSE, currx, 'maxrefine', maxrefine, 'vardim', [dd,ee]);
            % yVals
            currYVals = likeliVals.*priorVals/evidence;
            
            % store
            YPrior{ii,jj} = reshape(priorVals, NDiscr, NDiscr);
            YPosterior{ii,jj} = reshape(currYVals, NDiscr, NDiscr);
        end
    end
end
end