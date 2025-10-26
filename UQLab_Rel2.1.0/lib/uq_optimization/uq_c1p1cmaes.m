function [xstar,fstar,exitflag,output] = uq_c1p1cmaes(fun, x0, sigma0, lb, ub, nonlcon, options)
% UQ_1P1CMAES finds a constrained minimum of a multi-dimensional function by (1+1)-CMA-ES.
%   UQ_C1P1CMAES implements a (1+1) variant of the Covariance Matrix
%   Adaptation - Evolution Strategy (CMAES) to solve problems of
%   the following form:
%   XSTAR = argmin F(X) subject to: G(X) <= 0 (G(X) are nonlinear constraints)
%             X                     LB <= X <= UB
%
%   XSTAR = UQ_C1P1CMAES(FUN, X0, SIGMA0) finds a local minimizer of
%   the function FUN with X0 as the starting point and SIGMA0 as
%   the initial global step size.
%
%   XSTAR = UQ_C1P1CMAES(FUN, X0, SIGMA0, LB, UB) defines a set of lower
%   and upper bounds such that LB(i) <= XSTAR(i) <= UB(i). If LB and UB are
%   finite and X0 = [] and/or SIGMA0 = [], the center of the search space,
%   i.e., (LB(i)+UB(i))/2 and 1/6 of the search space width, i.e.,
%   (UB(i)-LB(i))/6 are used as X0(i) and SIGMA0(i), respectively.
%
%   XSTAR = UQ_C1P1CMAES(FUN, X0, SIGMA0, LB, UB, NONLCON) defines a set
%   of non-linear inequalities constraints and subjects the minimization
%   to the constraints. If there are no bound constraints,
%   set LB = [] and UB = [].
%
%   XSTAR = UQ_C1P1CMAES(FUN, X0, SIGMA0, LB, UB, NONLCON, OPTIONS)
%   minimizes with the default optimization options replaced by the values
%   in the OPTIONS structure:
%     .Display     : Level of display - String:
%                        'none' : No output.
%                        'iter' : Output at each iteration.
%                        'final': Only the final output.
%                    default: 'final'.
%     .MaxIter     : Maximum number of generations - Integer,
%                    default: 1000*(nvars+5)^2.
%     .nStallMax   : Maximum number of stall generations - Integer,
%                    default: 10+30*nvars
%     .MaxFunEval  : Maximum number of obj. function evaluations - Integer,
%                    default: Inf.
%     .TolFun      : Convergence tolerance on FUN - Double,
%                    default: 1e-12.
%     .TolSigma    : Convergence tolerance on SIGMA - Double,
%                    default: 1e-11 * sigma0.
%     .feasiblex0  : Flag to indicate that resampling should be done to try
%                    and find a feasible point if the starting point is
%                    not feasible - Logical,
%                    default: true.
%     .isActiveCMA : Update the matrix in case of successive unsuccessful
%                    trials - Logical,
%                    default: true.
%     .Strategy    : Default Internal parameters of CMAES. Default values
%                    are already tuned; it is strongly advised not to
%                    modify these parameters (for details about the values,
%                    see the references below) - Structure:
%                       .c       : Double, default: 2/(nvars+2).
%                       .ccovp   : Double, default: 2/(nvars^2+6).
%                       .cp      : Double, default: 1/12.
%                       .dp      : Double, default: 1 + nvars/2.
%                       .Ptarget : Double, default: 2/11.
%                       .cc      : Double, default: 1/(nvars+2).
%                       .beta    : Double, default: 0.1/(nvas+2).
%
%   [XSTAR,FSTAR] = UQ_C1P1CMAES(...) additionally returns the value
%   of the objective function at the solution XSTAR.
%
%   [XSTAR,FSTAR,EXITFLAG] = UQ_C1P1CMAES(...) additionally returns
%   an exit flag that indicates the termination condition:
%       1 : Maximum number of generations (MaxIter) is reached.
%       2 : Maximum number of stall generations (nStallMax) is reached.
%       3 : Maximum number of function evaluations (MaxFunEval) is reached.
%       4 : Range of FUN over nStallMax generations is smaller than TolFun.
%       5 : Step Size is smaller than TolSigma.
%      <0 : No feasible solution was found.
%
%   [XSTAR,FSTAR,EXITFLAG,OUTPUT] = UQ_C1P1CMAES(...) returns a structure
%   with additional information about the optimization process:
%     .iterations : Total number of iterations.
%     .funccount  : Total number of objective function evaluations.
%     .conscount  : Total number of contraints function evaluations.
%     .History    : A detailed history of the optimization process
%                   (X, FUN(X) at each iteration).
%                       .x     : History of the sampled points at each
%                                iteration - Matrix Double.
%                       .fval  : History of the objective function values
%                                at each iteration - Vector Double.
%                       .gval  : History of the constraint functions values
%                                at each iteration - Matrix Double.
%                       .sigma : History of the global step size at each
%                                iteration - Matrix Double.
%                       .status: History of the state of the sampled point
%                                at each iteration - Vector Integer:
%                                   -1 : Sampled point is not feasible.
%                                    0 : Sampled point is feasible, but it
%                                        does not improve the current best
%                                        solution.
%                                    1 : Sampled point is feasible and it
%                                        improves the current best
%                                        solution.
%
%   Additional Notes:
%
%   - Mandatory parameters are {FUN,X0,SIGMA0} or {FUN,lb,ub}.
%     Optional parameters can be replaced by [] in the call of
%     the function.
%
%   References:
%
%   - Arnold, D. V. and Hansen, N. A, "(1+1)-CMA-ES for constrained
%     optimisation," in GECCO'12, July 7-11, 2012, Philadelphia,
%     Pennsylvania, USA.
%   - Arnold, D.V. and Hansen N., "Active covariance matrix adaptation for
%     the (1+1)-CMA-ES," In GECCO'10, pp. 385-392. ACM Press, 2010.
%
%   See also: UQ_1P1CMAES, UQ_CMAES, UQ_CEO, UQ_GSO

%% Pre-processing and parameters checking
%
% Check the number of input arguments
try
    narginchk(3,7)
catch ME
    error('Wrong number of input arguments!')
end
if nargin < 7
    options = [];
    if nargin < 6
        nonlcon = [];
        if nargin < 5
            ub = [];
            if nargin < 4
                lb = [];
            end
        end
    end
end

% Consistency checks and get number of variables
% Check if given input is a row or vector (for multi-dimensional inputs)
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
    nvars = length(x0(:)) ;
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
        x0 = rand(nvars,1) .* (ub-lb) + lb;
    end
end

% Set initial value of sigma0 if not given by the user
if isempty(sigma0) && (isempty(lb) || isempty(ub))
    error('Either initial sigma value or bounds should be given')
elseif isempty(sigma0) && ~isempty(lb) && ~isempty(ub)
    sigma0 = (ub - lb)/6;
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
if isrow(lb), lb = lb(:); end
if isrow(ub), ub = ub(:); end

% In the case inputs are transposed,
% make sure that the function handles handle it properly
if FunTakesRow
    funfcn = @(x)fun(x') ;
    nonlconfcn = @(x) nonlcon(x');
else
    funfcn = @(x)fun(x);
    nonlconfcn = @(x) nonlcon(x);
end

%% Parse parameters and assign default values

% 1. General options
if isempty(options)
    options = struct;
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
if ~isfield(options,'MaxFunEval')
    MaxFunEval = Inf;
else
    MaxFunEval = options.MaxFunEval;
end
if ~isfield(options,'nStallMax')
    nStallMax = 10 + 30*nvars;
else
    nStallMax = options.nStallMax;
end
if ~isfield(options,'TolFun')
    TolFun = 1e-12;
else
    TolFun = options.TolFun;
end
if ~isfield(options,'TolSigma')
    if ~isempty(sigma0)
        TolSigma = 1e-11 * max(sigma0);
    else
        TolSigma = [];
    end
else
    TolSigma = options.TolSigma;
end
% Make sure that TolSigma is of proper size
if length(TolSigma) == 1 && nvars > 1
    TolSigma = TolSigma * ones(nvars,1) ;
end
if isempty(TolSigma)
    TolSigma = 1e-11*sigma0 ;
end
if length(TolSigma) ~= nvars && length(TolSigma) > 1
    error('TOLSIGMA should be either a scalar or a vector of size NVARS!')
end

% 3. Other settings
if ~isfield(options,'isActiveCMA')
    isActiveCMA = true;
else
    isActiveCMA = options.isActiveCMA;
end
if ~isfield(options,'feasiblex0')
    feasiblex0 = true;
else
    feasiblex0 = options.feasiblex0;
end

% 4. Internal CMA-ES parameters
if ~isfield(options,'Strategy')
    options.Strategy = struct;
end
if isfield(options.Strategy,'dp')
    dp = options.Strategy.dp;
else
    dp = 1 + nvars/2;
end
if isfield(options.Strategy,'c')
    c = options.Strategy.c;
else
    c = 2/(nvars + 2);
end
if isfield(options.Strategy,'cp')
    cp = options.Strategy.cp;
else
    cp = 1/12;
end
if isfield(options.Strategy,'Ptarget')
    Ptarget = options.Strategy.Ptarget;
else
    Ptarget = 2/11;
end
if isfield(options.Strategy,'ccovp')
    ccovp = options.Strategy.ccovp;
else
    ccovp = 2/(nvars^2 + 6);
end
if isfield(options.Strategy,'cc')
    cc = options.Strategy.cc;
else
    cc = 1/(nvars+2);
end
if isfield(options.Strategy,'beta')
    beta = options.Strategy.beta;
else
    beta = 0.1 / (nvars+2);
end

%% Record the optimization parameters, only for diagnostics
% Internal.MaxIter = MaxIter ;
% Internal.MaxFunEval = MaxFunEval ;
% Internal.TolSigmA = TolSigma ;
% Internal.TolFun = TolFun ;
% Internal.nStallMax = nStallMax ;

%% Initialize

x_current = x0;          % Current solution at starting point
sigma_current = sigma0;  % Current global step size at initial

% Initial objetive function value
f = funfcn(x_current);

% Counters
nfeval = 1; % Number of objective function evaluations
ngeval = 1; % Number of constraint functions evaluation
nStall = 0; % Number of stall generations
iteration = 1; % Generation counter

% Initial constraint(s) value(s)
if ~isempty(nonlcon)
    g = nonlconfcn(x_current);
    if isrow(g)
        g = g';
    end
else
    g = [];
end
% Add bound constraints to g
g = uq_addboundconstraints(x_current, g, lb, ub);
% Number of constraints (including bounds)
nconsts = length(g);

% Based on constraint, initialize best records for x and f
if all(g <= 0)
    % Initial point is feasible
    status = 1;
    x_best_ever = x_current;
    f_best_ever = f;
else
    % This also means that there is a non-linear constraint
    if feasiblex0
        status = 1;
        trials = 0;
        while any(g > 0)
            if all(isfinite(lb) & isfinite(ub))
                if trials == 0
                    fprintf(['Initial point is not feasible. '...
                        'Searching for a new one '...
                        'by random uniform sample on the search space\n'])
                end
                x_current = rand(nvars,1) .* (ub - lb) + lb;
            else
                if trials == 0
                    fprintf(['Initial point is not feasible. '...
                        'Searching for a new one by sampling '...
                        'following the initial normal distribution\n']);
                end
                x_current = randn(nvars,1).*sigma0 + x0;
            end
            % Evaluate constraint
            g = nonlconfcn(x_current);
            if all(g<0)
                fprintf('\nInitial feasible point found \n');
            end
            ngeval = ngeval + 1;
            trials = trials + 1;
            if trials > 100*nvars^2
                % TODO: This should be improved. Set dimension dependent limit or user-given
                warning(['No feasible point could be found '...
                    'after 100*nvars^2 trials']) % Rather output an error?
                x_current = x0;
                x_best_ever = x_current;
                status = -1;
                break
            end
        end
        if isrow(g)
            g = g';
        end
        % Evaluate point
        f = funfcn(x_current);
        % Update counter of fitness evaluation
        nfeval = nfeval + 1;
        % Add bounds to the constraints
        g = uq_addboundconstraints(x_current, g, lb, ub);
        if all(g <= 0)
            x_best_ever = x_current;
            f_best_ever = f;
        else
            % f_best_ever is Inf
        end
    else
        warning(['Initial point is not feasible. '...
            'This could decrease performance of the algorithm.'])
        x_best_ever = x_current;
        f_best_ever = Inf;
        status = -1;
    end
end

% Cholesky factor of the covariance matrix
A = eye(nvars);
invA = eye(nvars);
s = zeros(nvars,1);
m = length(g);
v = zeros(nvars,m);
w = zeros(nvars,m);
Psucc = Ptarget;

% History records
% Preallocate
history.x = zeros(nvars,MaxIter);
history.fval = zeros(1,MaxIter);
history.gval = zeros(nconsts,MaxIter);
history.sigma = zeros(nvars,MaxIter);
history.status = zeros(1,MaxIter);
% Initialize
history.x(:,1) = x_current;
history.fval(:,1) = f;
history.gval(:,1) = g(1:nconsts);
history.sigma(:,1) = sigma0;
history.status(:,1) = status;
% Iteration number of the best feasible points + 1
NewBestPoint = 1 ;
% Best records
f_best_mem = NaN * ones(1,nStallMax);

% Other records
f_ancestors = NaN * ones(1,5); % 5-th-order ancestor

% Exit flag and message
output.message = sprintf('Maximum number of generations (%i) reached',...
    MaxIter);
exitflag = 0;

%% Constrained (1+1)-CMA-ES optimization

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

% Optimization iteration
for iteration = 2 : MaxIter
    
    % Generate offspring
    z = randn(nvars, 1) ;
    x_current = x_best_ever + sigma_current .* (A * z) ;
    
    % Evaluate the constraint
    if ~isempty(nonlcon)
        g = nonlconfcn(x_current) ;
        if isrow(g), g = g' ; end
    else
        g = [] ;
    end
    g = uq_addboundconstraints(x_current,g,lb,ub) ;
    ngeval = ngeval + 1 ;
    
    % Get violated constraints indices
    Idx_violated = find(g > 0) ;
    
    % Update covariance matrix Cholesky decomposition
    if ~isempty(Idx_violated)
        % Case sampled point is not feasible
        status = -1 ;
        
        % 1. update v
        v(:,Idx_violated) = (1 - cc) * v(:,Idx_violated) ...
            + repmat(cc * A * z, 1, length(Idx_violated));
        % 2. update v and Svw
        Svw = zeros(nvars,nvars) ;
        for j = 1:m
            if g(j) > 0
                w(:,j) = invA * v(:,j) ;
                Svw = Svw + (( v(:,j) * w(:,j)') / (w(:,j)' * w(:,j)));
            end
        end
        % 3. update A
        A = A - (beta/length(Idx_violated)) * Svw;
        % 4. Compute inverse of A.
        %    Note: no updating formula available in this case
        invA = pinv(A) ;  % Note: Use pinv ?
    else
        % case sampled point is feasible
        
        % Evaluate fitness
        f = funfcn(x_current) ;
        nfeval = nfeval + 1 ;
        Psucc = (1-cp) * Psucc + cp * (f<=f_best_ever) ;
        sigma_current = sigma_current * exp((Psucc - Ptarget) / (dp * (1-Ptarget)));
        
        if f <= f_best_ever
            % Current point improves best solution
            status = 1;
            
            % Update current solution
            x_best_ever = x_current;
            f_best_ever = f;
            
            
            % Update A
            s = (1-c) * s + sqrt(c * (2-c)) * A * z;
            w = invA * s;
            w2 = sum(w.^2);
            a = sqrt(1 - ccovp) ;
            b = sqrt(1 - ccovp)/w2 * (sqrt( 1 + ccovp/(1 - ccovp)*w2) - 1); % ( sqrt(1 - ccovp) / w2 ) * ( sqrt(1 + (ccovp * w2)/(1 - ccovp)) - 1 )
            A = a * A + b * s * w';
            
            % Update invA (following Arnold and Hansen (2010))
            invA = 1/a * invA - (b/(a^2 + a*b*w2)) * w * (w'*invA);
            
            % k-th order ancestor success
            f_ancestors = [f_ancestors(2:end) f];
            % Best objective over nStall iterations
            f_best_mem = [f_best_mem(2:end) f];
            % Reset the stall counter
            nStall = 0;
            NewBestPoint = [NewBestPoint, iteration];
        else
            % Point is feasible but does not improve the current best point
            status = 0;
            nStall = nStall + 1;
            if isActiveCMA
                if ~isnan(f_ancestors(1)) && f > f_ancestors(1)
                    z2 = sum(z.^2) ;
                    ccovm = min(0.4/(nvars^(1.6) + 1), 1 / (2*z2 - 1));
                    if ccovm <= -1
                        % Note: numerical fix, unsure if it's the best way
                        ccovm = 0.4/(nvars^1.6 + 1);
                    end
                    a = sqrt(1+ccovm);
                    b = (sqrt(1+ccovm) / z2) ...
                        * (sqrt(1 - (ccovm*z2)/(1+ccovm)) - 1);
                    A = a*A + b * (A*z) * z';
                    % Update of the inv(A) made following Arnold and Hansen
                    % (2010)
                    invA = 1/a * invA - (b/(a^2 + a*b*z2)) * z * (z'*invA);
                end
            end
        end
    end
    
    % Save history
    history.x(:,iteration) = x_current;
    history.fval(:,iteration) = f;
    history.gval(:,iteration) = g(1:nconsts);
    history.sigma(:,iteration) = sigma_current;
    history.status(:,iteration) = status;
    
    % If requested, display iteration reporting
    if strcmpi(Display,'iter')
        fprintf('%-12i %-12i %-13.6e %-13.6e %-11i\n',...
            iteration, nfeval, f_best_ever, f, nStall)
    end
    
    % Check stopping criteria
    % 1) If the maximum number of stall generations has been reached stop
    if  nStall >= nStallMax
        exitflag = 1 ;
        output.message = sprintf(['Maximum number of stall generations '...
            '(%i) achieved'],nStallMax);
        break
    end
    % 2) Maximum number of evalluatino o fthe fitness function reached
    if nfeval >= MaxFunEval
        exitflag = 2 ;
        output.message = sprintf(['Maximum number of objective function '...
            'evaluations (%i) reached'],MaxFunEval);
        break
    end
    % 3) Remember the last nStallMax F_best_ever
    %    and if the difference between the max and min (range)
    %    is below TolFun, then stop
    if ~isnan(f_best_mem(1)) &&  (f_best_mem(1)-f_best_mem(end)) <= TolFun
        exitflag = 3 ;
        output.message = sprintf(['Range of objective function values '...
            'over %i iterations is below tolerance %g'],...
            nStallMax, TolFun);
        break
    end
    % 4) If sigma < TolSigma stop
    if sigma_current < TolSigma
        exitflag = 4 ;
        output.message = sprintf('Step size sigma is below tolerance %g',...
            max(TolSigma));
        break
    end
    
end

if f_best_ever == Inf
    % NO feasible solution was found
    exitflag = -1;
    output.message = sprintf('No feasible point was found');
end

%% Return results
if strcmpi(Display,'iter') || strcmpi(Display,'final')
    switch exitflag
        case 0
            fprintf(['\nMaximum number of generations '...
                '(options.MaxIter) is reached.\n'])
        case 1
            fprintf(['\nMaximum number of stall generations '...
                '(options.nStallMax) is reached.\n'])
        case 2
            fprintf(['\nMaximum number of objective function '...
                'evaluations (options.MaxFunEval) is reached.\n'])
        case 3
            fprintf(['\nRange of FUN over nStallMax '...
                'is below options.TolFun.\n'])
        case 4
            fprintf('\nValue of sigma below options.TolSigma.\n')
        case -1
            fprintf('\nNo feasible point was found.\n')
    end
%     fprintf('obj. value = %12.6g \n',f_best_ever)
end

if FunTakesRow
    xstar = x_best_ever' ;
    history.x = history.x(:,1:iteration)' ;
    history.fval = history.fval(:,1:iteration)' ;
    history.gval = history.gval(:,1:iteration)' ;
    history.sigma = history.sigma(:,1:iteration)' ;
    history.status = history.status(:,1:iteration)' ;
    
else
    xstar = x_best_ever ;
    history.x = history.x(:,1:iteration) ;
    history.fval = history.fval(:,1:iteration) ;
    history.gval = history.gval(:,1:iteration) ;
    history.sigma = history.sigma(:,1:iteration) ;
    history.status = history.status(:,1:iteration) ;
end

fstar = f_best_ever ;
output.iterations = iteration ;
output.funccount = nfeval ;
output.constcount = ngeval ;
output.History = history ;
% output.Internal = Internal ;
output.NewBestPoint = NewBestPoint ;
end


function g = uq_addboundconstraints(x, g, lb, ub)

if ~isempty(lb)
    g = [g ; lb - x];
end
if ~isempty(ub)
    g = [g ; x - ub];
end

end