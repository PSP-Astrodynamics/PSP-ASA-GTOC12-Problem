function success = uq_SVR_calculate_coefficients( module )
% UQ_SVR_CALCULATE_COEFFICIENTS(CURRENT_MODEL): calculate
% the SVR metamodel using options specified in CURRENT_MODEL
%
% See also: UQ_SVR_OPTIMIZER, UQ_EVAL_KERNEL, ...

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
    fprintf('\n---   Calculating the SVR metamodel...                              ---\n')
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

%% 
% Scale the ouput if the user sets output scaling on
if current_model.Internal.SVR(1).OutputScaling == 1
    for oo = 1 : Nout
        current_model.Internal.Runtime.muY(:,oo) = mean( current_model.ExpDesign.Y(:,oo) );
        current_model.Internal.Runtime.stdY(:,oo) = std( current_model.ExpDesign.Y(:,oo) );
        current_model.ExpDesign.Yu(:,oo) =  ...
            ( current_model.ExpDesign.Y(:,oo) - current_model.Internal.Runtime.muY(:,oo) ) / current_model.Internal.Runtime.stdY(:,oo) ;
    end        
else
    current_model.ExpDesign.Yu = current_model.ExpDesign.Y ;
end
%%
% IMPORTANT: Now that we got the number of points - Set the default to Loss
% to l1-eps and default QPSolver to SMO ... IF the user did not give any
if N > 300 && exist('fitrsvm', 'file')
  
 if current_model.Internal.Runtime.UserGivenQPSolver
     if strcmpi(current_model.Internal.SVR(1).QPSolver,'ip')
        warning('The ED size is larger than 300. The selected QP solver may be slow. Please consider using SMO or ISDA.')
     end
 else
    if ~any( strcmpi(current_model.Internal.SVR(1).QPSolver, {'smo', 'isda'}) )
        current_model.Internal.SVR(1).QPSolver = 'smo' ;
        warning('The ED size is larger than 300. The default QP solver has been reverted to SMO.')
    end
    if strcmpi(current_model.Internal.SVR(1).Loss, 'l2-eps')
        current_model.Internal.SVR(1).Loss = 'l1-eps' ;
        if current_model.Internal.Runtime.UserGivenLoss
            warning('The penalization scheme of the QP problem has been reverted to ''l1-eps'' because SMO is used.' ) ;
        end
    end
 end
elseif N > 300 && ~exist('fitrsvm', 'file')
    fprintf('Currently using the %s algorithm to solve the QP problem \n', current_model.Internal.SVR(1).QPSolver) ;
    warning('For training sets larger than 300, IP is extremely slow. Consider reducing the training set or using SMO (available in Matlab versions older than 2015a)') ;
end

%%
% Copy the necessary information about the SVR options to the various
% output coordinates
for oo = 2 : Nout
    current_model.Internal.SVR(oo) =  current_model.Internal.SVR(1);
end

%% ----  SVR entry point
% Get in input traiing points (U = X in the reduced space)
X = current_model.ExpDesign.U ;
% Dimension of the problem
M = size(X,2) ;
current_model.Internal.Runtime.M = M ;
% Remove the constants, if any
nonConst = current_model.Internal.Runtime.nonConstIdx ;
X = X(:,nonConst);


% Set the default kernel parameters for those depending on the experimental
% design \ie the radial basis functions type kernels
% NaN values mean that UQLab's default values should be computed
if ~strcmpi(func2str(current_model.Internal.SVR(1).Kernel.Handle),'uq_eval_kernel')
    % Do noting, assume that all parameters have been initialized in
    % uq_SVR_initialize
else
    % No parameters for the non-stationary linear kernel function
    if strcmpi(current_model.Internal.SVR(1).Kernel.Family,'linear_ns')
        for oo = 1:Nout
            current_model.Internal.SVR(oo).Hyperparameters.theta = [] ;
        end
    else
        
        if current_model.Internal.Runtime.isStationary
            if ( any(isnan(current_model.Internal.SVR(1).Hyperparameters.theta)) ...
                    || isnan(current_model.Internal.SVR(1).Optim.Bounds(1,3)) ...
                    || isnan(current_model.Internal.SVR(1).Optim.Bounds(2,3)) )
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
                if any( isnan( current_model.Internal.SVR(1).Hyperparameters.theta ) )
                    current_model.Internal.SVR(1).Hyperparameters.theta(1:end) = mean_distance;
                end
                % Default upper bound of the kernel parameter
                if any( isnan( current_model.Internal.SVR(1).Optim.Bounds(2,3:end) ) )
                    current_model.Internal.SVR(1).Optim.Bounds(2,3:end) = M*max(D(zidx(:)));
                end
                % Default lower bound of the kernel parameter
                if any( isnan( current_model.Internal.SVR(1).Optim.Bounds(1,3:end) ) )
                    % When there are replicated points, use minimal value
                    % of 1e-3 to avoid having a kernelparam = 0
                    current_model.Internal.SVR(1).Optim.Bounds(1,3:end) = max(1e-3,min(D(zidx(:)))/M);
                end
                % Cycle through each output to affect the same parameters
                for oo = 2 : Nout
                    current_model.Internal.SVR(oo).Hyperparameters.theta = ...
                        current_model.Internal.SVR(1).Hyperparameters.theta;
                    current_model.Internal.SVR(oo).Optim.Bounds(1,3:end) = ...
                        current_model.Internal.SVR(1).Optim.Bounds(1,3:end);
                    current_model.Internal.SVR(oo).Optim.Bounds(2,3:end) = ...
                        current_model.Internal.SVR(1).Optim.Bounds(2,3:end);
                end
                
            end
            
        end
    end
end

%%
% Cycle through each output
for oo = 1 : Nout
    current_model.Internal.Runtime.current_output = oo;
    % Get the current output in the scaled space (scale space = original
    % space if output scaling is disabled)
    Y = current_model.ExpDesign.Yu(:,oo) ;
    
    % Set default values of the hyperparameters if not already given by the
    % user
        % C depends on the DOE output mean and std
        % NaN values mean default values should be set
    if isnan( current_model.Internal.SVR(oo).Hyperparameters.C )
        temp_m = mean(Y);
        temp_s = std(Y);
        C = max(abs(temp_m + 3* temp_s), abs(temp_m - 3* temp_s));
        current_model.Internal.SVR(oo).Hyperparameters.C = C;
    end
    
    % Default lower and upper values of C on the DOE output, Y
    if isfield(current_model.Internal.SVR(oo).Optim,'Bounds')
        if isnan( current_model.Internal.SVR(oo).Optim.Bounds(1,1) ) %Lower bound
            current_model.Internal.SVR(oo).Optim.Bounds(1,1) = ...
                current_model.Internal.SVR(oo).Hyperparameters.C/10;
        end
         if isnan( current_model.Internal.SVR(oo).Optim.Bounds(2,1) ) % Upper bound
             if N >= 300
             current_model.Internal.SVR(oo).Optim.Bounds(2,1) = ...
                100*current_model.Internal.SVR(oo).Hyperparameters.C;                
             else
            current_model.Internal.SVR(oo).Optim.Bounds(2,1) = ...
                1e5*current_model.Internal.SVR(oo).Hyperparameters.C;
             end
        end       
    end
    
    % Default epsilon depends on the DOE output, Y
    if isnan( current_model.Internal.SVR(oo).Hyperparameters.epsilon )
        epsilon = iqr(Y)/13.49 ;
        current_model.Internal.SVR(oo).Hyperparameters.epsilon = epsilon;
    else
        epsilon = current_model.Internal.SVR(oo).Hyperparameters.epsilon ;
    end
    
    % Default Lower and Upper bound of epsilon depends on Y.
    if isfield(current_model.Internal.SVR(oo).Optim,'Bounds')
        if isnan( current_model.Internal.SVR(oo).Optim.Bounds(2,2) ) % Upper bound on epsilon
            current_model.Internal.SVR(oo).Optim.Bounds(2,2) = epsilon * 10;
        end
        if isnan( current_model.Internal.SVR(oo).Optim.Bounds(1,2) ) % Lower bound
            if N >= 300
                current_model.Internal.SVR(oo).Optim.Bounds(1,2) = epsilon/100;
            else
                current_model.Internal.SVR(oo).Optim.Bounds(1,2) = epsilon/1000;
            end
        end
    end
    
    %%
    % Estimate optimal hyperparameters if required by the user
    if ~strcmpi(current_model.Internal.SVR(1).Optim.Method,'none')
                
        % Optimize of the hyperparameters
        [theta,Jstar, ~, ~, ~] = uq_SVR_hyperparameters_optimizer(current_model);
        
        % Retrieve and store the results
        C = theta(1) ;
        epsilon = theta(2) ;
        sigma = theta(3:end) ;
        
    else
        
        % No optimization is required: Use the default or given parameters
        C = current_model.Internal.SVR(oo).Hyperparameters.C;
        sigma = current_model.Internal.SVR(oo).Hyperparameters.theta ;
        
    end
    
    %% Solve QP problem
    
    % Get optimal alpha (Lagrange multipliers) by solving the dual
    % optimization problem
    current_model.Internal.Runtime.C = C ;
    current_model.Internal.Runtime.epsilon = epsilon ;
    current_model.Internal.Runtime.Kernel = current_model.Internal.SVR(1).Kernel ;
    current_model.Internal.Runtime.Kernel.Params = sigma ;
    [alpha,exitflag,lambda,K] = uq_SVR_compute_alphas( X, Y, current_model ) ;
    
    % Check if everything went well, otherwise throw a warning or an error and exit
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
    
    %% Post-process results of QP
    % Post_processing of the SVR model
    a_star = alpha(1:N,:);
    a = alpha(N+1 : 2*N,:);
    a_coef = max(a,a_star);
    beta = a_star - a;
    %  alpha_cutoff: parameter that will be used to classify the vectors
    alpha_cutoff = current_model.Internal.SVR(1).Alpha_CutOff;
    % Set of support vectors
    Isv = find(abs(a_coef)>= max(a_coef) * alpha_cutoff) ;
    % Number of support vectors
    Nsv = length(Isv);
    
    if strcmpi( current_model.Internal.SVR(oo).Loss , 'l1-eps')
        % Unbounded support vectors: indices and number
        Iusv = find(a_coef >= max(a_coef) * alpha_cutoff & a_coef < C * ( 1 - alpha_cutoff ) );
        Nusv = length(Iusv);
        
        % Bounded support vectors: indices and number
        Ibsv = find( a_coef >= C * ( 1 - alpha_cutoff ) );
        Nbsv = length(Ibsv);
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
        if ~strcmpi(current_model.Internal.SVR(1).Optim.Method,'none')
            J = Jstar ;
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
        J = uq_SVR_calc_SpanLOO( current_model ) ;
    end
 
    %% Store important results
    % Hyperparameters
    current_model.SVR(oo).Hyperparameters.C = C ;
    current_model.SVR(oo).Hyperparameters.epsilon = epsilon ;
    current_model.SVR(oo).Hyperparameters.theta = sigma ;
    
    % Coefficients
    current_model.SVR(oo).Coefficients.alpha = alpha ;
    current_model.SVR(oo).Coefficients.beta = beta ;
        current_model.SVR(oo).Coefficients.bias = bias ;

    current_model.SVR(oo).Coefficients.SVidx = Isv ;
    
    if strcmpi( current_model.Internal.SVR(oo).Loss , 'l1-eps')
        current_model.SVR(oo).Coefficients.USVidx = Iusv ;
        current_model.SVR(oo).Coefficients.BSVidx = Ibsv ;
    end
    % Kernel
    current_model.SVR(oo).Kernel = current_model.Internal.SVR.Kernel ;
    % LOO error and normalized LOO errors
    current_model.Error(oo).LOO = J;
    current_model.Error(oo).LOO_norm = J/var(Y) ;
    
    % Store the SVC model in case of fitcsvm
    if any( strcmpi(current_model.Internal.SVR(oo).QPSolver,{'smo','isda'}) )
        current_model.Internal.SVR(oo).matlab_svr = current_model.Internal.Runtime.matlab_svr ;
    end

end
success = 1 ;
end