function success = uq_SVC_calculate_coefficients( module )
%UQ_SVC_CALCULATE_COEFFICIENTS(CURRENT_MODEL): calculate the SVC metamodel
%using options specified in CURRENT_MODEL
%
% See also: uq_svc_optimizer, uq_eval_kernel, etc.

success = 0;

%% session retrieval, argument and consistency checks
if exist('module', 'var')
    current_model = uq_getModel(module);
else
    current_model = uq_getModel;
end

%% argument and consistency checks
% let's check the model is of type "uq_metamodel"
if ~strcmp(current_model.Type, 'uq_metamodel')
    error('Error: uq_metamodel cannot handle objects of type %s', current_model.Type);
end

%% Reporting
DisplayLevel = current_model.Internal.Display ;
if DisplayLevel
    fprintf('---   Calculating the SVC metamodel...                              ---\n')
end

%% Generate the initial experimental design
% Get X
[current_model.ExpDesign.X, current_model.ExpDesign.U] = uq_getExpDesignSample(current_model);
% Get Y
current_model.ExpDesign.Y = uq_eval_ExpDesign(current_model,current_model.ExpDesign.X);
% Update the number of output variables of the model and store it
Nout = size(current_model.ExpDesign.Y, 2);
current_model.Internal.Runtime.Nout = Nout;
% Get the number of samples
N = size(current_model.ExpDesign.Y, 1);

% Issue an error if the training set has only one class
for oo = 1:Nout
    if all(current_model.ExpDesign.Y(:,oo) == 1) || all(current_model.ExpDesign.Y(:,oo) == -1)
        error('The training set only contains one label! One-class classificationis not supported');
    end
end
%%
% IMPORTANT: Now that we got the number of points - Set the default to Loss
% to l1-eps and default QPSolver to SMO ... IF the user did not give any
if N > 300
    
    if current_model.Internal.Runtime.UserGivenQPSolver
        if strcmpi(current_model.Internal.SVC(1).QPSolver,'ip')
            warning('The ED size is larger than 300. The selected QP solver may be slow. Please consider using SMO or ISDA.')
        end
    else
        if ~any( strcmpi(current_model.Internal.SVC(1).QPSolver, {'smo', 'isda'}) )
            current_model.Internal.SVC(1).QPSolver = 'smo' ;
            warning('The ED size is larger than 300. The default QP solver has been reverted to SMO.')
        end
        if strcmpi(current_model.Internal.SVC(1).Penalization, 'quadratic')
            current_model.Internal.SVC(1).Penalization = 'linear' ;
            if current_model.Internal.Runtime.UserGivenLoss
                warning('The penalization scheme of the QP problem has been reverted to ''linear'' because SMO is used.' ) ;
            end
        end
    end
    
    % Reduce the default upper bound of C
    if ~current_model.Internal.Runtime.UserGivenUpperC
        current_model.Internal.SVC.Optim.Bounds(2,1) = 2^10 ;
        % Just for consistency - This value is normally not used after
        % initialization...
        current_model.Internal.Runtime.Optim.Bounds.C(2) = 2^10 ;
    end
    
end

% Copy the necessary information about the SVC options to the various
% output coordinates
if Nout  > 1
    current_model.Internal.SVC(2:Nout) =  deal(current_model.Internal.SVC(1));
end

%% ----  SVC entry point
% Get in input traiing points (U = X in the reduced space)
X = current_model.ExpDesign.U ;
% Get the dimension of the problem
M = size(X,2) ;
current_model.Internal.Runtime.M = M ;
% Remove the constants, if any
nonConst = current_model.Internal.Runtime.nonConstIdx ;
X = X(:,nonConst);

% Set the default kernel parameters for those depending on the experimental
% design \ie the radial basis functions type kernels
% NaN values mean that UQLab's default values should be computed
if ~strcmpi(func2str(current_model.Internal.SVC(1).Kernel.Handle),'uq_eval_kernel')
    % Do nothing, assume that all parameters have been initialized in
    % uq_SVC_initialize
else
    % No parameters for the non-stationary linear kernel function
    if strcmpi(current_model.Internal.SVC(1).Kernel.Family,'linear_ns')
        for oo = 1:Nout
            current_model.Internal.SVC(oo).Hyperparameters.theta = [] ;
        end
    else
        
        if current_model.Internal.Runtime.isStationary
            if ( any(isnan(current_model.Internal.SVC(1).Hyperparameters.theta)) ...
                    || isnan(current_model.Internal.SVC(1).Optim.Bounds(1,2)) ...
                    || isnan(current_model.Internal.SVC(1).Optim.Bounds(2,2)) )
                % If the kernel param or one of its bounds is NaN,
                % calculate the distance matrix and then affect default value
                % (calculated through the distance matrix) to any of the
                % negative ones
                if N > 500
                    % If training set size is larger than 500 points, take
                    % only a subset of 500 points. For repeatability, we
                    % take the 500 first points of the training set
                    % instead of randomly subsampling.
                    [idx2, idx1] = meshgrid(1:500,1:500);
                    zidx = idx1 > idx2;
                    % Distance matrix
                    D = pdist2(X(1:500,:),X(1:500,:)) ;
                    % Average distance is the mean of components above the
                    % principal diagonal (upper triangular part of D)
                    mean_distance = mean(D(zidx(:))) ;                    
                else
                    [idx2, idx1] = meshgrid(1:N,1:N);
                    zidx = idx1 > idx2;
                    % Distance matrix
                    D = pdist2(X,X) ;
                    % Average distance is the mean of components above the
                    % principal diagonal (upper triangular part of D)
                    mean_distance = mean(D(zidx(:))) ;
                end
                % Default kernel parameter
                if any( isnan( current_model.Internal.SVC(1).Hyperparameters.theta ) )
                    current_model.Internal.SVC(1).Hyperparameters.theta(1:end) = mean_distance;
                end
                % Default upper bound of the kernel parameter
                if any( isnan( current_model.Internal.SVC(1).Optim.Bounds(2,2:end) ) )
                    current_model.Internal.SVC(1).Optim.Bounds(2,2:end) = M*max(D(zidx(:)));
                end
                % Default lower bound of the kernel parameter
                if any( isnan( current_model.Internal.SVC(1).Optim.Bounds(1,2:end) ) )
                    % When there are replicated points, use minimal value
                    % of 1e-3 to avoid having a kernelparam = 0
                    current_model.Internal.SVC(1).Optim.Bounds(1,2:end) = max(1e-3,min(D(zidx(:)))/M);
                end
                % Cycle through each output to affect the same parameters
                for oo = 2 : Nout
                    current_model.Internal.SVC(oo).Hyperparameters.theta = ...
                        current_model.Internal.SVC(1).Hyperparameters.theta;
                    current_model.Internal.SVC(oo).Optim.Bounds(1,2:end) = ...
                        current_model.Internal.SVC(1).Optim.Bounds(1,2:end);
                    current_model.Internal.SVC(oo).Optim.Bounds(2,2:end) = ...
                        current_model.Internal.SVC(1).Optim.Bounds(2,2:end);
                end
                
            end
            
        end
    end
end

%%
% Cycle through the output
for oo = 1 : Nout
    current_model.Internal.Runtime.current_output = oo;
    Y = current_model.ExpDesign.Y(:,oo) ;
    % Set default values of the hyperparameters if not already given by the
    % user
    
    %%
    % Estimate optimal hyperparameters if needed required by the user
    if ~strcmpi(current_model.Internal.SVC(1).Optim.Method,'none')        
        % Optimize the hyperparameters
        [theta,Jstar, ~, ~, ~] = uq_SVC_hyperparameters_optimizer(current_model);
        
        % Retrieve and store the results
        C = theta(1) ;
        sigma = theta(2:end) ;
    else
        
        % No optimization is required: Use the default or given parameters
        C = current_model.Internal.SVC(1).Hyperparameters.C;
        sigma = current_model.Internal.SVC(1).Hyperparameters.theta ;        
    end
    
    %% SOlve the QP problem
    
    % Get optimal alpha (Lagrange multipliers) by solving the dual
    % optimization problem, given the optimal hyperparameters
    current_model.Internal.Runtime.C = C ;
    current_model.Internal.Runtime.Kernel = current_model.Internal.SVC(1).Kernel ;
    current_model.Internal.Runtime.Kernel.Params = sigma ;
    [alpha,exitflag,lambda,K] = uq_SVC_compute_alphas( X, Y, current_model ) ;
    
    % Check if everything went well, otherwise throw an error and exit
    if exitflag < 0
        fprintf('The QP solution did not go well...\n');
        if exitflag == -2 % Unfeasible
            warning('Problem in building the metamodel: The QP problem is unfeasible - Please check the settings');
        elseif exitflag == -3 % Unbounded
            warning('Problem in building the metamodel: The QP problem is unbounded - Please check the settings');
        elseif exitflag == -4  % trust-region-reflective Algorithm
            warning('Problem in building the metamodel: The QP problem is unbounded - Please check the settings');
        elseif exitflag == -6  % interior-point-convex Algorithm
            warning('Problem in building the metamodel: The QP problem is nonconvex - Please provide other hyperparameters values');
        elseif exitflag == -7 % Active-set algorithm
            warning('Problem in building the metamodel: The QP problem is ill-posed pr badly conditionned - Please check the settings');
        elseif exitflag == -10 % Matlab fitcsvm
            warning('No metamodel calculated  - The call to matlab''s fitcsvm to solve the QP problem returned an error - Please check the settings \n');
        end
        
        if exitflag == -10 % For now put a warning for all cases except the one using fitcsvm
            success = 0 ;
            error('The SVC QP problem could not be solved!') ;
            return;
        end
    end
    
    %% Post-processing of the QP
    beta = alpha.*Y ;
    
    %  alpha_cutoff: parameter that will be used to classify the vectors
    alpha_cutoff = current_model.Internal.SVC(1).Alpha_CutOff ;
    %  Set of support vectors
    Isv = find( alpha >= max(alpha) * alpha_cutoff);
    Nsv = length(Isv);
    
    if strcmpi( current_model.Internal.SVC(oo).Penalization , 'linear')
        % Unbounded support vectors: indices and number
        Iusv = find( alpha >= max(alpha) * alpha_cutoff & alpha < C * ( 1 - alpha_cutoff ) ) ;
        
        % Bounded support vectors: indices and number
        Ibsv = find( alpha >= C * ( 1 - alpha_cutoff ) ) ;
    end
    
    % Get the bias
    if isempty(lambda)
        % Meaning we used Matlab solver:
        bias = current_model.Internal.Runtime.bias ;
    else
        bias = lambda.eqlin(1) ;
    end
    
    %% LOO error computation
    if N >= 1000 % Lazy fix for now... Do not attempt to compte the LOO for informative reasons when the ED is of size larger than 1000
        if ~strcmpi(current_model.Internal.SVC(1).Optim.Method,'none')
            if any(strcmpi(current_model.Internal.SVC(1).EstimMethod,{'spanloo', 'smoothloo'}))
                J = (Jstar - Nsv/N)/N  ;
            else
                J = Jstar ;
            end
        else
            J = NaN ;
            warning('The LOO error is not computed because of the large training set (N>1000).');
        end
    else
        % Save these results for use in uq_calc_SpanLOO
        current_model.Internal.Runtime.alpha = alpha ;
        current_model.Internal.Runtime.exitflag = exitflag ;
        current_model.Internal.Runtime.lambda = lambda ;
        current_model.Internal.Runtime.K = K ;
        % Evaluate the Span LOO error
        current_model.Internal.Runtime.EstimMethod = 'SpanLOO' ;
        J = uq_SVC_calc_SpanLOO( current_model ) ;
        
        % Get the actual LOO error (without accounting for the ratio of support
        % vectors
        J = (J - Nsv/N)/N ;
    end
    
    %% Store important results
     % Hyperparameters
    current_model.SVC(oo).Hyperparameters.C = C ;
    current_model.SVC(oo).Hyperparameters.theta = sigma ;
    
    % Coefficients
    current_model.SVC(oo).Coefficients.alpha = alpha ;
    current_model.SVC(oo).Coefficients.beta = beta ;
    current_model.SVC(oo).Coefficients.bias = bias ;
    current_model.SVC(oo).Coefficients.SVidx = Isv ;
    
    if strcmpi( current_model.Internal.SVC(oo).Penalization , 'linear')
        current_model.SVC(oo).Coefficients.USVidx = Iusv ;
        current_model.SVC(oo).Coefficients.BSVidx = Ibsv ;
    end
    
    % Kernel
    current_model.SVC(oo).Kernel = current_model.Internal.SVC(oo).Kernel ;

    % LOO error and normalized LOO errors
    current_model.Error(oo).LOO = J;
    
    % Store the SVC model in case of fitcsvm
    if any( strcmpi(current_model.Internal.SVC(oo).QPSolver,{'smo','isda'}) )
        current_model.Internal.SVC(oo).matlab_svc = current_model.Internal.Runtime.matlab_svc ;
    end
    success = 1 ;
end