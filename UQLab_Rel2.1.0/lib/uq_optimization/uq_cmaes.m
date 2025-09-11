function [xstar, fstar, exitflag, output] = uq_cmaes(fun, x0, sigma0, lb, ub, options)
% UQ_CMAES finds an unconstrained minimum of a multi-dimensional function by CMA-ES.
%   UQ_CMAES implements a Covariance Matrix Adaptation - Evolution Strategy
%   (CMAES) to solve problems of the following form:
%   XSTAR = argmin F(X), where LB <= X <= UB.
%             X
%
%   XSTAR = UQ_CMAES(FUN, X0, SIGMA0) finds a local minimizer of
%   the function FUN with X0 as the starting point and SIGMA0 as
%   the initial coordinate-wise standard deviation.
%
%   XSTAR = UQ_CMAES(FUN, X0, SIGMA0, LB, UB) defines a set of lower 
%   and upper bounds such that LB(i) <= XSTAR(i) <= UB(i). If LB and UB are
%   finite and X0 = [] and/or SIGMA0 = [], the center of the search space
%   (LB(i)+UB(i))/2 and 1/6 of the search space width, i.e.,
%   (UB(i)-LB(i))/6 are used as X0(i) and SIGMA0(i), respectively.
%
%   XSTAR = UQ_CMAES(FUN, X0, SIGMA0, LB, UB, OPTIONS) minimizes
%   with the default optimization options replaced by the values
%   in the OPTIONS structure :
%       .lambda         : Population size - Integer,
%                         default: 4 + floor(3*log(nvars))
%       .mu             : Parent number - Integer,
%                         default: floor(lambda/2)
%       .recombination  : Weight computation - String:
%                           'equal'       : Assigns same weight to all
%                                           parents regardless of their 
%                                           rank.
%                           'linear'      : Assigns weights that varies
%                                           linearly with respect to 
%                                           the parents rank.
%                           'superlinear' : Assigns weight that varies
%                                           superlinearly with respect to 
%                                           the parent ranks.
%                         default: 'superlinear'
%       .boundsHandling : Strategy how to handle out of bounds sample
%                         points - String: 
%                           'resampling'  : Resamples out-of-bound sample
%                                           points.
%                           'penalization : Projects out-of-bound sample 
%                                           points and penalize the
%                                           corresponding objective
%                                           function values.
%                         default: 'resampling'.
%       .Display        : Display options - String:
%                           'none' : Displays no output.
%                           'iter' : Displays output at each iteration.
%                           'final': Displays only the final output.
%                         default: 'final'.
%       .isVectorized   : Flag indicating whether the objective (fitness)
%                         function is vectorized - Logical,
%                         default: true.
%       .MaxIter        : Maximum number of generations - Integer,
%                         default: floor(1e3*(nvars+5)^2/sqrt(lambda))
%       .nStallMax      : Maximum number of stall generations - Integer,
%                         default: max(70, 10 + ceil(30*nvars/lambda))
%       .TolFun         : Convergence tolerance on FUN - Double,
%                         default: 1e-12.
%       .TolX           : Convergence tolerance on X - Double,
%                         default: 1e-11*max(sigma0).
%       .MaxFunEval     : Maximum number of function evaluations - Integer,
%                         default: Inf. 
%       .keepCDiagonal  : Keep the covariance matrix C diagonal - Integer:
%                           <= 0 : C is never diagonal.
%                              1 : C is always kept diagonal.
%                            > 1 : C is kept diagonal for the first 
%                                  keepCDiagonal iterations only.
%                         default: 0.
%       .isActiveCMA    : Update the covariance matrix in case of
%                         successive unsuccessful trials - Logical,
%                         default: true.
%       .Strategy       : Strategy parameters, already optimized.
%                         It is strongly advised not to modify any of them
%                         - Structure:
%                           .cc   : Double, default: 4/(nvars+4).
%                           .ccov : Double, default: 2/(nvars + sqrt(2))^2.
%                           .cs   : Double, default: 4/(nvars+4).
%                           .ds   : Double, default: 1/cs + 1.
%
%   [XSTAR,FSTAR] = UQ_CMAES(FUN, X0, SIGMA0,...) additionally returns 
%   the value of the objective function FSTAR at the solution XSTAR.
%
%   [XSTAR,FSTAR,EXITFLAG] = UQ_CMAES(FUN, X0, SIGMA0,...) additionally 
%   returns an exit flag that indicates the termination condition:
%       1 : Maximum number of generations (MaxIter) is reached.
%       2 : Maximum number of stall generations (nStallMax) is reached.
%       3 : Maximum number of function evaluations (MaxFunEval) is reached.
%       4 : Range of FUN over nStallMax generations is smaller than TolFun.
%       5 : Step Size is smaller than TolX.
%      <0 : No feasible solution was found.
%
%   [XSTAR,FSTAR,EXITFLAG,OUTPUT] = UQ_CMAES(FUN, X0, SIGMA0,...) 
%   additionally returns a structure with additional information about 
%   the optimization process:
%       .message        : Exit message - String.
%       .lastgeneration : Output from the last generation - Structure:
%                           .Xmean       : Mean of the final Gaussian
%                                          distribution - 1-by-M Double.
%                           .Xbest       : Best solution from the last
%                                          generation - 1-by-M Double.
%                           .bestfitness : Best objective function value
%                                          from the last generation -
%                                          Double.
%       .iterations     : Total number of generations - Integer.
%       .funccount      : Total number of objective function evaluations - 
%                         Integer.
%       .History        : History of the optimization process
%                         (X, FUN(X) at each iteration) - Structure:
%                           .Xmean     : History of the means of the
%                                        successive Gaussian distributions
%                                        - Matrix Double.
%                           .sigma     : History of the global step size
%                                        at each iteration - Matrix Double.
%                           .Xbest     : History of the best sampled point
%                                        at each iteration - Matrix Double.
%                           .fitbest   : History of the best objective
%                                        function value at each iteration -
%                                        Vector Double.
%                           .fitmedian : History of the median of the
%                                        objective function values on each
%                                        iteration - Vector Double.
%
%   Additional notes:
%   
%   - Mandatory parameters are {FUN,X0,SIGMA0} or {FUN,LB,UB}.
%     Optional parameters can be replaced by [] in the call
%     to the function.
%
%   References:
%
%   - Hansen, N. (2011). The CMA Evolution Strategy: A tutorial, June 2011.
%   - Hansen, N. and Ostermeier, A. (2001). Completely derandomized
%     self-adaptation in evolution strategies, In Evolutionary computation
%     9(2) pp. 159-195, 2001.
%
%   See also: UQ_GSO, UQ_CEO, UQ_1P1CMAES, UQ_C1P1CMAES

%% Pre-processing and parameters checking

% Check the number of input arguments
try
    narginchk(3,6)
catch ME
    error('Wrong number of input arguments!')
end
if nargin < 6
    options = [];
    if nargin < 5
        ub = [];
        if nargin < 4
            lb = [];
        end
    end
end

% Consistency checks and get the number of variables
% Check if given input is a row or column vector
% (for multi-dimensional inputs)
if isempty(x0) && ( isempty(lb) || isempty(ub) )
    error('Either an initial point or bounds should be given!')
elseif isempty(x0) && ~isempty(lb) && ~isempty(ub)
    % Initial points is not given but bounds are
    % Make sure lb and ub are of equal sizes
    if length(lb) ~= length(ub)
        error('Dimension mismatch between lb and ub!')
    end
    nvars = length(lb(:));
    x0 = (lb+ub)/2;
    if any(isnan(x0)) || any(~isfinite(x0))
        error(['Bounds should have finite values '
            'if an initial point is not given!'])
    end
elseif ~isempty(x0) && ( isempty(lb) || isempty(ub) )
    % x0 is given but not lb and ub
    nvars = length(x0(:));
elseif ~isempty(x0) && ~isempty(lb) && ~isempty(ub)
    % x0, lb and ub are given. Check that dimensions match
    % Make sure lb and ub are of equal sizes
    if length(lb) ~= length(ub)
        error('Dimension mismatch between lb and ub!')
    end
    nvars = length(x0(:));
    if length(lb) ~= nvars && length(lb) == 1
        lb = repmat(lb,nvars,1);
        ub = repmat(ub,nvars,1);
    end
    % Check that initial point is in bounds. Otherwise re-sample a new one:
    if any(x0 < lb) || any(x0 > ub)
        warning('Initial points in not in bounds')
        fprintf(['Calculating a new one: '...
            'random uniform sample on the search space'])
        x0 = rand(nvars,1) .* (ub-lb) + lb;
    end
end

% Make everything column
if isrow(x0)
    FunTakesRow = true;
    x0 = x0(:);
else
    FunTakesRow = false;
end
% Now that all the consistency check is done, 
% set lb and ub to Inf in case they are empty
if isempty(lb), lb = -Inf*ones(nvars,1) ; end
if isempty(ub), ub = Inf*ones(nvars,1) ; end
% Set everything in row
if isrow(lb), lb = lb(:); end
if isrow(ub), ub = ub(:); end

% In case inputs are transposed,
% make sure that the function handles handle it properly
if FunTakesRow
    funfcn = @(x)fun(x');
else
    funfcn = @(x)fun(x);
end

%% Asigning default parameters values

% 1. Selection parameters
if ~isfield(options,'lambda')
    lambda = 4 + floor(3*log(nvars));
else
    lambda = options.lambda;
end
if ~isfield(options, 'mu')
    mu = floor(lambda/2);
else
    mu = options.mu;
end
if ~isfield(options,'recombination')
    recombination = 'superlinear';
else
    recombination = options.recombination;
end
switch recombination
    case 'equal'
        weights = ones(mu,1);
    case 'linear'
        weights = mu + 0.5 - (1:mu)';
    case 'superlinear'
        weights = log(max(mu,lambda/2) + 0.5) - log(1:mu)';
    otherwise
        if strcmpi(Display,'iter')
            warning(['Unknown recombination type. '...
                'Default (superlinear) is used'])
        end
        weights = log(max(mu,lambda/2) + 0.5) - log(1:mu)';
end
% Normalize weights
weights = weights / sum(weights);
% Variance effective size of mu
mueff = sum(weights)^2 / sum(weights.^2);

% 2. General options
if isempty(options)
    options = struct;
end
if ~isfield(options,'Display')
    Display = 'final';
else
    Display = options.Display;
end

% 3. Convergence criteria
if ~isfield(options,'MaxIter')
    MaxIter = floor(1e3*(nvars+5)^2/sqrt(lambda));
else
    MaxIter = options.MaxIter;
end
if ~isfield(options,'nStallMax')
    nStallMax = max(70, 10 + ceil(30*nvars/lambda));
else
    nStallMax = options.nStallMax;
end
if ~isfield(options,'MaxFunEval')
    MaxFunEval = Inf;
else
    MaxFunEval = options.MaxFunEval;
end
if ~isfield(options,'TolX')
    if ~isempty(sigma0)
        TolX = 1e-11 * max(sigma0);
    else
        TolX = [];
    end
else
    TolX = options.TolX;
end
if ~isfield(options,'TolFun')
    TolFun = 1e-12; % Very conservative for practical purposes
else
    TolFun = options.TolFun;
end

% 4. Some other preferences setting
if ~isfield(options,'keepCDiagonal')
    keepCDiagonal = 0;
else
    keepCDiagonal = options.keepCDiagonal;
end
% Coefficients associated to the case where C is diagonal
if keepCDiagonal > 0 
    diagc1 = min(1, c1 * (nvars+1.5)/3);
    diagcmu = min(1 - diagc1, cmu * (nvars+1.5)/3);
end
if ~isfield(options,'isVectorized')
    isVectorized = true;
else
    isVectorized = options.isVectorized;
end
if ~isfield(options,'isActiveCMA')
    isActiveCMA = true;
else
    isActiveCMA = options.isActiveCMA;
end
if ~isfield(options, 'boundsHandling')
    bounds.handling = 'resampling';
else
    bounds.handling = options.boundsHandling;
end

% 5. Covariance adaptation parameters
if ~isfield(options,'Strategy')
    options.Strategy = struct;
end
% Step-size control
if ~isfield(options.Strategy,'cs')
    cs = (mueff+2) / (nvars+mueff+5);
else
    cs = options.Strategy.cs;
end
if ~isfield(options.Strategy,'ds')
    ds = 1 + 2 * max(0,sqrt((mueff-1)/(nvars+1)) - 1 ) + cs;
else
    ds = options.Strategy.ds;
end
% Covariance matrix adaptation
if ~isfield(options.Strategy,'cc')
    cc = (4 + mueff/nvars) / (nvars+4+2*mueff/nvars);
else
    cc = options.Strategy.cc;
end
if ~isfield(options.Strategy,'c1')
    c1 = 2 / ((nvars+1.3)^2 + mueff);
else
    c1 = options.Strategy.c1;
end
if ~isfield(options.Strategy,'cmu')
    cmu = min(1 - c1, 2 * (mueff-2+1/mueff) / ((nvars+2)^2 + mueff));
else
    cmu = options.Strategy.cmu;
end

%% Checking inputs

if length(sigma0) ~= nvars && length(sigma0) > 1
    error('SIGMA0 should be either a scalar or a vector of size NVARS!')
else
    if length(sigma0) == 1 && nvars > 1
        sigma0 = repmat(sigma0, nvars, 1);
    else
        sigma0 = sigma0(:);
    end
end
if any(sigma0 <= 0)
    error('All components of sigma should be positive!')
end
if isempty(sigma0)
    sigma0 = (ub-lb)/6;
end
if ~isfinite(sigma0)
    error(['Initial step size should be finite! '...
        'If none is given, bounds should be finite'])
end
if max(sigma0)/min(sigma0) > 1e6
    error('Initial sigma is badly conditioned!')
end
if isempty(TolX)
    TolX = 1e-11 * max(sigma0);
end
if length(TolX(:)) ~= nvars && length(TolX(:)) > 1
    error('TOLX should be either a scalar or a vector of size NVARS!')
else
    if length(TolX) == 1 && nvars > 1
        TolX = repmat(TolX, nvars, 1);
    else
        TolX = TolX(:);
    end
end

%% Save some options for output
% Commented, only for diagnostic purposes.
% Internal.lambda = lambda;
% Internal.mu = mu;
% Internal.weights = weights;
% Internal.MaxIter = MaxIter;
% Internal.MaxFunEval = MaxFunEval;
% Internal.TolX = TolX;
% Internal.TolFun = TolFun;
% Internal.nStallMax = nStallMax;

%% Initialization

% Expectation of ||N(0,1)|| in dimension nvars
chiN = sqrt(nvars) * (1 - 1/(4*nvars) + 1/(21*nvars^2));

xmean = x0;          % Mean of the Gaussian sampling distribution 
sigma = max(sigma0); % Global step size

% Internal CMA-ES parameters
ps = zeros(nvars,1); % Evolution path, p_sigma
pc = zeros(nvars,1); % Evolution path, p_c

% Counters
nStall = 0;
generation = 0;
fcount = 1;

% Initial objective function value
f = funfcn(xmean);

% If using diagonal C, use eigenvalue decomposition
diagD = sigma0/max(sigma0);
diagC = diagD.^2;
B = eye(nvars); % Eigenvectors
D = eye(nvars); % Eigenvalues
BD = B * repmat(diagD', nvars, 1);
C = diag(diagC);

if keepCDiagonal <= 0
    flagDiagonal = false;
else
    flagDiagonal = true;
end

% History records
% Preallocate
history.Xmean = NaN * ones(nvars,MaxIter+1);
history.sigma = NaN * ones(1,MaxIter+1);
history.Xbest = NaN * ones(nvars,MaxIter+1);
history.fitmedian = NaN * ones(1,MaxIter+1);
history.fitbest = NaN * ones(1,MaxIter+1);
% Initialize
history.Xmean(:,1) = xmean;
history.sigma(:,1) = sigma;
history.Xbest(:,1) = xmean;
history.fitmedian(:,1) = f;
history.fitbest(:,1) = f;

% Best records
x_best_ever = xmean;
f_best_ever = f;
f_best_mem = NaN * ones(1,nStallMax);

% Bounds handling
if strcmpi(bounds.handling, 'penalization')
    % Just as in cmaes.m by Hansen et al.
    if any(isfinite(lb)) || any(isfinite(ub))
        bounds.active = true;
        bounds.isscaled = true;
        bounds.initialized = 0;
        bounds.weights = zeros(nvars,1);
        bounds.deltafitness = 1;
        bounds.idxpoints = [];
        bounds.fitness = [];
        bounds.notinitial = 0;
    else
        bounds.active = 0;
    end
    % Initial scaling of the weights
    if bounds.isscaled == 1
        bounds.scale = diagC / mean(diagC);
    else
        bounds.scale = zeros(nvars,1);
    end
    % Find indices of bounded dimensions
    idx = (lb > -Inf) | (ub < Inf);
    bounds.boundedcoord = zeros(nvars,1);
    bounds.boundedcoord((idx==1)) = 1;
elseif strcmpi(bounds.handling, 'resampling')
    if any(isfinite(lb)) || any(isfinite(ub))
        bounds.active = true;
        bounds.maxtrials = 1e3 * nvars^2; % Note: Random choice...
    else
        bounds.active = false;
    end
else
    error('Unknown bounds handling options');
end

% Exit flag and message
output.message = sprintf('Maximum number of generations (%i) reached',...
    MaxIter);
exitflag = 1;

%% CMA-ES Optimization

% Display the header for the iterations
headerStringFirst = {'Median', 'Current pop', 'Stall'};
headerStringSecond = {'Generation', 'f-count', 'f(x)', 'best f(x)',...
    'Generations'};
if strcmpi(Display,'iter')
    fprintf('\n')
    fprintf('%32s %18s %7s\n', headerStringFirst{1:end})
    fprintf('%-12s %-12s %-13s %-13s %-11s\n',headerStringSecond{1:end})
    fprintf('%-12i %-12i %-13.6e %-13.6e %-11i\n',...
        generation, fcount, f, f, nStall);
end

% Optimization iteration
for generation = 1:MaxIter
    
    % Generate sample points
    z = randn(nvars,lambda);
    if ~flagDiagonal
        pop = repmat(xmean, 1, lambda) + sigma * (BD*z);
    else
        pop = repmat(xmean, 1, lambda) ...
            + repmat(sigma*diagD, 1, lambda) .* z;
    end
    
    % Handle bounds
    switch bounds.handling
        case 'resampling'
            % Find out of bounds samples
            [inbnd,idxbnd] = uq_checkBounds(pop, lb, ub);
            trials =  1;
            % Regenerate points until all are in the bounds.
            while ~isempty(idxbnd)
                trials = trials + 1;
                tmpz = randn(nvars,length(idxbnd));
                if keepCDiagonal
                    tmppop = repmat(xmean, 1, length(idxbnd)) ... 
                        + sigma * (BD*tmpz);
                else
                    tmppop = repmat(xmean, 1, length(idxbnd))...
                        + repmat(sigma*diagD, 1, length(idxbnd)) .* tmpz;
                end
                pop(:,idxbnd) = tmppop;
                z(:,idxbnd) = tmpz;
                [inbnd,idxbnd] = uq_checkBounds(pop, lb, ub);

                % If an in-bound sample point is not found after 
                % each 1e3 trials, print a warning
                if mod(trials,1000) == 0
                    if strcmpi(Display,'iter')
                        warning(['Sample in bounds not found '...
                            'after %i trials'],trials)
                        fprintf('Searching...\n')
                    end
                end
                
                % If no in-bound sample point is not found at all,
                % exit the loop
                if trials >= bounds.maxtrials
                    if strcmpi(Display,'iter')
                        warning(['Could not sample all-in-bound points '...
                            'after maximum allowed trials']);
                    end
                    break
                end
            end
            actualpop = pop;

        case 'penalization'
            if bounds.active
                actualpop = xintobounds(pop, lb, ub);
            else
                actualpop = pop;
            end
    end
    
    % Evaluate fitness function
    if isVectorized
        % The fitness function is vectorized: 
        % Evaluate all points at once
        fpop = funfcn(actualpop);
    else
        % The fitness function is not vectorized:
        % Evaluate one point at a time.
        fpop = NaN * ones(1,lambda);
        for k = 1:lambda
            fpop(:,k) = funfcn(actualpop(:,k));
        end
    end
    
    % Update counter for the model evaluation
    fcount = fcount + lambda;
    
    % Handle bounds as constraints - 
    % following implementation of cmaes.m (for penalization, see
    % http://cma.gforge.inria.fr/cmaes.m , last accessed 04/12/2018) 
    switch bounds.handling
        case 'resampling'
            adjustedfpop = fpop;
        case 'penalization'
            if bounds.active
                val = quantile(fpop,[0.25,0.75]);
                val = (val(2)-val(1)) / (nvars*mean(diagC)*sigma^2);
                if ~isfinite(val)
                    % warning('Non-finite fitness range');
                    val = max(bounds.deltafitness);
                elseif val == 0
                    val = min(bounds.deltafitness);
                elseif bounds.notinitial == 0
                    % val keeps its value and the parameters below are
                    % initialized/set
                    bounds.deltafitness = [];
                    bounds.notinitial = 1;
                end
                
                if length(bounds.deltafitness) < 20 + (3*nvars) / lambda
                    bounds.deltafitness = [bounds.deltafitness val]; 
                else
                    bounds.deltafitness = [bounds.deltafitness(2:end) val];
                end
                [adjusted_xmean,adjusted_xmean_idx] = xintobounds(xmean,...
                    lb, ub);
                
                if bounds.initialized == 0
                    if any(adjusted_xmean_idx)
                        % Number taken as such from the original 
                        % cmaes.m implementation (Hansen et al.)
                        bounds.weights(find(bounds.boundedcoord)) = ...
                            2.0002 * median(bounds.deltafitness); 
                        if bounds.isscaled
                            dd = diagC;
                            idx = find(bounds.boundedcoord);
                            dd = diagC(idx)/mean(diagC);
                            bounds.weights(idx) = bounds.weights(idx) ./ dd;
                        end
                        if bounds.notinitial && generation > 2
                            bounds.initialized = 1;
                        end
                    end
                end
                
                % Increase weights
                if any(adjusted_xmean_idx)
                    adjusted_xmean = xmean - adjusted_xmean;
                    idx = (adjusted_xmean_idx ~= 0 & abs(adjusted_xmean) ...
                        > 3 * max(1/(sqrt(nvars)*mueff)) * sigma * sqrt(diagC));
                    idx = idx & (sign(adjusted_xmean_idx) == sign(xmean-xold));
                    if ~isempty(idx)
                        bounds.weights(idx) = 1.2^(min(1,mueff/(10*nvars))) * bounds.weights(idx);
                    end
                    if bounds.isscaled
                        bounds.scale = exp(0.9 * (log(diagC) - mean(log(diagC))));
                    end
                end
                
                % Penalized fitness values
                bounds.penalty = (bounds.weights./bounds.scale)' *...
                    (actualpop-pop).^2;
                
                adjustedfpop = fpop + bounds.penalty;
            else
                adjustedfpop = fpop;
            end
    end
    
    % Sort raw fitness and 
    % get the best point ever (elitist adaptation of CMA)
    [sortedrawfitness,sortrawidx] = sort(fpop);
    if sortedrawfitness(1) < f_best_ever
        f_best_ever = sortedrawfitness(1);
        x_best_ever = actualpop(:,sortrawidx(1));
        nStall = 0;
    else
        nStall = nStall + 1;
    end
    
    % Sort fitness for actuall actual CMA-ES algorithm
    [sortedfitness,sortidx] = sort(adjustedfpop);
    % Compute new mean population
    xold = xmean;
    xmean = pop(:,sortidx(1:mu)) * weights;
    zmean = z(:,sortidx(1:mu)) * weights;

    % Cumulation: Update evolution path
    ps = (1-cs) * ps + (sqrt(cs * (2-cs) * mueff) * B * zmean);
    if sqrt(sum(ps.^2)) / sqrt(1 - (1-cs)^(2*(fcount/lambda))) / chiN < (1.4 + 2/(nvars+1))
        % Note: seems that sqrt(sum( .^2)) is faster than norm()
        hs = 1;
    else
        hs = 0;
    end
    pc = (1-cc) * pc + hs * sqrt(cc*(2-cc)*mueff/sigma) * (xmean-xold);
    
    % Adapt the covariance matrix
    acc = 0;
    accfinal = acc;
    if flagDiagonal
        diagC = (1-diagc1-diagcmu) * diagC + diagc1 ...
            * (pc.^2 + (1-hs) * cc * (2-cc) * diagC) ...
            + diagcmu * (diagC .* (z(:,sortidx(1:mu)).^2 * weights));
        diagD = sqrt(diagC);
    else
        y = (pop(:,sortidx(1:mu)) - repmat(xold, 1, mu))/sigma;
        if isActiveCMA
            % Compute coefficients for negative update as well
            % Note: Method is explained in Ref. []
            % Note: can't find the reference for parameters setting...
            amu = mu;
            amueff = mueff;
            acc = (1-cmu) * 0.25 * amueff / ((nvars+2)^1.5 + 2*amueff);
            accfinal = acc;
            aalpha = 0.5;
            zneg = z(:,sortidx(lambda:-1:lambda-amu+1));
            [arnorms,idxnorms] = sort(sqrt(sum(zneg.^2,1)));
            [ignore,idxnorms] = sort(idxnorms);  % inverse index
            arnormfacs = arnorms(end:-1:1) ./ arnorms;
            arnorms = arnorms(end:-1:1); % for the record
            zneg = zneg .* repmat(arnormfacs(idxnorms), nvars, 1);  % E x*x' is N
            ztemp = BD * zneg;
            Cneg = ztemp * (repmat(weights, 1, nvars) .* ztemp');
            Ccheck = zneg * (repmat(weights, 1, nvars) .* zneg');
            
            % Check for positive definiteness and modify accordingly
            if acc * arnorms(idxnorms).^2 * weights < 0.66
                maxeigenval = max(eig(Ccheck));
                accfinal = min(acc, (1-cmu) * (1-0.66)/maxeigenval);
            end
            % Update matrix C for active CMA-ES
            C = (1-c1-cmu+aalpha*accfinal)*C ...
                + c1 * (pc*pc' + (1-hs) * cc * (2-cc) *C ) ...
                + (cmu + (1-aalpha)*accfinal) * y ...
                    * (repmat(weights, 1, nvars) .* y') ...
                - accfinal * Cneg;
        else
            % Update matrix C without active CMA-ES
            C = (1-c1-cmu) * C ...
                + c1 * (pc*pc' + (1-hs) * cc * (2-cc) * C) ...
                + cmu * y * (repmat(weights, 1, nvars) .* y');
        end
    end
    
    % Adapt step-size
    sigma = sigma * exp(min(1, (cs/ds) * (sqrt(sum(ps.^2))/chiN - 1)));
    
    % Update B, D and BD
    % Eigenvalue decomposition is carried out only when not using 
    % diagonal C and after every n = lambda/(c1+cmu+accfinal)/(nvars*10) 
    % number of iterations
    if ~flagDiagonal ...
            && mod(generation,floor(lambda/(c1+cmu+accfinal)/nvars/10)) == 0
        C = triu(C) + triu(C,1)'; % Force symmetry
        [B,D] = eig(C);
        diagD = diag(D);
        % Check that there is no issue with the eigenvalue decomposition
        % Handling conditioning of C. Note that no reference was found.
        % This is taken from the MATLAB implementation of cmaes.
        % TODO: shall that be removed?
        if min(diagD) < 0
            % warning('Some eigenvalues are negative. Setting them to zero.');
            diagD(diagD<0) = 0;
            tmp = max(diagD)/1e14;
            C = C + tmp*eye(nvars);
            diagD = diagD + tmp*ones(nvars,1);
        end
        if max(diagD) > 1e14*min(diagD)
            % warning('Condition on C is at the upper limit 1e14. C is modified');
            tmp = max(diagD)/1e14 - min(diagD);
            C = C + tmp*eye(nvars);
            diagD = diagD + tmp*ones(nvars,1);
        end
        
        diagC = diag(C);
        diagD = sqrt(diagD);
        BD = B .* repmat(diagD', nvars, 1);
        if ~isreal(B) || ~isreal(D)
            % Warning('Matrix C is not well conditioned: Returns negative D or B values.') ;
            % fprintf('The algorithm will exit now and return best found solution so far') ;
            % Matrix C is not well conditioned, exit now, return the best
            % solution found so far, and do something for 
            % positive definiteness
            exitflag = -1;
            break
        end
    end
    
    if flagDiagonal && keepCDiagonal > 1 && keepCDiagonal <= generation
        flagDiagonal = false;
        B = eye(nvars);
        BD =diag(diagD);
        C = diag(diagC);
    end
    
    if any(abs(xmean - xmean + 0.2*sigma*sqrt(diagC)) < eps*abs(xmean))
        % warning('Standard deviation too small to renew population\n');
        if flagDiagonal
            diagC = diagC + (diagc1+diagcvmu) * (diagC .* ...
                (abs(xmean - xmean + 0.2*sigma*sqrt(diagC)) < eps*abs(xmean)));
        else
            C = C + (c1+cmu) * diag(diagC .* ...
                (abs(xmean - xmean + 0.2*sigma*sqrt(diagC)) < eps*abs(xmean)));
        end
        sigma = sigma * exp(0.05+cs/ds);
    end
    
    % If flatness, increase sigma
    if abs(sortedfitness(1)-sortedfitness(ceil(0.7*lambda))) < eps * abs(fpop)
        sigma = sigma * exp(0.2+cs/ds);
        % warning('Flatness detected, global step size sigma is increased slightly');
    end
    
    % Save history
    history.Xmean(:,generation+1) = xmean;
    history.sigma(:,generation+1) = sigma;
    history.Xbest(:,generation+1) = pop(:,sortidx(1));
    history.fitbest(:,generation+1) = sortedfitness(1);
    history.fitmedian(:,generation+1) = median(sortedfitness(1:mu));
    
    % Display output
    if strcmpi(Display,'iter')
        fprintf('%-12i %-12i %-13.6e %-13.6e %-11i\n',...
            generation, fcount, median(sortedfitness(1:mu)),...
            sortedrawfitness(1), nStall)
    end
    
    % Check stopping criteria
    % 2. Maximum number of stall generations has been reached.
    if nStall >= nStallMax
        exitflag = 2;
        output.message = sprintf(['Maximum number of stall generations '...
            '(%i) reached'],nStallMax);
        break
    end
    % 3. Maximum number of objective function evaluations has been reached.
    if fcount >= MaxFunEval
        exitflag = 3;
        output.message = sprintf(['Maximum number of objective function '...
            'evaluations (%i) reached'],MaxFunEval);
        break
    end
    % 4. Absolute maximum difference (range) in the objective function 
    %    values over generations is smaller than threshold 
    if generation <= nStallMax
        f_best_mem(generation) = sortedfitness(1);
    else
        % Remember the last F_best_ever after generation exceed nStallMax
        % and if the difference between the max and min of the objective 
        % function values (the range) over nStallMax is below TolFun,
        % then stop
        f_best_mem = [f_best_mem(2:end) sortedfitness(1)];
        if range(f_best_mem) <= TolFun
            exitflag = 4;
            output.message = sprintf(['Range of objective function values '...
                'is below tolerance (%g) over generations'],TolFun);
            break
        end
    end
    % 5. Step size is smaller than threshold.
    if all(sigma * max(abs(pc),sqrt(diag(C))) < TolX)
        exitflag = 5;
        output.message = sprintf(['Possible change in X '...
            'is below tolerance (%g)'],TolX(1));
        break
    end
    
end

%% Return results

% Print exit message
if strcmpi(Display,'iter') || strcmpi(Display,'final')
    switch exitflag
        case 1
            fprintf(['\nMaximum number of generations '...
                '(options.MaxIter) is reached.\n'])
        case 2
            fprintf(['\nMaximum number of stall generations '...
                '(options.nStallMax) is reached.\n'])
        case 3
            fprintf(['\nMaximum number of objective function '...
                'evaluations (options.MaxFunEval) is reached.\n'])
        case 4
            fprintf(['\nRange of FUN over nStallMax '...
                'is below options.TolFun.\n'])
        case 5
            fprintf('\nPossible change in X is below options.TolX.\n')
        case -1
            fprintf('\nNot converged. Not well defined.\n')
    end
    fprintf('obj. value = %12.6g \n',f_best_ever)
end

% Compute fitness at the final xmean
[isinbounds,idx] = uq_checkBounds(xmean, lb, ub);
if isinbounds
    fmean_final = funfcn(xmean);
    fcount = fcount + 1;
    if  fmean_final < f_best_ever
        f_best_ever = fmean_final;
        x_best_ever = xmean;
    end
end

% Return results
if FunTakesRow
    xstar = x_best_ever';
    history.Xbest = history.Xbest(:,1:generation+1)';
    history.Xmean = history.Xmean(:,1:generation+1)';
    history.fitmedian = history.fitmedian(:,1:generation+1)';
    history.fitbest = history.fitbest(:,1:generation+1)';
    history.sigma = history.sigma(:,1:generation+1)';
    output.lastgeneration.Xmean = history.Xmean(end,:);
    output.lastgeneration.Xbest = history.Xbest(end,:);
else
    xstar = x_best_ever;
    history.Xbest = history.Xbest(:,1:generation+1);
    history.Xmean = history.Xmean(:,1:generation+1);
    history.sigma = history.sigma(:,1:generation+1);
    history.fitmedian = history.fitmedian(:,1:generation+1);
    history.fitbest = history.fitbest(:,1:generation+1);
    output.lastgeneration.Xmean = history.Xmean(:,end);
    output.lastgeneration.Xbest = history.Xbest(:,end);
end

fstar = f_best_ever;

output.iterations = generation;
output.funccount = fcount;
output.lastgeneration.bestfitness = history.fitbest(end);
output.History = history;

% Comment out for diagnostic purpose
% output.Internal = Internal;

end

function [isinbounds, idx] = uq_checkBounds(x,lb,ub)
if isrow(x) && length(lb) > 1
    isinbounds = prod(bsxfun(@minus,lb,x).*bsxfun(@minus,x,ub) > 0,2);
else
    isinbounds = prod(bsxfun(@minus,lb,x).*bsxfun(@minus,x,ub) > 0,1);
end
idx = find(isinbounds == 0);

end

function [x,idx] = xintobounds(x, lbounds, ubounds)
%
% x can be a column vector or a matrix consisting of column vectors
%
  if ~isempty(lbounds)
    if length(lbounds) == 1
      idx = bsxfun(@lt,x,lbounds)
      x(idx) = lbounds;
    else
      arbounds = repmat(lbounds, 1, size(x,2));
      idx = bsxfun(@lt,x,arbounds) ;
      x(idx) = arbounds(idx);
    end
  else
    idx = 0;
  end
  if ~isempty(ubounds)
    if length(ubounds) == 1
      idx2 = bsxfun(@gt,x,ubounds);
      x(idx2) = ubounds;
    else
      arbounds = repmat(ubounds, 1, size(x,2));
      idx2 = bsxfun(@gt,x,arbounds) ;
      x(idx2) = arbounds(idx2);
    end
  else
    idx2 = 0;
  end
  idx = idx2 - idx; 
end