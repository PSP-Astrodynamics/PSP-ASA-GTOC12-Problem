function [xstar,fstar,exitflag,output] = uq_ceo(fun, x0, sigma0, lb, ub, options)
% UQ_CEO finds an unconstrained minimum of a multi-dimensional function by Cross-entropy method.
%   UQ_CEO implements a cross-entropy optimization (CEO) to solve problems
%   of the following form:
%   XSTAR = argmin F(X) where: LB <= X <= UB.
%             X
%
%   XSTAR = UQ_CEO(FUN, X0, SIGMA0) finds a local minimizer of the function
%   FUN with X0 as the starting point and SIGMA0 as the initial
%   variable-wise standard deviation.
%
%   XSTAR = UQ_CEO(FUN, X0, SIGMA0, LB, UB) defines a set of lower and
%   upper bounds such that LB(i) <= Xstar(i) <= UB(i). If LB and UB are
%   finite and X0 = [] and/or SIGMA0 = [], the center of the search space
%   (LB(i)+UB(i))/2 and 1/6 of the search space width, i.e.,
%   (UB(i)-LB(i))/6 are used as X0(i) and SIGMA0(i), respectively.
%
%   XSTAR = UQ_CEO(FUN,X0,SIGMA0,LB,UB,OPTIONS) minimizes with
%   the default optimization options replaced by the values
%   in the OPTIONS structure:
%      .Display     : Level of output display - String:
%                       'none' : No output.
%                       'iter' : Output at each iteration.
%                       'final': Only the final output.
%                     default: 'final'.
%      .isVectorized: Flag to decide if the objective function 
%                     is vectorized - Logical, default: true.
%      .MaxIter     : Maximum number of generations  - Integer,
%                     default: 100*nvars.
%      .nStallMax   : Maximum number of stall generations - Integer,
%                     default: 70.
%      .MaxFunEval  : Maximum number of function evaluation - Integer,
%                     default: Inf.
%      .TolFun      : Convergence tolerance on FUN - Double, default: 1e-3.
%      .TolSigma    : Convergence tolerance on SIGMA - Double,
%                     default: 1e-3.
%      .FvalMin     : Minimum possible value of FUN - Double,
%                     default: -Inf.
%      .nPop        : Population size - Integer, default: 100.
%      .quantElite  : Proportion of the population considered to be elite.
%                     This serves as a basis for the computation of 
%                     the next generation parameters - Double between 0 
%                     and 1, default: 0.05.
%      .alpha       : Internal parameter of CE - Double, default: 0.4.
%      .beta        : Internal parameter of CE - Double, default: 0.4.
%      .q           : Internal parameter of CE - Double, default: 10.
%
%   [XSTAR,FSTAR] = UQ_CEO(FUN, X0, SIGMA0,...) additionally returns 
%   the value of the objective function FSTAR at the solution XSTAR.
%
%   [XSTAR,FSTAR,EXITFLAG] = UQ_CEO(FUN, X0, SIGMA0,...) additionally
%   returns an exit flag that indicates the termination condition:
%       1 : Maximum number of generations (MaxIter) is reached.
%       2 : Maximum number of stall generations (nStallMax) is reached.
%       3 : Maximum number of function evaluations (MaxFunEval) is reached.
%       4 : Range of FUN over nStallMax generations is smaller than TolFun.
%       5 : Step Size is smaller than TOLSIGMA.
%       6 : Objective function value falls below FvalMin. 
%      <0 : No feasible solution was found.
%
%   [XSTAR,FSTAR,EXITFLAG,OUTPUT] = UQ_CEO(FUN, X0, SIGMA0,...)
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
%                                        objective function values at each
%                                        iteration - Vector Double.
%
%   Additional notes:
%   
%   - Mandatory parameters are {FUN,X0,SIGMA0} or {FUN,lb,ub}.
%     Optional parameters can be replaced by [] in the call
%     to the function.
%
%   References:
%
%   - D.P. Kroese, S. Porotsky and R. Y. Rubinstein. The cross-entropy 
%     method for continuous multi-extremal optimization.
%     Meth. Comp. Appl. Prob. 8:383-407, 2006.
%
%   See also: UQ_GSO, UQ_CMAES, UQ_1P1CMAES, UQ_C1P1CMAES

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

% Consistency checks and get number of variables
% Check if given input is row or vector (for multidemensional inputs)
if isempty(x0) && ( isempty(lb) || isempty(ub) )
    error('Either initial point or bounds should be given!')
elseif isempty(x0) && ~isempty(lb) && ~isempty(ub)
    % Initial points is not given but bounds are
    % Make sure lb and ub are of equal sizes
    if length(lb) ~= length(ub)
        error('Dimension mismatch between lb and ub!')
    end
    nvars = length(lb(:));
    x0 = (lb + ub)/2 ;
    if any(isnan(x0)) || any(~isfinite(x0))
        error(['Bounds should have finite values '...
            'if initial point is not given!'])
    end
elseif ~isempty(x0) && ( isempty(lb) || isempty(ub) )
    % x0 is given but not lb and ub
    nvars = length(x0(:)) ;
elseif ~isempty(x0) && ~isempty(lb) && ~isempty(ub)
    % x0, lb and ub are given. Check if the dimensions match.
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
        x0 = rand(nvars,1) .* (ub - lb) + lb;
    end
end
% Make everything column
if isrow(x0)
    FunTakesRow = true;
    x0 = x0(:);
else
    FunTakesRow = false;
end
if isrow(lb), lb = lb(:); end
if isrow(ub), ub = ub(:); end

% In case inputs are transposed,
% make sure that the function handles handle it properly
if FunTakesRow
    funfcn = @(x)fun(x');
else
    funfcn = @(x)fun(x);
end

%% Parse parameters and assign default values

% 1. General options
if isempty(options)
    options = struct;
end
if ~isfield(options,'Display') || isempty(options.Display)
    Display = 'final';
else
    Display = options.Display ;
end
if ~isfield(options,'isVectorized')
    isVectorized = true;
else
    isVectorized = options.isVectorized;
end

% 2. Convergence criteria
if ~isfield(options,'MaxIter')
    MaxGen = 100*nvars;
else
    MaxGen = options.MaxIter;
end
if ~isfield(options,'TolSigma')
    tolsigma = 1e-3;
else
    tolsigma = options.TolSigma;
end
if ~isfield(options,'TolFun')
    TolFun = 1e-3;
else
    TolFun = options.TolFun;
end
if ~isfield(options,'FvalMin')
    FvalMin = -Inf;
else
    FvalMin = options.FvalMin;
end
if ~isfield(options,'nStallMax')
    nStallMax = 50;
else
    nStallMax = options.nStallMax;
end
if ~isfield(options,'MaxFunEval')
    MaxFunEval = Inf;
else
    MaxFunEval = options.MaxFunEval;
end

% 3. Selection parameters
if ~isfield(options,'nPop')
    nPop = 100;
else
    nPop = options.nPop;
end
if ~isfield(options,'quantElite')
    qElite = 0.05;
else
    qElite = options.quantElite;
end

% 4. Adaptation parameters
if isfield(options,'alpha')
    alpha =  options.alpha;
else
    alpha = 0.4;
end
if isfield(options,'beta')
    beta =  options.beta;
else
    beta = 0.4;
end
if isfield(options,'q')
    q =  options.q;
else
    q = 10;
end

% Check consistency for parameters given
% Make sure that sigma0 and tolsigma is of proper size
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
if length(tolsigma) ~= nvars && length(tolsigma) > 1
    error('TOLSIGMA should be either a scalar or a vector of size NVARS!')
else
    if length(tolsigma) == 1 && nvars > 1
        tolsigma = repmat(tolsigma, nvars, 1);
    else
        tolsigma = tolsigma(:);
    end
end

%% Initialize

% With ceil, min(Nel) = 1 whatever N and qElite
Nel = ceil(qElite * nPop); 

% Counters
generation = 0;
fcount = 1;
nStall = 0;

% Input
xmean = x0;
sigmamean = sigma0;
x_best_ever = xmean;

% Initial fitness value
f = funfcn(xmean);
f_best_ever = f;

% History records
% Preallocate
history.Xmean = NaN * ones(nvars,MaxGen+1);
history.sigma = NaN * ones(nvars,MaxGen+1);
history.Xbest = NaN * ones(nvars,MaxGen+1);
history.fitbest = NaN * ones(1,MaxGen+1);
history.fitmedian = NaN * ones(1,MaxGen+1);
% Initialize
history.Xmean(:,1) = xmean;
history.sigma(:,1) = sigma0;
history.Xbest(:,1) = xmean;
history.fitbest(:,1) = f;
history.fitmedian(:,1) = f;

% Other records
f_best_mem = NaN * ones(1,nStallMax);

% Exit flag and message
exitflag = 1;
output.message = sprintf('Maximum number of generations (%i) is reached',...
    MaxGen);

% Save some options, only for diagnostics
% Internal.nPop = nPop;
% Internal.nElite = Nel;

%% Cross-Entropy optimization algorithm

IndConst = find(lb==ub);

% Display the iterations header
headerStringFirst = {'Median', 'Current pop', 'Stall'};
headerStringSecond = {'Generation', 'f-count', 'f(x)', 'best f(x)',...
    'Generations'};
if strcmpi(Display,'iter')
    fprintf('\n')
    fprintf('%32s %18s %7s\n',headerStringFirst{1:end})
    fprintf('%-12s %-12s %-13s %-13s %-13s\n',headerStringSecond{1:end})
    fprintf('%-12i %-12i %-13.6e %-13.6e %-11i\n', generation, fcount,...
        f, f, nStall)
end

for generation = 1:MaxGen
    % Adapting mean and standard deviation 
    % to consider the bounds on the input
    pop = repmat(xmean, 1, nPop) ...
        + repmat(sigmamean, 1, nPop) ...
        .* icdf('Normal',...
        repmat(cdf('Normal', (lb - xmean)./sigmamean, 0, 1), 1, nPop) ...
        + repmat((cdf('Normal', (ub - xmean)./sigmamean, 0, 1) ...
        - cdf('Normal', (lb-xmean)./sigmamean, 0, 1)), 1, nPop) ...
        .* rand(nvars,nPop),...
        0, 1);
    
    if ~isempty(IndConst)
        pop(IndConst,:) = repmat(lb(IndConst),1,nPop);
    end
    
    % Evaluate fitness function
    if isVectorized
        % The fitness function is vectorized: Evaluate all points at once
        fpop = funfcn(pop);
    else
        % The fitness function is not vectorized: 
        % Evaluate one point at a time.
        fpop = NaN* ones(1,nPop);
        for k = 1:nPop
            fpop(:,k) = funfcn(pop(:,k));
        end
    end
    % Update count of the model evaluation
    fcount = fcount + nPop;

    % Sort raw fitness and get the best point ever
    % (elitist adaptation of CMA)
    [sortedfitness, sortedidx] = sort(fpop);
    if sortedfitness(1) < f_best_ever
        f_best_ever = sortedfitness(1);
        x_best_ever = pop(:,sortedidx(1));
        nStall = 0;
    else
        nStall = nStall + 1;
    end
    
    % Get the moments of the elite sample
    elite_pop = pop(:,1:Nel);
    xmean = mean(elite_pop,2);
    sigmamean_last = sigmamean;
    sigmamean = std(elite_pop, 0, 2); % std deviation in dim 2 (input dim.)

    % Updating the parameters
    B_mod = beta - (1 - 1/generation)^q * beta;
    % Update mean
    xmean = alpha * xmean + (1 - alpha) * x_best_ever;
    % Update sigma
    % sigma_ce = beta * sigma_ce + (1 - beta) * sigma_ce_last;  % Static
    % Dynamic updating of sigma
    sigmamean = B_mod * sigmamean + (1 - B_mod) * sigmamean_last;  

    % Save history
    history.fitmedian(:,generation+1) = median(sortedfitness(1:Nel));
    history.fitbest(:,generation+1) = sortedfitness(1);
    history.Xbest(:,generation+1) = pop(:,sortedidx(1));
    history.Xmean(:,generation+1) = xmean;
    history.sigma(:,generation+1) = sigmamean;
    
    % Reporting
    if strcmpi(Display,'iter')
        fprintf('%-12i %-12i %-13.6e %-13.6e %-11i\n', generation,...
            fcount, median(sortedfitness(1:Nel)), sortedfitness(1), nStall)
    end
    
    % Check stopping criteria
    % 2. Maximum number of stall generations has been reached
    if nStall >= nStallMax
        exitflag = 2;
        output.message = sprintf(['Maximum number of stall '...
            'generations (%i) is reached'],nStallMax);
        break
    end
    % 3. Maximum number of evaluations of the fitness function reached
    if fcount >= MaxFunEval
        exitflag = 3;
        output.message = sprintf(['Maximum number of objective function '...
            'evaluations (%i) is reached'],MaxFunEval);
        break
    end
    % 4. Remember the last nStallMax F_best_ever
    %    and the difference between the max and min (range) is below TolFun
    if generation <= nStallMax
        f_best_mem(generation) = sortedfitness(1);
    else
        f_best_mem = [f_best_mem(2:end) sortedfitness(1)];
        if range(f_best_mem) <= TolFun
            exitflag = 4;
            output.message = sprintf(['Range of objective function values '...
                'is below tolerance (%g) over generations'],TolFun);
            break
        end
    end
    % 5. Step size is smaller than tolsigma
    if all(sigmamean./sigma0 < tolsigma)
        exitflag = 5;
        output.message = sprintf(['The global step size length ',...
            'is below tolerance (%i)'],tolsigma(1));
        break
    end
    % 6. Objective function value is smaller than FvalMin
    if ~isempty(FvalMin) && f_best_ever <= FvalMin
        exitflag = 6;
        output.message = sprintf('Minimum fitness value (%g) is reached',...
            FvalMin);
        break
    end
end
%% Return results
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
            fprintf(['\nGlobal step size (sigma) '...
                'is below options.TolSigma\n'])
        case 6
            fprintf(['\nMinimum fitness value (options.FValMin) '...
                'is reached.\n'])
        otherwise
            % Note that technically this should never happen
            fprintf('\nNot converged. Not well defined.\n')
    end
    fprintf('obj. value = %12.6g \n',f_best_ever)
end

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

% Only for diagnostics
% output.Internal = Internal;

end