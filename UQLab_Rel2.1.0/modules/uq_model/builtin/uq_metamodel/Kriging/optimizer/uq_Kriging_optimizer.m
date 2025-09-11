function [theta,Jstar,fcount,nIter,exitflag] = ...
    uq_Kriging_optimizer(X, Y, optim_options, current_model)
%UQ_KRIGING_OPTIMIZER optimizes the Kriging model hyperparameters.
%
%   THETA = UQ_KRIGING_OPTIMIZER(X, Y, OPTIM_OPTIONS, CURRENT_MODEL)
%   returns the optimal values of hyperparameters THETA of the Kriging
%   model CURRENT_MODEl using X and Y as the experimental design with
%   the options for the optimization algorithm stored in
%   the structure OPTIM_OPTIONS.
%
%   [THETA,JSTAR] = .UQ_KRIGING_OPTIMIZER(...) additionally returns
%   the value of the objective function at the optimum solution JSTAR.
%
%   [THETA,JSTAR,FCOUNT] = UQ_KRIGING_OPTIMIZER(...) additionally returns
%   the number of the objective function evaluations that takes place
%   during the optimization process.
%
%   [THETA,JSTAR,FCOUNT,NITER] = UQ_KRIGING_OPTIMIZER(...) additionally
%   returns the number of iterations or generations of the optimization
%   method.
%
%   [THETA,JSTAR,FCOUNT,NITER,EXITFLAG] = UQ_KRIGING_OPTIMIZER(...)
%   additionally returns an exit flag that indicates the termination
%   condition of the optimization method. The values of EXITFLAG depend
%   on the optimization method used (see for instance, fmincon, ga, cmaes).
%
%   See also UQ_KRIGING_CALCULATE, UQ_KRIGING_INITIALIZE_OPTIMIZER, 
%   UQ_KRIGING_EVAL_J_OF_THETA_CV, UQ_KRIGING_EVAL_J_OF_THETA_ML.

%% Read the options from the current model

% Obtain the current output
current_output = current_model.Internal.Runtime.current_output;

% Retrieve the handle of the appropriate objective function
switch lower(current_model.Internal.Kriging(current_output).GP.EstimMethod)
    case 'ml'
        objFunHandle = str2func('uq_Kriging_eval_J_of_theta_ML');
    case 'rml'
        objFunHandle = str2func('uq_Kriging_eval_J_of_theta_RML');
    case 'cv'
        objFunHandle = str2func('uq_Kriging_eval_J_of_theta_CV');
end

% Retrieve the number of input variables
M = current_model.Internal.Runtime.M;

%% Define variable shorthands
InternalKriging = current_model.Internal.Kriging(current_output);
InternalRegression = current_model.Internal.Regression(current_output);

%% Get relevant parameters from input
% Organize in a simple structure the necessary parameters
% to solve this specific optimization problem.

% Experimental design
KrgModelParameters.X = X;  % Input
KrgModelParameters.Y = Y;  % Output
KrgModelParameters.N = current_model.Internal.Runtime.N;  % Size

% Trend
KrgModelParameters.F = InternalKriging.Trend.F;  % Observation matrix
KrgModelParameters.trend_type = InternalKriging.Trend.Type;  % Trend type

% Correlation options
KrgModelParameters.CorrOptions = InternalKriging.GP.Corr;

% Estimation method
estim_method = InternalKriging.GP.EstimMethod;
if strcmpi(estim_method,'cv')
    % The CV folds (classes) each of which contains the exp. design indices
    KrgModelParameters.RandIdx = current_model.Internal.Runtime.CV.RandIdx;
end

% Kriging model (regression or interpolation)
KrgModelParameters.IsRegression = InternalRegression.IsRegression;
KrgModelParameters.EstimNoise = InternalRegression.EstimNoise;
if KrgModelParameters.IsRegression
    sigmaNSQ = InternalRegression.SigmaNSQ;
    if isscalar(sigmaNSQ)
        % Homoscedastic
        KrgModelParameters.sigmaNSQ = eye(KrgModelParameters.N) * sigmaNSQ;
    elseif iscolumn(sigmaNSQ)
        % Heteroscedastic, independent
        KrgModelParameters.sigmaNSQ = diag(sigmaNSQ);
    else
        % Heteroscedastic, with covariance (assign as is)
        KrgModelParameters.sigmaNSQ = sigmaNSQ;
    end
end

%% Find the number of the optimization variables
if strcmpi(func2str(InternalKriging.GP.Corr.Handle),'uq_eval_kernel')
    % Use the built-in uq_eval_Kernel to calculate R
    
    % Keep track of the non-constants
    nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
    % Get the isotropy of the correlation function
    isIsotropic = InternalKriging.GP.Corr.Isotropic;
    
    % Determine the number of optimization variables
    if isIsotropic
        nVars = 1;
        % do nothing about constants, 
        % assume that at least one variable is non-constant.
    else
        % NOTE: It is assumed for anisotropic correlation functions
        % there exists *one* optimization variable per dimension.
        % That might not be the case in a future release.
        nVars = length(nonConstIdx);
    end
    
    if KrgModelParameters.IsRegression
        nVars = nVars + 1;
    end
else
    % Use a user-defined correlation matrix calculator
    
    % Keep track of the non-constants:
    nonConstIdx = current_model.Internal.Runtime.nonConstIdx;
    
    % Find the optimization variable size by the initial value
    % and/or the bounds that were defined;
    % if both are defined they should be consistent!
    nVars = [];
    if isfield(InternalKriging.Optim,'InitialValue')
        initval_definition = InternalKriging.Optim.InitialValue;
        nVars = [nVars; length(initval_definition)];
    end

    if isfield(InternalKriging.Optim,'Bounds')
        % Keep only the bounds that correspond
        % to the varying dimensions of the metamodel
        bounds_definition = InternalKriging.Optim.Bounds;
        nVars = [nVars; size(bounds_definition,2)];
    end

    switch length(nVars)
        case 0 
            error(['Kriging optimization error: either ',...
                   'the InitialValue or Bounds need to be defined!'])
        case 1
            % Either initial values or bounds are given, do nothing
        case 2
            if nVars(1) ~= nVars(2)
                error(['Kriging optimization error: Inconsistent ',...
                       'dimensions between the InitialValue and Bounds!'])
            end
            nVars = nVars(1);
    end

end

%% Execute optimization based on the selected method
switch lower(current_model.Internal.Kriging(current_output).Optim.Method)

    case 'none'
        % No optimization
        theta = current_model.Internal.Kriging(current_output). ...
            Optim.InitialValue;
        Jhandle = @(theta)objFunHandle(theta, KrgModelParameters);
        Jstar = Jhandle(theta);
        fcount = 1;
        nIter = 0;
        exitflag = 1;

    case {'gradbased','lbfgs', 'bfgs'}
        % Gradient-based optimization
        LB = InternalKriging.Optim.Bounds(1,:);
        UB = InternalKriging.Optim.Bounds(2,:);
        theta0 = InternalKriging.Optim.InitialValue;
        % Store the initial value of objective function
        current_model.Internal.Kriging(current_output). ...
            Optim.InitialObjFun = objFunHandle(theta0, KrgModelParameters);
        
        % Optimize using gradient-based optimization ('fmincon')
        [theta,Jstar,exitflag,output] = ...
            fmincon(@(theta)objFunHandle(theta, KrgModelParameters),...
                theta0,...
                [], [], [], [], LB, UB, [], optim_options);

        fcount = output.funcCount;
        nIter = output.iterations;

    case 'knitro'
        % Knitro optimization
        LB = InternalKriging.Optim.Bounds(1,:);
        UB = InternalKriging.Optim.Bounds(2,:);
        theta0 = InternalKriging.Optim.InitialValue;
        % Store the initial value of objective function
        current_model.Internal.Kriging(current_output). ...
            Optim.InitialObjFun = objFunHandle(theta0, X, current_model);

        % Optimize
        [theta,Jstar,exitflag,output] = ...
            ktrlink(@(theta)objFunHandle(theta, KrgModelParameters),...
                theta0, [], [], [], [], LB, UB, [], optim_options);

        fcount = output.funcCount;
        nIter = output.iterations;

    case 'ga'
        % Vanilla Genetic Algorithm (GA)
        LB = InternalKriging.Optim.Bounds(1,:);
        UB = InternalKriging.Optim.Bounds(2,:);

        % Optimize
        [theta,Jstar,exitflag,output] = ga(...
            @(theta)objFunHandle(theta, KrgModelParameters),...
            nVars, [], [], [], [], LB, UB, [], optim_options);

        fcount = output.funccount;
        nIter = output.generations;

    case 'hga'
        % Hybrid Genetic Algorithm optimization
        LB = InternalKriging.Optim.Bounds(1,:);
        UB = InternalKriging.Optim.Bounds(2,:);

        % Optimize with 'ga'
        [theta,~,exitflag.GA,output] = ga(...
            @(theta)objFunHandle(theta, KrgModelParameters),...
            nVars,...
            [], [], [], [], LB, UB, [], optim_options.ga);
        fcountGA = output.funccount; 
        nIterGA = output.generations;
        
        % Refine the result using a gradient-based optimization ('fmincon')
        [theta,Jstar,exitflag.BFGS,output] = fmincon(...
            @(theta)objFunHandle(theta, KrgModelParameters),...
            theta,...
            [], [], [], [], LB, UB, [], optim_options.grad);
        fcountGRAD = output.funcCount;
        nIterGRAD = output.iterations;

        % Get function evaluation counts
        fcount = fcountGA + fcountGRAD;  % Total

        % Get iteration counts
        nIter = nIterGA;  % nIterGRAD is not taken into account

    case 'sade'
        % Self-Adaptive Differential Evolution optimization
        LB = InternalKriging.Optim.Bounds(1,:);
        UB = InternalKriging.Optim.Bounds(2,:);
        Npop = InternalKriging.Optim.SADE.nPop;

        % Optimize
        [theta,Jstar,output] = uq_optim_sade(...
            @(theta)objFunHandle(theta, KrgModelParameters),...
            nVars, Npop, LB, UB, optim_options);

        % Get function evaluation and iteration counts
        fcount = output.fcount;
        nIter = output.niter;
        exitflag = output.exitflag;

        % Store some additional interesting fields
        current_model.Internal.Kriging(current_output). ...
            Optim.Strategies = output.strategies;
        current_model.Internal.Kriging(current_output). ...
            Optim.pStrategies = output.pStrategies;
        current_model.Internal.Kriging(current_output). ...
            Optim.CRm = output.CRm;

    case 'hsade'
        % Hybrid Self-Adaptive Differential Evolution optimization
        LB = InternalKriging.Optim.Bounds(1,:);
        UB = InternalKriging.Optim.Bounds(2,:);
        Npop = InternalKriging.Optim.HSADE.nPop;

        % Optimize using SADE
        [theta,~,output] = uq_optim_sade(...
            @(theta)objFunHandle(theta,KrgModelParameters),...
            nVars, Npop, LB, UB, optim_options.sade);
        fcountDE = output.fcount;
        nIterDE = output.niter;
        exitflag.SADE = output.exitflag;

        % Store some extra interesting fields
        current_model.Internal.Kriging(current_output). ...
            Optim.Strategies = output.strategies;
        current_model.Internal.Kriging(current_output). ...
            Optim.pStrategies = output.pStrategies;
        current_model.Internal.Kriging(current_output). ...
            Optim.CRm = output.CRm;

        % Refine the result usin a gradient-based optimization ('fmincon')
        [theta,Jstar,exitflag.BFGS,output] = fmincon(...
            @(theta)objFunHandle(theta, KrgModelParameters),...
            theta,...
            [], [], [], [], LB, UB, [], optim_options.grad);
        fcountGRAD = output.funcCount;
        nIterGRAD = output.iterations;

        % Total number of function evaluations and iterations
        fcount = fcountDE + fcountGRAD;
        % nIterGRAD is not taken into account when calculating the total
        % number of iterations
        nIter = nIterDE;

    case 'cmaes'
        % Covariance-Matrix-Adaptation Evolution Strategy optimization
        LB = InternalKriging.Optim.Bounds(1,:);
        UB = InternalKriging.Optim.Bounds(2,:);

        % Optimize
        [theta,Jstar,exitflag,output] = uq_cmaes(...
            @(theta)objFunHandle(theta, KrgModelParameters),...
            [], [], LB, UB, optim_options);
        fcount = output.funccount;
        nIter = output.iterations;

    case 'hcmaes'
        % Hybrid CMAES optimization
        LB = InternalKriging.Optim.Bounds(1,:);
        UB = InternalKriging.Optim.Bounds(2,:);

        % Optimize
        [theta,~,exitflag.CMAES,output] = uq_cmaes(...
            @(theta)objFunHandle(theta, KrgModelParameters),...
            [], [], LB, UB, optim_options.cmaes);        
        fcountCMAES = output.funccount;
        nIterCMAES = output.iterations;

        % Refine the result using a gradient-based optimization ('fmincon')
        [theta,Jstar,exitflag.BFGS,output] = fmincon(...
            @(theta)objFunHandle(theta, KrgModelParameters),...
            theta, ...
            [], [], [], [], LB, UB, [], optim_options.grad);
        fcountGRAD = output.funcCount;
        nIterGRAD = output.iterations;

        % Total number of function evaluations and iterations
        fcount = fcountCMAES + fcountGRAD;
        % nIterGRAD is not taken into account when calculating the total
        % number of iterations 
        nIter = nIterCMAES; 

    otherwise
        errMsg = ['Error: Unknown method for optimizing ',...
            'the hyperparameters of the Kriging correlation function!']; 
        error(errMsg)

end

end