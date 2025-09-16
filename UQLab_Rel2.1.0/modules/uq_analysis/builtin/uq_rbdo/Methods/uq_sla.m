function results = uq_sla( current_analysis )
% book-keeping
History.X = [] ;
History.Score = [] ;

Options = current_analysis.Internal ;
%% Initialize BFGS
if  Options.Display <= 0
    Display = 'off' ;
elseif  Options.Display == 1
    Display = 'final' ;
else
    Display = 'iter' ;
end
% Cost function
fun = @(X) uq_evalCost( X, current_analysis ) ;
% Bounds of the search space
lb = Options.Optim.Bounds(1,:) ;
ub = Options.Optim.Bounds(2,:) ;
% Starting point
x0 = Options.Optim.StartingPoint ;
% For book-keeping
current_analysis.Internal.Runtime.RecordedConstraints = [] ;
% Compute the finite difference step size for gradient-based algorithms
if any(strcmpi(Options.Optim.Method,{'ip','sqp'}))
    % Step size for gradient-based methods
    GivenH = Options.Optim.(upper(Options.Optim.Method)).FDStepSize ;
    M_d = Options.Runtime.M_d ;
    if isscalar(GivenH) && M_d > 1
        GivenH = GivenH * ones(1,M_d) ;
    elseif isscalar(GivenH) && M_d == 1
        % Do nothing everything is consistent
    elseif ~isscalar(GivenH) && M_d == 1
        error('The size of the Finite Difference Step is not consistent with the dimensionality of the optimization problem') ;
    elseif ~isscalar(GivenH) && M_d > 1
        if length(GivenH) ~= M_d
            error('The size of the Finite Difference Step is not consistent with the dimensionality of the optimization problem') ;
        else
            % Do nothing, everything's fine and everybody's happy
        end
    end
    h = GivenH ;
    for ii = 1 : M_d
        if strcmpi(Options.Input.DesVar(ii).Runtime.DispersionMeasure, 'Std')
            if Options.Input.DesVar(ii).Std > 0
                h(ii) = GivenH(ii) * Options.Input.DesVar(ii).Std ;
            end
        else
            fprintf('Warning: The finite difference step type was set to relative but a CoV was given as measure of dispersion:\n') ;
            fprintf('The initial value of the standard deviation is used to compute h\n');
            h(ii) = GivenH(ii) * Options.Input.DesVar(ii).CoV * abs(x0(ii));
        end
    end
    current_analysis.Internal.Runtime.FDStepSize = h ;
end


Mz = Options.Runtime.M_z ;
if Mz > 0
    for jj = 1 : Mz
        current_analysis.Internal.Runtime.muZ(1,jj) = ...
            Options.Input.EnvVar.Marginals(jj).Moments(1) ;
        current_analysis.Internal.Runtime.sigmaZ(1,jj) = ...
            Options.Input.EnvVar.Marginals(jj).Moments(2) ;  
    end
end
% Non linear constraints: Hard and soft constraints
nonlcon = @(X)uq_matlabnonlconwrapper( X, current_analysis ) ;

% Find Non-Gaussian parameters
nonGaussianIdx.DesVar = ~ismember(lower({Options.Input.DesVar.Type}),{'gaussian','constant'}) ;
if Mz > 0
    nonGaussianIdx.EnvVar = ~ismember(lower({Options.Input.EnvVar.Marginals.Type}),{'gaussian','constant'}) ;
end
current_analysis.Internal.Runtime.nonGaussianIdx = nonGaussianIdx ;
% Get parameters ifthey do not exist
% if Options.Runtime.M_z > 0 
%     current_analysis.Internal.Input.EnvVar =  uq_MarginalFields(Options.Input.EnvVar) ;
% end
% Initialize optimization options
optim_options = uq_initializeLocalSLAOptimizer( current_analysis ) ;
% Run optimization problem
[Xstar,Fstar,exitflag,output] = fmincon(fun,x0,[],[],[],[],lb,ub,nonlcon,optim_options) ;

% Get an exit message
switch exitflag
    case 1
        exitMsg = 'First-order optimality criteria satisfied' ;
    case 0
        exitMsg = 'Maximum number of iterations reached!' ;
    case -2
        exitMsg = 'No feasible solution found!' ;
    case -3
        exitMsg = 'Objective function is below limit' ;
    case {2,3,4,5}
        exitMsg ='Miscelleneous: Converged to a local minimum' ;
end

results.Xstar = Xstar ;
results.Fstar = Fstar ;
results.exitMsg = exitMsg ;
results.output = output ;
results.output.exitflag = exitflag ;
results.History = History ;
results.ModelEvaluations = current_analysis.Internal.Runtime.ModelEvaluations ;

    function [optim_options] = uq_initializeLocalSLAOptimizer( current_analysis )
        History.X = [] ;
        History.Score = [] ;
        if strcmpi(current_analysis.Internal.Optim.Method, 'ip')
            OptimMethod = 'interior-point' ;
        else
            OptimMethod = current_analysis.Internal.Optim.Method ;
        end
        optim_options = ...
            optimoptions(@fmincon, 'OutputFcn', @(x,optimValues,state)outfun(x,optimValues,state,current_analysis), ...
            'Algorithm', OptimMethod, ...
            'Display', current_analysis.Internal.Optim.Display,...
            'MaxIter', current_analysis.Internal.Optim.MaxIter,...
            'TolX', current_analysis.Internal.Optim.TolX, ...
            'TolFun', current_analysis.Internal.Optim.TolFun, ...
            'MaxFunEvals', current_analysis.Internal.Optim.(upper(current_analysis.Internal.Optim.Method)).MaxFunEvals,...
            'FinDiffType', current_analysis.Internal.Optim.(upper(current_analysis.Internal.Optim.Method)).FDType,...
            'FinDiffRelStep', current_analysis.Internal.Runtime.FDStepSize);
        
        function stop = outfun(x,optimValues,state,current_analysis)
            
            stop = false ;
            switch state
                case 'init'
                    % Do nothing...
                    % Initial value is already saved in Histroy.X &.Score
                    
                    % Update the flag signaling that a new point is about
                    % to be computed
                    current_analysis.Internal.Runtime.isnewpoint = true ;
                case 'iter'
                    % Concatenate current point and objective function
                    % value with history. x must be a row vector.
                    History.Score = ...
                        [History.Score; optimValues.fval];
                    History.X = ...
                        [History.X; x];
                    % Update the flag signaling that a new point is about
                    % to be computed
                    current_analysis.Internal.Runtime.isnewpoint = true ;
                case 'done'
                    % Do nothing
                otherwise
                    % Do nothing
            end
        end
    end
end
