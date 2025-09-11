function OptimOptions = uq_Kriging_initialize_optimizer(current_model)
%UQ_KRIGING_INITIALIZE_OPTIMIZER parses various optimization options. 
%
%   OptimOptions = uq_Kriging_initialize_optimizer(current_model) returns
%   the structure OptimOptions parsed from the current_model internal
%   optimization options structure. OptimOptions is used in the call to
%   the optimization algorithm.
%
%   Summary:
%   The parsed optimization options depend on the selected optimization
%   method. For model with multiple outputs, it is assumed that for each
%   output the same optimization method will be used taken from the options
%   of the first output.
%
%   Side-effect:
%   The function will change the current state of current_model,
%   by filtering out the constant input variables from the initial values
%   and bounds arrays.
%
%   See also UQ_KRIGING_OPTIMIZER, UQ_KRIGING_CALCULATE,
%   UQ_KRIGING_HELPER_ASSIGN_OPTIONOPTIM.

%% Set some local variables
evalRFunctionName = 'uq_eval_Kernel';  % The default correlation calculator
nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
InternalKriging = current_model.Internal.Kriging(1);  % Variable shorthand

%% Filter out constants from the initial value and bounds definition
if strcmpi(func2str(InternalKriging.GP.Corr.Handle), evalRFunctionName)    
    
    isIsotropic = InternalKriging.GP.Corr.Isotropic;
    if ~isIsotropic

        if isfield(InternalKriging.Optim,'InitialValue')
            % Keep only the initial values that correspond to
            % the non-constant input variables
            current_model.Internal.Kriging(1).Optim.InitialValue = ...
                InternalKriging.Optim.InitialValue(nonConstIdx);
        end

        if isfield(InternalKriging.Optim,'Bounds')
            % Keep only the bounds that correspond to
            % the non-constant input variables
            current_model.Internal.Kriging(1).Optim.Bounds = ...
                InternalKriging.Optim.Bounds(:,nonConstIdx);
        end        
    end
    % NOTE: Do nothing about constants,
    % assume that at least one input variable is a non-constant.
end

% NOTE: If the default calculator for correlation matrix is not used, the
% user is responsible to set the initial values and bounds arrays with the
% proper dimensions. Constant input variables should be excluded from
% the two arrays specification.

%% Parse the Optimization (.Optim) options
switch lower(InternalKriging.Optim.Method)

    case 'none'
        %% No optimization
        OptimOptions = [];

    case {'gradbased', 'lbfgs', 'bfgs'}
        %% Gradient-based optimization
        OptimOptions = optimset(...
            'Display', lower(InternalKriging.Optim.Display),...
            'MaxIter', InternalKriging.Optim.MaxIter,...
            'Algorithm', 'interior-point',...
            'Hessian', {'lbfgs',InternalKriging.Optim.BFGS.nLM},...
            'AlwaysHonorConstraints', 'bounds',...
            'TolFun', InternalKriging.Optim.Tol );

    case 'ga'
        %% Vanilla Genetic Algorithm (GA)
        OptimOptions = gaoptimset(...
            'Display', lower(InternalKriging.Optim.Display), ...
            'Generations', InternalKriging.Optim.MaxIter,...
            'PopulationSize', InternalKriging.Optim.GA.nPop,...
            'StallGenLimit', InternalKriging.Optim.GA.nStall,...
            'TolFun', InternalKriging.Optim.Tol);

    case 'hga'
        %% Hybrid Genetic Algorithm (HGA)
        % Options for GA (global)
        OptimOptions.ga = gaoptimset(...
            'Display', lower(InternalKriging.Optim.Display), ...
            'Generations', InternalKriging.Optim.MaxIter,...
            'PopulationSize', InternalKriging.Optim.HGA.nPop,...
            'StallGenLimit', InternalKriging.Optim.HGA.nStall,...
            'TolFun', InternalKriging.Optim.Tol);
        % Options for gradient-based (local)
        OptimOptions.grad = optimset(...
            'Display', lower(InternalKriging.Optim.Display),...
            'MaxIter', InternalKriging.Optim.MaxIter,...
            'Algorithm', 'interior-point',...
            'Hessian', {'lbfgs',InternalKriging.Optim.HGA.nLM},...
            'AlwaysHonorConstraints', 'bounds',...
            'TolFun', InternalKriging.Optim.Tol);

    case 'cmaes'
        %% Covariance Matrix Adaptation-Evolution Strategy (CMAES)
        OptimOptions.Display = lower(InternalKriging.Optim.Display);
        OptimOptions.MaxIter = InternalKriging.Optim.MaxIter;
        OptimOptions.TolX = InternalKriging.Optim.Tol;
        OptimOptions.lambda = InternalKriging.Optim.CMAES.nPop;
        OptimOptions.nStallMax = InternalKriging.Optim.CMAES.nStall;
        OptimOptions.isVectorized = false;  % Output NOT vectorized
        
    case 'hcmaes'
        %% Hybrid Covariance Matrix Adaptation-Evolution Strategy (HCMAES)
        % Options for CMAES (global)
        OptimOptions.cmaes.Display = lower(InternalKriging.Optim.Display);
        OptimOptions.cmaes.MaxIter = InternalKriging.Optim.MaxIter;
        OptimOptions.cmaes.TolX = InternalKriging.Optim.Tol;        
        OptimOptions.cmaes.lambda = InternalKriging.Optim.HCMAES.nPop;
        OptimOptions.cmaes.nStallMax = InternalKriging.Optim.HCMAES.nStall;
        OptimOptions.cmaes.isVectorized = false ; % Output NOT vectorized
        % Options for gradient-based (local)
        OptimOptions.grad = optimset(...
            'Display', lower(InternalKriging.Optim.Display),...
            'MaxIter', InternalKriging.Optim.MaxIter,...
            'Algorithm', 'interior-point',...
            'Hessian', {'lbfgs',InternalKriging.Optim.HCMAES.nLM},...
            'AlwaysHonorConstraints', 'bounds',...
            'TolFun', InternalKriging.Optim.Tol);

    case 'sade'
        %% Self-Adaptive Differential Evolution (SADE)
        OptimOptions.Display = lower(InternalKriging.Optim.Display);
        OptimOptions.MaxIter = InternalKriging.Optim.MaxIter;
        OptimOptions.TolFun = InternalKriging.Optim.Tol;
        OptimOptions.nStall = InternalKriging.Optim.SADE.nStall;
        OptimOptions.Strategies = InternalKriging.Optim.SADE.Strategies;
        OptimOptions.pStr = InternalKriging.Optim.SADE.pStr;
        OptimOptions.CRm = InternalKriging.Optim.SADE.CRm;

    case 'hsade'
        %% Hybrid Self-Adaptive Differential Evolution (HSADE)        
        % Options for SADE (global)
        OptimOptions.sade.Display = lower(InternalKriging.Optim.Display);
        OptimOptions.sade.MaxIter = InternalKriging.Optim.MaxIter;
        OptimOptions.sade.TolFun = InternalKriging.Optim.Tol;
        OptimOptions.sade.nStall = InternalKriging.Optim.HSADE.nStall;
        OptimOptions.sade.Strategies = ...
            InternalKriging.Optim.HSADE.Strategies;
        OptimOptions.sade.pStr = InternalKriging.Optim.HSADE.pStr;
        OptimOptions.sade.CRm = InternalKriging.Optim.HSADE.CRm;
        
        % Options for gradient-based (local)
        OptimOptions.grad = optimset(...
            'Display', lower(InternalKriging.Optim.Display),...
            'MaxIter', InternalKriging.Optim.MaxIter,...
            'Algorithm', 'interior-point',...
            'Hessian', {'lbfgs',InternalKriging.Optim.HSADE.nLM},...
            'AlwaysHonorConstraints', 'bounds',...
            'TolFun', InternalKriging.Optim.Tol);
end

end
