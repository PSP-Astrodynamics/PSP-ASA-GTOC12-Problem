function [xstar, fval, exitflag, output] = uq_c1p1cmaes_intrusive(fun, x0, sigma0, lb, ub, nonlcon, options)
%
% UQ_C1P1CMAES Constrainted (1+1)-CMAES as described in:
%
% [1] Arnold, D. V. and Hansen, N. A (1+1)-CMA-ES for constrained optimisation.
% GECCO'12, July 7-11, 2012, Philadelphia, PennySylvania, USA.
%
% [2] Arnold, D.V. and Hansenm N. Active covariance matrix adaptation for
% the (1+1)-CMA-ES. In genetic and Evolutionnary Computation Conference -
% GECCO'10, pp. 385-392. ACM Press, 2010
%
%
% UQ_C1P1CMAES attempts to solve problems of the following form:
% Xstar = argmin F(X) subject to: M(X) <= 0 (M(X) is nonlinear constraints)
%            X                    lb <= X <= ub
%
%
% Xstar = UQ_C1P1CMAES(FUN,X0,SIGMA0) finds a local minimizer of function
% FUN with X0 as starting point and SIGMA0 as initial search step length
%
% Xstar = UQ_C1P1CMAES(FUN,X0,SIGMA0,LB,UB) defines  a set of lower and
% upper bounds so that LB <= Xstar <= UB. If X0 = [] and/or SIGMA0 = [],
% the center of the search space and 1/3 of the search space width will be
% used as default parameters for X0 and SIGMA0 respectively.
%
% Xstar = UQ_C1P1CMAES(FUN,X0,SIGMA0,LB,UB,NONLCON) defines a set of non-
% linear inequatilies constraints. Set  LB = [] and UB = [] if there are no
% bound constraints

% Xstar = UQ_C1P1CMAES(FUN,X0,SIGMA0,LB,UB,NONLCON,OPTIONS) minimizes
% with default optimization options replaced by values in OPTIONS struct:
%     .Display: Display options - 'none'|{'iter'}|'final'
%     .MaxIter: Maximum number of iterations  - Integer|{1000}
%     .TolSigma: Convergence tolerance on SIGMA - double|{1e-6 * sigma0}
%     .TolFun: Convergence tolerance on FUN - double|{1e-12}
%     .nStallMax: Maximum number of stall generations - Integer{20}
%     .Internal: Default Internal parameters of CMAES. Already tuned.
%         (Strongly advised not to modify these parameters.
%          See paper above for values)
%
% [Xstar,FVAL] = UQ_C1P1CMAES(FUN,X0,SIGMA0,...) returns the value of the
% objective function at the solution Xstar
%
% [Xstar,FVAL,EXITFLAG] = UQ_C1P1CMAES(FUN,X0,SIGMA0,...) returns an exit
% flag that describes termination condition:
%   1  : Maximum number of generations reached
%   2  : Maximum number of stall generations reached
%   3  : Step Size is smaller than TOLSIGMA
%   4  : The relative change of FUN is smaller than TOLFUN
%   <0 : No feasible solution was found (may be not - à voir)
%
% [Xstar,FVAL,EXITFLAG, OUTPUT] = UQ_C1P1CMAES(FUN,X0,SIGMA0,...) retunrs a
% structure with additional information about the optimization process:
%     .iterations: Total number of iterations
%     .funccount: Total number of fitness function evaluations
%     .conscount: Total number of contraints function evaluations
%     .History: A detailed history of the optimization process (X, FUN(X)
%               at each iteration)
%
% General information: Mandatory parameters are {FUN,X0,SIGMA0} or
% {FUN,lb,ub}. Optional parameters can be replaced by [] in the call of the
% function.

%% Pre-prcessing and parameters checking
% Check the number of input arguments
try
    narginchk(3,7);
catch ME
    error('Wrong number of input arguments');
end
if nargin < 7, options = [] ;
    if nargin < 6, nonlcon = [] ;
        if nargin < 5, ub = [] ;
            if nargin < 4, lb = [] ;
            end
        end
    end
end
% Consistency checks and get number of variables
% Check if given input is row or vector (for multidemensional inputs)
if isempty(x0) && ( isempty(lb) || isempty(ub) )
    error('Either initial point or bounds should be given') ;
elseif isempty(x0) && ~isempty(lb) && ~isempty(ub)
    % Initial points is not given but bounds are
    % Make sure lb and ub are of equal sizes
    if length(lb) ~= length(ub)
        error('Dimension mismatch between lb and ub !') ;
    end
    nvars = length(lb(:)) ;
    x0 = (lb + ub)/2 ;
    if isnan(x0)
        error('Bounds should have finite values if initial point is not given') ;
    end
elseif ~isempty(x0) && ( isempty(lb) || isempty(ub) )
    % x0 is given but not lb and ub
    nvars = length(x0(:)) ;
elseif ~isempty(x0) && ~isempty(lb) && ~isempty(ub)
    % x0, lb and ub are given. Check that dimensions match
    % Make sure lb and ub are of equal sizes
    if length(lb) ~= length(ub)
        error('Dimension mismatch between lb and ub !') ;
    end
    nvars = length(x0(:)) ;
    if length(lb) ~= nvars && length(lb) == 1
        lb = repmat(lb,nvars,1);
        ub = repmat(ub,nvars,1);
    end
    % Check that initial point is in bounds. Otherwise re-sample a new one:
    if any(x0 < lb) || any(x0 > ub)
        warning('Initial points in not in bounds') ;
        fprintf('Calculating a new one: random uniform sample on the search space') ;
        x0 = rand(nvars,1) .* (ub - lb) + lb ;
    end
end
% Set initial value of sigma0 if not given by the user
if isempty(sigma0) && (isempty(lb) || isempty(ub))
    error('Either initial sigma value or bounds should be given') ;
elseif isempty(sigma0) && ~isempty(lb) && ~isempty(ub)
    sigma0 = (ub - lb)/3 ;
end
if length(sigma0) == 1 && nvars > 1
    sigma0 = sigma0 * ones(nvars,1) ;
end
if length(sigma0) ~= nvars && length(sigma0) > 1
    error('SIGMA0 should be either a scalar or a vector of size NVARS!') ;
end
% Make everything column
if isrow(x0)
    FunTakesRow = true ;
    x0 = x0(:);
else
    FunTakesRow = false ;
end
if isrow(sigma0), sigma0 = sigma0(:) ; end
if isrow(lb), lb = lb(:) ; end
if isrow(ub), ub = ub(:) ; end
% In case inputs are transposed, make sure that the function handles handle
% it properly
if FunTakesRow
    funfcn = @(x)fun(x') ;
    nonlconfcn = @(x, flag, iteration) nonlcon(x', flag, iteration) ;
else
    funfcn = @(x)fun(x) ;
    nonlconfcn = @(x, flag, iteration) nonlcon(x, flag, iteration) ;
end

% Now start assigning default parameters
% Assign default parameters
if isempty(options)
    options = struct ;
end
if ~isfield(options,'Display')
    Display = 'iter' ;
else
    Display = options.Display ;
end
if ~isfield(options,'MaxIter')
    MaxIter = 1000*(nvars+5)^2;
else
    MaxIter = options.MaxIter;
end
if ~isfield(options,'TolSigma')
    if ~isempty(sigma0)
        TolSigma = 1e-11 * max(sigma0);
    else
        TolSigma = [] ;
    end
else
    TolSigma = options.TolSigma;
end
if ~isfield(options,'TolFun')
    TolFun = 1e-12 ;
else
    TolFun = options.TolFun ;
end
if ~isfield(options,'nStallMax')
    nStallMax = 10 + 30*nvars ;
else
    nStallMax = options.nStallMax ;
end
if ~isfield(options,'MaxFunEval')
    MaxFunEval = Inf ;
else
    MaxFunEval = options.MaxFunEval ;
end
if ~isfield(options, 'feasiblex0')
    feasiblex0 = true ;
else
    feasiblex0 = options.feasiblex0 ;
end

% Internal CMA-ES parameters
if ~isfield(options, 'Strategy')
    options.Strategy = struct ;
end
if isfield(options.Strategy,'dp')
    dp =  options.Strategy.dp;
else
    dp = 1 + nvars/2 ;
end
if isfield(options.Strategy,'c')
    c =  options.Strategy.c;
else
    c = 2/(nvars + 2) ;
end
if isfield(options.Strategy,'cp')
    cp =  options.Strategy.cp;
else
    cp = 1/12 ;
end
if isfield(options.Strategy,'Ptarget')
    Ptarget =  options.Strategy.Ptarget;
else
    Ptarget = 2/11 ;
end
if isfield(options.Strategy,'ccovp')
    ccovp =  options.Strategy.ccovp;
else
    ccovp = 2/(nvars^2 + 6) ;
end
if isfield(options.Strategy,'cc')
    cc =  options.Strategy.cc;
else
    cc = 1/(nvars+2) ;
end
if isfield(options.Strategy,'beta')
    beta =  options.Strategy.beta;
else
    beta = 0.1 / (nvars+2) ;
end
if isfield(options.Strategy,'isactiveCMA')
    isactiveCMA =  options.Strategy.isactiveCMA;
else
    isactiveCMA = true ;
end
% Enrichment options
if ~isfield(options, 'Enrichment')
    options.Enrichment = struct ;
end
if isfield(options.Enrichment,'Restart')
    restart =  options.Enrichment.Restart ;
else
    restart = true ;
end

% Make sure that TolSigma is of proper size
if length(TolSigma) == 1 && nvars > 1
    TolSigma = TolSigma * ones(nvars,1) ;
end
if isempty(TolSigma)
    TolSigma = 1e-11*sigma0 ;
end
if length(TolSigma) ~= nvars && length(TolSigma) > 1
    error('TOLSIGMA should be either a scalar or a vector of size NVARS!') ;
end

%% Save some options
Internal.MaxIter = MaxIter ;
Internal.MaxFunEval = MaxFunEval ;
Internal.TolSigmA = TolSigma ;
Internal.TolFun = TolFun ;
Internal.nStallMax = nStallMax ;

%% Initialization
iteration = 0 ;
x_current = x0 ;
sigma_current = sigma0 ;
f_best_ever = Inf ;
% Initial fitness value
f = funfcn(x_current) ;
% Number of fitness evaluations
nfeval = 1 ;
update_flag = 0 ;
% Initial constraint(s) value(s)
if ~isempty(nonlcon)
    [g, dummy_flag] = nonlconfcn(x_current, update_flag, iteration) ;
    if isrow(g), g = g' ; end
else
    g = [] ;
end

% Add bound constraints to g
g = uq_addboundconstraints(x_current,g,lb,ub) ;
% Number of constraint evaluation
ngeval = 1 ;
% Number of constraints (including bounds)
nconsts = length(g) ;
if all(g <= 0)
    % Initial point is feasible
    status = 1 ;
    x_best_ever = x_current ;
    f_best_ever = f ;
else
    % This also means that there is a non-linear constraint
    if feasiblex0
        status = 1 ;
        trials = 0 ;
        while any(g > 0)
            if all(isfinite(lb) & isfinite(ub))
                if trials == 0
                    fprintf('Initial point is not feasible. Searching for a new one by random uniform sample on the search space') ;
                end
                x_current = rand(nvars,1) .* (ub - lb) + lb ;
            else
                if trials == 0
                    fprintf('Initial point is not feasible. Searching for a new one b sampling following the initial normal distribution') ;
                end
                x_current = randn(nvars,1).* sigma0 + x0 ;
            end
            % Evaluate constraint
            [g, dummy_flag] = nonlconfcn(x_current, update_flag, iteration) ;
            ngeval = ngeval + 1 ;
            trials = trials + 1 ;
            if trials > 100*nvars^2 % This should be improved. Set dimension dependent limit or user-given
                warning('No feasible point could be found after 100*nvars^2 trials') ; % Rather output an error ?
                x_current = x0 ;
                status = -1 ;
                x_best_ever = x_current ;
                break ;
            end
        end
        if isrow(g), g = g' ; end
        % Reset number of trials
        trials = 0 ;
        % Evaluate point
        f = funfcn(x_current) ;
        % Update counter of fitness evaluation
        nfeval = nfeval + 1 ;
        % Add bounds to the constraints
        g = uq_addboundconstraints(x_current,g,lb,ub) ;
        if all(g <= 0)
            x_best_ever = x_current ;
            f_best_ever = f ;
        else
            % f_best_ever is Inf
        end
    else
        warning('Initial point is unfeasible. This could decrease performance of the algorithm') ;
        x_best_ever = x_current ;
        f_best_ever = Inf ;
        status = -1 ;
    end
end

history.x = zeros(nvars, MaxIter + 1) ;
history.fval = zeros(1,MaxIter + 1) ;
history.gval = zeros(nconsts, MaxIter + 1) ;
history.sigma = zeros(nvars, MaxIter+1 ) ;
history.status = zeros(1, MaxIter + 1) ;

history.x(:,1) = x_current ;
history.fval(:,1) = f ;
history.gval(:,1) = g(1:nconsts) ;
history.sigma(:,1) = sigma0 ;
history.status(:,1) = status ;
% Iteration number of the best feasible points + 1
NewBestPoint = 1 ;
nStall = 0;
exitflag = 0 ;
x_0 = x_current ;
f_0 = f ;
A = eye(nvars) ;
invA = eye(nvars) ;
s = zeros(nvars,1) ;
m = length(g) ;
v = zeros(nvars,m)  ;
w = zeros(nvars,m) ;
Psucc = Ptarget ;
f_ancestors = NaN * ones(1,5) ;
f_best_mem = NaN * ones(1, nStallMax) ;

% History fo best point
x_best_hist = [] ;
f_best_hist = [] ;
g_best_hist = [] ;
sigma_hist = [] ;
iter_hist =  [] ;
A_hist = [] ;
invA_hist = [] ;
f_anc_hist = [] ;
f_best_mem_hist = [] ;
s_hist = [] ;
Psucc_hist = [] ;
v_hist = [] ;
num_of_restart = 0 ;
restart_generation = 5 ;

%% Main constrained (1+1)-CMA-ES algorithm
if strcmpi(Display,'iter')
    fprintf('\n');
    fprintf('                               Best          Current       Stall\n');
    fprintf('Generation      f-count        f(x)            f(x)      Generations\n');
    fprintf('%i               %i      %12.6g    %12.6g         %i\n',...
        iteration, nfeval, f_best_ever, f, nStall);
end
while iteration <= MaxIter
    iteration = iteration + 1 ;
    % Generate offspring
    z = randn(nvars, 1) ;
    x_current = x_best_ever + sigma_current .* (A * z) ;
    
    % Evaluate fitness
    f = funfcn(x_current) ;
    nfeval = nfeval + 1 ;
    
    % Set the flag for possibly updating the metamodel: Consider updating
    % hte metamodel only if the current point is improving the current best
    % design
    if f <= f_best_ever && uq_isinbounds(x_current,lb,ub)
        update_flag = 1 ;
    else
        update_flag = 0 ;
    end
    % Evaluate the constraint
    if ~isempty(nonlcon)
        [g, newMeta_flag] = nonlconfcn(x_current, update_flag, iteration) ;
        if isrow(g), g = g' ; end
    else
        g = [] ;
    end
    
    g = uq_addboundconstraints(x_current,g,lb,ub) ;
    ngeval = ngeval + 1 ;
    
    if restart && newMeta_flag && length(f_best_hist) > 1
        % Re-compute the failure probabilties for the last iteration to see
        % whether there are still valid or not
        update_flag = 0 ;
        for i = min(restart_generation - 1,length(f_best_hist)-1):-1:0
            [g_new, dummy] = nonlconfcn(x_best_hist(:,end-i), update_flag, iteration) ;
            if any(g_new > 0)
                x_best_hist = x_best_hist(:,1:end-i-1) ;
                f_best_hist = f_best_hist(:,1:end-i-1) ;
                g_best_hist = g_best_hist(:,1:end-i-1) ;
                sigma_hist = sigma_hist(:,1:end-i-1) ;
                iter_hist =  iter_hist(:,1:end-i-1) ;
                A_hist = A_hist(:,1:end-nvars*(i+1)) ;
                invA_hist = invA_hist(:,1:end-nvars*(i+1)) ;
                f_best_mem_hist = f_best_mem_hist(1:end-i-1,:) ;
                f_anc_hist = f_anc_hist(1:end-i-1,:) ;
                s_hist = s_hist(:,1:end-i-1) ;
                Psucc_hist = Psucc_hist(:,1:end-i-1) ;
                v_hist = v_hist(1:end-nvars*(i+1),:) ;
                
                prev_best_modified = true ;
                if isempty(x_best_hist)
                    % This means all the points have been disapproved by the new metamodel
                    % Restart from zero
                    x_best_ever = x_0 ;
                    f_best_ever = f_0 ;
                    [g, dummy_flag] = nonlconfcn(x_best_ever, update_flag, iteration) ;
                    if isrow(g), g = g' ; end
                    if any(g>0)
                        f_best_ever = Inf ;
                    end
                    g = uq_addboundconstraints(x_current,g,lb,ub) ;
                    x_current = x_best_ever ;
                    iteration = 0 ;
                    sigma_current = sigma0 ;
                    A = eye(nvars) ;
                    invA = eye(nvars) ;
                    s = zeros(nvars,1) ;
                    m = length(g) ;
                    v = zeros(nvars,m)  ;
                    Psucc = Ptarget ;
                    f = f_best_ever ;
                    f_best_mem = NaN * ones(1, nStallMax) ;
                    f_ancestors = NaN * ones(1,5) ;
                    num_of_restart = num_of_restart + 1 ;
                else
                    x_best_ever = x_best_hist(:,end) ;
                    f_best_ever = f_best_hist(:,end) ;
                    g = g_best_hist(:,end) ;
                    x_current = x_best_ever ;
                    iteration = iter_hist(:,end) ;
                    sigma_current = sigma_hist(:,end) ;
                    A = A_hist(:,end-nvars+1:end) ;
                    invA = invA_hist(:,end-nvars+1:end) ;
                    f = f_best_ever ;
                    f_best_mem = f_best_mem_hist(end,:) ;
                    f_ancestors = f_anc_hist(end,:) ;
                    num_of_restart = num_of_restart + 1 ;
                    s = s_hist(:,end) ;
                    v = v(end-nvars+1:end,:) ;
                    
                    Psucc = Psucc_hist(:,end) ;
                end
                break ;
            else
                prev_best_modified = false ;
            end
        end
    else
        % Either no restart is turned off, or no newmetamodel was created or we don't have enough history to go back up so:
        % Set that : The previous best point has not been modified
        prev_best_modified = false ;
    end
    
    if prev_best_modified
        
        % Do nothing
        
    else
        % Get violated constraints indices
        Idx_violated = find(g > 0) ;
        
        % Update covariance matrix Cholesky decomposition
        if ~isempty(Idx_violated)
            % Case sampled point is unfeasible
            status = -1 ;
            
            % 1. update v
            v(:,Idx_violated) = (1 - cc) * v(:,Idx_violated) + repmat(cc * A * z, 1, length(Idx_violated)) ;
            % 2. update v and Svw
            Svw = zeros(nvars,nvars) ;
            for j = 1:m
                if g(j) > 0
                    w(:,j) = invA * v(:,j) ;
                    Svw = Svw + ( ( v(:,j) * w(:,j)' ) / (w(:,j)' * w(:,j)) );
                end
            end
            % 3. update A
            A = A - (beta/length(Idx_violated)) * Svw ;
            % 4. Compute inverse of A. Note no updating formula available in this case
            invA = pinv(A) ;  % Use pinv ?
        else
            % case sampled point is feasible
            
            Psucc = (1 - cp) * Psucc + cp * (f <= f_best_ever) ;
            sigma_current = sigma_current * exp( (Psucc - Ptarget) / ( dp * (1 - Ptarget) ) );
            
            if f <= f_best_ever
                % Current point improves best solution
                status = 1 ;
                
                % Update current solution
                x_best_ever = x_current ;
                f_best_ever = f ;
                
                
                % Update A
                s = (1-c) * s + sqrt( c * (2 - c) ) * A * z;
                w = invA * s;
                w2 = sum(w.^2);
                a = sqrt(1 - ccovp) ;
                b = sqrt(1 - ccovp)/w2 * ( sqrt( 1 + ccovp/(1 - ccovp)*w2) - 1 ) ; % ( sqrt(1 - ccovp) / w2 ) * ( sqrt(1 + (ccovp * w2)/(1 - ccovp)) - 1 )
                A = a * A + b * s * w';
                
                % Update invA (following [2])
                invA = 1/a * invA - (b/(a^2 + a*b*w2)) * w * (w'*invA) ;
                
                % k-th order ancestor success
                f_ancestors = [f_ancestors(2:end), f] ;
                f_best_mem = [f_best_mem(2:end), f]; % Best objective over nStall iterations
                nStall = 0 ;
                NewBestPoint = [NewBestPoint, iteration] ;
                
                % Save history to be used in case of restart
                x_best_hist = [x_best_hist x_best_ever] ;
                f_best_hist = [f_best_hist f_best_ever] ;
                g_best_hist = [g_best_hist g] ;
                sigma_hist = [sigma_hist, sigma_current] ;
                iter_hist =  [iter_hist, iteration] ;
                A_hist = [A_hist, A] ;
                invA_hist = [invA_hist, invA] ;
                f_best_mem_hist = [f_best_mem_hist ; f_best_mem] ;
                f_anc_hist = [f_anc_hist ; f_ancestors] ;
                s_hist = [s_hist, s] ;
                Psucc_hist = [Psucc_hist, Psucc] ;
                v_hist = [v_hist; v] ;
                
            else
                % Point is feasible but does not improve the current best point
                status = 0 ;
                nStall = nStall + 1 ;
                if isactiveCMA
                    if ~isnan(f_ancestors(1)) && f > f_ancestors(1)
                        z2 = sum(z.^2) ;
                        ccovm = min(0.4/(nvars^(1.6) + 1) , 1 / ( 2* z2 - 1) );
                        if ccovm <= -1, ccovm = 0.4/(nvars^1.6 + 1) ; end % Numerical fix - Nopt sure it is the best wa to do
                        a = sqrt(1 + ccovm) ;
                        b = ( sqrt(1 + ccovm) / z2 ) * ( sqrt(1 - (ccovm * z2)/(1 + ccovm)) - 1) ;
                        A = a * A + b * (A * z) * z' ;
                        % Update of the inv(A) made following paper [2]
                        invA = 1/a * invA - (b/(a^2 + a*b*z2)) * z * (z'*invA) ;
                    end
                end
            end
        end
        
    end
 
    if nfeval > 2000
        restart_generation = 3 ;
    end
    if nfeval > 5000
        restart = false ;
    end

    % save history
    history.x(:,iteration +1) = x_current ;
    history.fval(:,iteration + 1) = f ;
    history.gval(:,iteration +1 ) = g(1:nconsts) ;
    history.sigma(:,iteration + 1) = sigma_current ;
    history.status(:,iteration + 1) = status ;
    % Reporting
    if strcmpi(Display,'iter')
        fprintf('%i               %i      %12.6g    %12.6g         %i\n',...
            iteration, nfeval, f_best_ever, f, nStall);
    end
    
    % Stopping criteria
    % 1) If the maximum number of stall generations has been reached stop
    if  nStall >= nStallMax
        exitflag = 1 ;
        output.message = sprintf('Maximum number of stall generations (%i) achieved', nStallMax);
        break;
    end
    % 2) Maximum number of evalluatino o fthe fitness function reached
    if nfeval >= MaxFunEval
        exitflag = 2 ;
        output.message = sprintf('Maximum number of fitness evaluations (%i) reached', MaxFunEval);
        break;
    end
    %     % 3) Remember the last nStallMax F_best_ever and if the difference between
    %     %    the max and min is below TolFun stop
    if ~isnan(f_best_mem(1)) &&  f_best_mem(1) - f_best_mem(end)  <= TolFun
        exitflag = 3 ;
        output.message = sprintf('Relative change in fitness over %i iterations is below tolerance %g',nStallMax,TolFun) ;
        break;
    end
    % 4) If sigma < TolSigma stop
    if sigma_current < TolSigma
        exitflag = 4 ;
        output.message = sprintf('Step size sigma is below tolerance %g',max(TolSigma)) ;
        break;
    end
    
end
if f_best_ever == Inf
    % NO feasible solution was found
    exitflag = -1 ;
    output.message = sprintf('No feasible point was found') ;
end
%% Return results
if strcmpi(Display,'iter') || strcmpi(Display,'final')
    switch exitflag
        case 0
            fprintf('\n\nMaximum number of generations (options.MaxIter) reached\n') ;
        case 1
            fprintf('\nMaximum number of stall generations (options.nStallMax) reached\n') ;
        case 2
            fprintf('\nMaximum number of fitness evaluation (options.MaxFunEval) reached\n') ;
        case 3
            fprintf('\nThe relative change of F was below options.TolFun\n') ;
        case 4
            fprintf('\nValue of sigma below options.TolSigma\n') ;
        case -1
            fprintf('\nNo feasible point was found\n') ;
    end
    fprintf('obj. value = %12.6g \n',f_best_ever)
end

if FunTakesRow
    xstar = x_best_ever' ;
    history.x = history.x(:,1:iteration+1)' ;
    history.fval = history.fval(:,1:iteration+1)' ;
    history.gval = history.gval(:,1:iteration+1)' ;
    history.sigma = history.sigma(:,1:iteration+1)' ;
    history.status = history.status(:,1:iteration+1)' ;
    
else
    xstar = x_best_ever ;
    history.x = history.x(:,1:iteration+1) ;
    history.fval = history.fval(:,1:iteration+1) ;
    history.gval = history.gval(:,1:iteration+1) ;
    history.sigma = history.sigma(:,1:iteration+1) ;
    history.status = history.status(:,1:iteration+1) ;
    
end
fval = f_best_ever ;
output.iterations = iteration ;
output.funccount = nfeval ;
output.constcount = ngeval ;
output.History = history ;
output.Internal = Internal ;
output.NewBestPoint = NewBestPoint ;
output.num_of_restart = num_of_restart ;
end

function g = uq_addboundconstraints(x,g,lb,ub)

if ~isempty(lb)
    g = [g ; lb - x ] ;
end
if ~isempty(ub)
    g = [g ; x - ub ] ;
end

end

function result = uq_isinbounds(x,lb,ub)

if all(x-lb>=0) && all(ub-x >= 0)
    result = true ;
else
    result = false ;
end
end