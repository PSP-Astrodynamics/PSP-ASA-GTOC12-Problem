function [xstar,fstar,exitflag,output] = uq_1p1cmaes(fun, x0, sigma0, lb, ub, options)
% UQ_1P1CMAES finds an unconstrained minimum of a multi-dimensional function by (1+1)-CMA-ES.
%   UQ_1P1CMAES implements a (1+1) variant of the Covariance Matrix
%   Adaptation - Evolution Strategy (CMAES) to solve problems of
%   the following form:
%   XSTAR = argmin F(X), where LB <= X <= UB.
%             X
%
%   XSTAR = UQ_1P1CMAES(FUN, X0, SIGMA0) finds a local minimizer of
%   the function FUN with X0 as starting point and SIGMA0 as 
%   the initial global step size.
%
%   XSTAR = UQ_1P1CMAES(FUN, X0, SIGMA0, LB, UB) defines a set of lower 
%   and upper bounds such that LB(i) <= XSTAR(i) <= UB(i). If LB and UB are
%   finite and X0 = [] and/or SIGMA0 = [], the center of the search space,
%   i.e., (LB(i)+UB(i))/2 and 1/6 of the search space width, i.e.,
%   (UB(i)-LB(i))/6 are used as X0(i) and SIGMA0(i), respectively.
%   If only bound constraints are considered, try UQ_C1P1CMAES.
%
%   XSTAR = UQ_1P1CMAES(FUN,X0,SIGMA0,LB,UB,OPTIONS) minimizes with 
%   the default optimization options replaced by the values
%   in the OPTIONS structure:
%     .Display    : Level of output display - String:
%                       'none' : No output.
%                       'iter' : Output at each iteration.
%                       'final': Only the final output.
%                   default: 'final'.
%     .MaxIter    : Maximum number of generations - Integer,
%                   default: 1000 * (nvars+5)^2.
%     .nStallMax  : Maximum number of stall generations - Integer,
%                   default: 50.
%     .MaxFunEval : Maximum number of obj. function evaluations - Integer,
%                   default: Inf.
%     .TolFun     : Convergence tolerance on FUN - Double,
%                   default: 1e-6
%     .TolSigma   : Convergence tolerance on SIGMA - Double,
%                   default: 1e-11 * sigma0.
%     .isActiveCMA: Update the matrix is case on successive unsuccessful
%                   trials - Boolean, default: 'true'.
%     .Strategy   : Default Internal parameters of CMAES. Default values
%                   are already tuned; it is strongly advised not to modify 
%                   these parameters - Structure:
%                       .dp     : Double, default: 1 + nvars/2.
%                       .Ptarget: Double, default: 2/11.
%                       .cp     : Double, default: 1/12.
%                       .cc     : Double, default: 2/(nvars+2).
%                       .ccov   : Double, default: 2/(nvars^2+6).
%                       .Pthres : Double, default: 0.44
%
%   [XSTAR,FSTAR] = UQ_1P1CMAES(FUN, X0, SIGMA0,...) additionally returns 
%   the value of the objective function at the solution XSTAR.
%
%   [XSTAR,FSTAR,EXITFLAG] = UQ_1P1CMAES(FUN, X0, SIGMA0,...) additionally 
%   returns an exit flag that indicates termination condition:
%       1 : Maximum number of generations (MaxIter) is reached.
%       2 : Maximum number of stall generations (nStallMax) is reached.
%       3 : Maximum number of function evaluations (MaxFunEval) is reached.
%       4 : Range of FUN over nStallMax generations is smaller than TolFun.
%       5 : Step Size is smaller than TolSigma.
%      <0 : No feasible solution was found.
%
%   [XSTAR,FSTAR,EXITFLAG,OUTPUT] = UQ_1P1CMAES(FUN, X0, SIGMA0,...)
%   additionally returns a structure with additional information about
%   the optimization process:
%       .iterations : Total number of iterations - Integer.
%       .funccount  : Total number of objective function 
%                     evaluations - Integer.
%       .History    : Detailed history of the optimization process
%                     (X, FUN(X) at each iteration) - Structure:
%                       .x     : History of the sampled points at each
%                                iteration - Matrix Double.
%                       .fval  : History of the corresponding objective
%                                function values at each iteration - Vector
%                                Double.
%                       .sigma : History of the global step size - 
%                                Matrix Double.
%
%   Additional notes:
%
%   - Mandatory parameters are {FUN,X0,SIGMA0} or {FUN,lb,ub}.
%     Optional parameters can be replaced by [] in the call
%     of the function.
%
%   - The algorithm handles bound constraints by resampling. In some cases,
%     this may not be the most efficient approach. UQ_C1P1CMAES may be more
%     appropriate if the solution lies close to a boundary
%     of the search space
%
%   References:
%
%   - D. V. Arnold and N. Hansen, "Active Covariance matrix adaptation 
%     for the (1+1)-CMA-ES," GECCO'10, July 7-11, 2010, Portland,
%     Oregon, USA. 
%   - T. Suttorp, N. Hansen and C. Igel, "Efficient covariance matrix
%     update for variable matrix evolution strategies," Machine Learning,
%     75(2):167-197, 2009. (main source)
%   - C. Igel, T. Suttorp and N. Hansen, "A computational efficient
%     covariance matrix update and a (1+1)-CMA for evolution strategies,"
%     GECCO'06, July 8-12, Seattle, Washington, USA.
%
%   See also: UQ_C1P1CMAES, UQ_CMAES, UQ_GSO, UQ_CEO

%% Pre-process and check parameters

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
% Check if input is a row or column vector (for multi-dimensional inputs)
if isempty(x0) && ( isempty(lb) || isempty(ub) )
    error('Either initial point or bounds should be given!')
elseif isempty(x0) && ~isempty(lb) && ~isempty(ub)
    % Initial points is not given but bounds are
    % Make sure lb and ub are of equal sizes
    if length(lb) ~= length(ub)
        error('Dimension mismatch between lb and ub!')
    end
    nvars = length(lb(:));
    x0 = (lb + ub)/2;
    if isnan(x0)
        error(['Bounds should have finite values '...
            'if initial point is not given!'])
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
        lb = repmat(lb, nvars, 1);
        ub = repmat(ub, nvars, 1);
    end
    % Check that initial point is in bounds. Otherwise re-sample a new one:
    if any(x0 < lb) || any(x0 > ub)
        warning('Initial points in not in bounds')
        fprintf(['Calculating a new one: '...
            'random uniform sample on the search space'])
        x0 = rand(nvars,1) .* (ub - lb) + lb;
    end
end

% Set initial value of sigma0 if not given by the user
if isempty(sigma0) && (isempty(lb) || isempty(ub))
    error('Either initial sigma value or bounds should be given!')
elseif isempty(sigma0) && ~isempty(lb) && ~isempty(ub)
    sigma0 = (ub-lb)/6;
end
if length(sigma0) == 1 && nvars > 1
    sigma0 = sigma0 * ones(nvars,1);
end
if length(sigma0) ~= nvars && length(sigma0) > 1
    error('SIGMA0 should be either a scalar or a vector of size NVARS!')
end

% Make everything column
if isrow(x0)
    FunTakesRow = true;
    x0 = x0(:);
else
    FunTakesRow = false;
end
if isrow(sigma0), sigma0 = sigma0(:); end

% Now that all the consistency check is done, set lb and ub to Inf in case 
% they are empty
if isempty(lb), lb = -Inf*ones(nvars,1) ; end
if isempty(ub), ub = Inf*ones(nvars,1) ; end
% Set eveerything in row
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
    options = struct ;
end
if ~isfield(options,'Display')
    Display = 'final';
else
    Display = options.Display;
end

% 2. Convergence criteria
if ~isfield(options,'MaxIter')
    MaxIter = 1000 * (nvars+5)^2;
else
    MaxIter = options.MaxIter;
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
if ~isfield(options,'TolFun')
    TolFun = 1e-6;
else
    TolFun = options.TolFun;
end
if ~isfield(options,'TolSigma')
    TolSigma = 1e-11 * sigma0;
else
    TolSigma = options.TolSigma;
end

% 3. Other Settings
if isfield(options,'isActiveCMA')
    isActiveCMA =  options.isActiveCMA;
else
    isActiveCMA = true;
end

% 4. Internal CMA-ES parameters
if ~isfield(options, 'Strategy')
    options.Strategy = struct;
end
% Step size control
if isfield(options.Strategy,'dp')
    dp =  options.Strategy.dp;
else
    dp = 1 + nvars/2;
end
if isfield(options.Strategy,'Ptarget')
    Ptarget =  options.Strategy.Ptarget;
else
    Ptarget = 2/11;
end
if isfield(options.Strategy,'cp')
    cp =  options.Strategy.cp;
else
    cp = 1/12;
end
% Covariance matrix adaptation
if isfield(options.Strategy,'cc')
    cc =  options.Strategy.cc;
else
    cc = 2/(nvars+2);
end
if isfield(options.Strategy,'ccov')
    ccov =  options.Strategy.ccov;
else
    ccov = 2/(nvars^2+6);
end
if isfield(options.Strategy,'Pthres')
    Pthres =  options.Strategy.Pthres;
else
    Pthres = 0.44;
end

% Check consistency for parameters given in Strategy
% Make sure that TolSigma is of proper size
if length(TolSigma) ~= nvars && length(TolSigma) > 1
    error('TolSigma should be either a scalar or a vector of size NVARS!')
else
    if length(TolSigma) == 1 && nvars > 1
        TolSigma = repmat(TolSigma,nvars,1);
    else
        TolSigma = TolSigma(:);
    end
end

%% Initialize

x_current = x0;         % Starting point
sigma_current = sigma0; % Step size

% Check if starting point is in bound.
% Search new one if not.
isinbounds = uq_checkBounds(x_current, lb, ub);
inbounds = isreal(lb) && isreal(ub) && all(isinbounds);
trials = 0;
while ~inbounds
    if all(isfinite(lb) & isfinite(ub))
        if trials == 0
            fprintf(['Initial point is not in bounds. '...
                'Searching for a new one by random uniform sample '...
                'on the search space'])
        end
        x_current = rand(nvars,1) .* (ub-lb) + lb;
    else
        if trials == 0
            fprintf(['Initial point is not in bounds. '...
                'Searching for a new one by sampling following '...
                'the initial normal distribution'])
        end
        x_current = randn(nvars,1) .* sigma0 + x0;
    end
    trials = trials + 1;
end

% State parameters
pc = 0;             % Search path
Psucc = Ptarget;    % Success probability
A = eye(nvars);     % Cholesky factor
Ainv = eye(nvars);  % its inverse

% Initial fitness value
f = funfcn(x_current);

% Counters
iteration = 0;  % Number of iteration
nStall = 0;     % Number of stalled generation
nfeval = 1;     % Number of fitness evaluations

% History records
% Preallocate
history.x = zeros(nvars,MaxIter+1);
history.fval = zeros(1,MaxIter+1);
history.sigma = zeros(nvars,MaxIter+1);
% Initialize
history.x(:,iteration+1) = x_current;
history.fval(:,iteration+1) = f;
history.sigma(:,iteration+1) = sigma0;

% Best records
x_best_ever = x_current;
f_best_ever = f;
f_best_mem = NaN * ones(1,nStallMax); % Best over nStallMax

% Other records
f_ancestors = NaN * ones(1,5);        % 5-th-order ancestor

% Exit flag and message
output.message = sprintf('Maximum number of generations (%i) is reached',...
    MaxIter);
exitflag = 1;

%% (1+1)-CMA-ES optimization algorithm

% Display the iterations header
headerStringFirst = {'Best', 'Current', 'Stall'};
headerStringSecond = {'Generation', 'f-count', 'f(x)', 'f(x)',...
    'Generations'};
if strcmpi(Display,'iter')
    fprintf('\n')
    fprintf('%30s %16s %11s\n', headerStringFirst{1:end})
    fprintf('%-12s %-12s %-13s %-13s %-11s\n',headerStringSecond{1:end})
    fprintf('%-12i %-12i %-13.6e %-13.6e %-11i\n',...
        iteration, nfeval, f_best_ever, f, nStall)
end

for iteration = 1:MaxIter
    
    % Generate offspring
    trials = 0;
    inbounds = false;
    while ~inbounds
        z = randn(nvars,1);
        x_current = x_best_ever + sigma_current .* (A*z);
        areinbound = uq_checkBounds(x_current, lb, ub);
        inbounds = isreal(lb) && isreal(ub) && all(areinbound);
        trials = trials + 1;
        % Display warning every 1000 trials if no offspring still cannot
        % be found
        if mod(trials,1000) == 0
            warning('Attempts to find samples in bounds appear to be difficult')
            fprintf('Number of trials: %i\n',trials)
        end
    end
    
    % Evaluate function
    f = funfcn(x_current);
    nfeval = nfeval + 1;
    
    % Success probability and step size
    Psucc = (1-cp) * Psucc + cp * (f<=f_best_ever);
    sigma_current = sigma_current * exp( (Psucc-Ptarget) / (dp * (1-Ptarget)));
    
    % Better solution found
    if f <= f_best_ever
        x_best_ever = x_current;
        f_best_ever = f;
        nStall = 0 ;
        % Update Cholesky decomposition factor A and its inverse Ainv
        % Note that here update of the search path is done w.r.t. to Psucc
        % and Pthres as in Suttorp, Hansen, and Igel (2009)
        if Psucc < Pthres
            pc = (1-cc) * pc + sqrt(cc*(2-cc)) * z;
            alpha = 1 - ccov;
        else
            pc = (1-cc) * pc;
            alpha = (1-ccov) + ccov * cc * (2-cc);
        end
        w = Ainv * pc;
        w2 = sum(w.^2);
        A = sqrt(alpha) * A ...
            + sqrt(alpha)/w2 * (sqrt(1 + ccov/alpha*w2) - 1) * pc * w';
        Ainv = 1/sqrt(alpha) * Ainv ...
            - 1/(sqrt(alpha) * w2) * (1 - 1/(sqrt(1+ccov/alpha*w2))) * w * (w'*Ainv);
        
        % k-th order ancestor success
        f_ancestors = [f_ancestors(2:end) f];
        % Best objective function values over nStall iterations
        f_best_mem = [f_best_mem(2:end) f]; 
    else
        nStall = nStall + 1;
        % Specially uncesful case : Active covariance matrix
        % Active covariance matrix update is done following 
        % Arnold and Hansen (2010)
        if isActiveCMA
            if ~isnan(f_ancestors(1)) && f > f_ancestors(1)
                z2 = sum(z.^2);
                ccovm = min(0.4/(nvars^(1.6) + 1), 1/(2*z2-1));
                if ccovm <= -1 || 1 - (ccovm * z2)/(1 + ccovm) <= 0
                    ccovm = 0.4/(nvars^1.6+1);
                end % Numerical fix - Note: not sure this is the best way 
                a = sqrt(1+ccovm);
                b = (sqrt(1 + ccovm) / z2) * (sqrt(1 - (ccovm*z2)/(1+ccovm)) - 1);
                A = a*A + b * (A*z) * z';
                % Update of the Ainv made following Suttorp, Hansen, 
                % and Igel (2009)
                Ainv = 1/a * Ainv - (b/(a^2 + a*b*z2)) * z * (z'*Ainv);
            end
        end
    end
            
    % Save history
    history.x(:,iteration+1) = x_current;
    history.fval(:,iteration+1) = f;
    history.sigma(:,iteration+1) = sigma_current;

    % If requested, display iteration
    if strcmpi(Display,'iter')
        fprintf('%-12i %-12i %-13.6e %-13.6e %-11i\n',...
            iteration, nfeval, f_best_ever, f, nStall);
    end
    
    % Check stopping criteria
    % 2. Maximum number of stall generations has been reached
    if  nStall >= nStallMax
        exitflag = 2;
        output.message = sprintf(['Maximum number of stall '...
            'generations (%i) is achieved'],nStallMax);
        break
    end
    % 3. Maximum number of evaluations of the objective function reached
    if nfeval >= MaxFunEval
        exitflag = 3;
        output.message = sprintf(['Maximum number of objective function '...
            'evaluations (%i) is reached'],MaxFunEval);
        break
    end
    % 4. Remember the last nStallMax F_best_ever
    %    and the difference between the max and min (range) is below TolFun
    if ~isnan(f_best_mem(1)) &&  (f_best_mem(1)-f_best_mem(end)) <= TolFun
        exitflag = 4;
        output.message = sprintf(['Range of objective function values '...
            'over %i iterations is below tolerance %g'],...
            nStallMax, TolFun);
        break
    end
    % 5. Current step size is smaller than TolSigma
    if sigma_current < TolSigma
        exitflag = 5;
        output.message = sprintf('Step size sigma is below tolerance %g',...
            max(TolSigma));
        break
    end
end

%% Return results

% Print out the exit message
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
            fprintf('\nValue of sigma below options.TolSigma.\n')
        otherwise
            fprintf('\nNo valid solution found.\n')
     end
    fprintf('obj. value = %12.6g \n',f_best_ever)
end

if FunTakesRow
    xstar = x_best_ever';
    history.x = history.x(:,1:iteration+1)';
    history.fval = history.fval(:,1:iteration+1)';
    history.sigma = history.sigma(:,1:iteration+1)';
    
else
    xstar = x_best_ever;
    history.x = history.x(:,1:iteration+1);
    history.fval = history.fval(:,1:iteration+1);
    history.sigma = history.sigma(:,1:iteration+1);
end

fstar = f_best_ever;
output.iterations = iteration;
output.funccount = nfeval;
output.History = history;

end
function [isinbounds, idx] = uq_checkBounds(x,lb,ub)
if isrow(x) && length(lb) > 1
    isinbounds = prod((lb - x).*(x - ub) > 0,2);
else
    isinbounds = prod((lb - x).*(x - ub) > 0,1);
end
idx = find(isinbounds == 0);

end

% function [isinbounds, idx] = uq_checkBounds(x,lb,ub)
% 
% if isrow(lb)
%     isinbounds = prod((lb-x).*(x-ub) > 0,1);
% else
%     isinbounds = prod((lb-x).*(x-ub) > 0,2);
% end
% idx = find(isinbounds == 0);
% 
% end