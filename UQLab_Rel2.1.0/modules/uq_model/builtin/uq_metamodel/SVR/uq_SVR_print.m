function uq_SVR_print(SVRModel, outArray, varargin)

%% Consistency checks and command line parsing
if ~SVRModel.Internal.Runtime.isCalculated
    fprintf('SVR object %s is not yet calculated!\nGiven Configuration Options:', SVRModel.Name);
    SVRModel.Options
    return;
end
if ~exist('outArray', 'var') || isempty(outArray)
    outArray = 1;
    if length(SVRModel.SVR) > 1
        warning('The selected SVR metamodel has more than 1 output. Only the 1st output will be printed');
        fprintf('You can specify the outputs you want to be displayed with the syntax:\n')
        fprintf('uq_print(SVRModel, OUTARRAY)\nwhere OUTARRAY is the index of desired outputs, e.g. 1:3 for the first three\n\n')
    end
end
if max(outArray) > length(SVRModel.SVR)
    error('Requested output range is too large') ;
end

%% Produce the fixed header
fprintf('\n%%--------------------------- SVR metamodel ---------------------------%%\n');
fprintf('\tObject Name:\t\t%s\n', SVRModel.Name);

%% Produce the default printout

M = SVRModel.Internal.Runtime.M;
fprintf('\tInput Dimension:\t%i\n', M);
fprintf('\n\tExperimental Design\n')
fprintf('\t\tSampling:\t%s\n', SVRModel.ExpDesign.Sampling)
fprintf('\t\tX size:\t\t[%s]\n', [num2str(size(SVRModel.ExpDesign.X,1)),'x',num2str(size(SVRModel.ExpDesign.X,2))])
fprintf('\t\tY size:\t\t[%s]\n', [num2str(size(SVRModel.ExpDesign.Y,1)),'x',num2str(size(SVRModel.ExpDesign.Y,2))])

for ii =  1 : length(outArray)
    % Get desired output
    current_output = outArray(ii);
    if length(outArray) > 1
        fprintf('--- Output #%i:\n', current_output);
    end
    % Loss function
    switch lower(SVRModel.Internal.SVR(current_output).Loss)
        case 'l1-eps'
            fprintf('\n\tLoss function:\t\t%s\n', 'L_1 epsilon-insensitive');
        case 'l2-eps'
            fprintf('\n\tLoss function:\t\t%s\n', 'L_2 epsilon-insensitive');
        otherwise
            fprintf('\tLoss function:\t\t%s\n', ...
                SVRModel.Internal.SVR(current_output).Loss) ;
    end
    % QP Solver
    switch lower(SVRModel.Internal.SVR(current_output).QPSolver)
        case 'ip'
            fprintf('\tQP Solver:\t\t\t%s\n', 'Quadprog''s IP');
        case 'smo'
            fprintf('\tQP Solver:\t\t\t%s\n', 'Sequential Minimal Opitmizatin (SMO)');
        case 'isda'
            fprintf('\tQP Solver:\t\t\t%s\n', 'Iterative Single Data Algorithm (ISDA) ');
        otherwise
            fprintf('\tLoss function:\t\t\t%s\n', ...
                SVRModel.Internal.SVR(current_output).QPSolver) ;
    end
    
    % Kernel   
    if ~strcmpi(func2str(SVRModel.Internal.SVR(current_output).Kernel.Handle),'uq_eval_kernel')
        % User-defined kernel handle
        fprintf('\tKernel:\t\t\t\t%s\t(user-defined)\n', strcat('@',func2str(SVRModel.Internal.SVR(current_output).Kernel.Handle)) );
    else
        if isfield(SVRModel.Internal.SVR(current_output).Kernel,'Family')
            if strcmpi(class(SVRModel.Internal.SVR(current_output).Kernel.Family),'function_handle')
                fprintf('\tKernel:\t\t\t\t%s\n', strcat('@',func2str(SVRModel.Internal.SVR(current_output).Kernel.Family)) );
            else
                fprintf('\tKernel:\t\t\t\t%s\n', SVRModel.Internal.SVR(current_output).Kernel.Family );
            end
        end
    end
    % Hyperparameters
    fprintf('\n\tHyperparameters\n')
    fprintf('\t\tC:\t\t\t\t\t\t%e\n', SVRModel.SVR(current_output).Hyperparameters.C);
    fprintf('\t\tepsilon:\t\t\t\t%e\n', SVRModel.SVR(current_output).Hyperparameters.epsilon)
    if isempty(SVRModel.SVR(current_output).Hyperparameters.theta)
        fprintf('\t\tkernel params:\t\t\t[ ]\n')
    else
        fprintf('\t\tkernel params:\t\t\t%e\n', SVRModel.SVR(current_output).Hyperparameters.theta(1))
        if isfield(SVRModel.Internal.SVR(current_output).Kernel,'Family') ...
                && strcmpi(SVRModel.Internal.SVR(current_output).Kernel.Family, 'polynomial')
            % If the kernel is polynomial add something to specify it
            fprintf('\t\t              \t\t\t%u\t\t\t (degree)\n', SVRModel.SVR(current_output).Hyperparameters.theta(2));

        else
            if length(SVRModel.SVR(current_output).Hyperparameters.theta) > 1
                for jj = 2: length(SVRModel.SVR(current_output).Hyperparameters.theta)
                    fprintf('\t\t              \t\t\t%e\n', SVRModel.SVR(current_output).Hyperparameters.theta(jj));
                end
            end
        end
    end
    % Error estimation method
    switch lower(SVRModel.Internal.SVR(current_output).EstimMethod)
        case 'cv'
            fprintf('\t\tEstimation method:\t\t%s\n', 'Cross-validation' )
        case 'spanloo'
            fprintf('\t\tEstimation method:\t\t%s\n', 'Leave-one-out span estimate' )
        case 'smoothloo'
            fprintf('\t\tEstimation method:\t\t%s\n', 'Leave-one-out smoothed span estimate' )
        otherwise
            fprintf('\tEstimation method:\t\t%s\n', ...
                SVRModel.Internal.SVR(current_output).EstimMethod) ;
    end
    % Optimization algorithm
    switch lower(SVRModel.Internal.SVR(current_output).Optim.Method)
        case 'hga'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'Hybrid Genetic Algorithm' )
        case 'ga'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'Genetic Algorithm' )
        case 'bfgs'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'BFGS' )
        case 'ce'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'Cross-entropy optimization' )
        case 'hce'
            fprintf('\t\tOptim. method:\t\t\t\t%s\n', 'Hybrid cross-entropy optimization' )
        case 'cmaes'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'CMA-ES' )
        case 'hcmaes'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'Hybrid CMA-ES' )
        case 'gs'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'Grid search' )
        case 'hgs'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'Hybrid grid search' )
            
        case 'none'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'None: User-defined or default parameters are used' )
        otherwise
            fprintf('\t\tOptim. method:\t\t\t%s\n', ...
                SVRModel.Internal.SVR(current_output).Optim.Method) ;
    end
    % Support vectors
    if strcmpi(SVRModel.Internal.SVR(current_output).Loss,'l2-eps')
        fprintf('\n\tNumber of SVs (USV,BSV):\t\t\t%u \t(--,--)', ...
            length(SVRModel.SVR(current_output).Coefficients.SVidx));
    else
        fprintf('\n\tNumber of SVs (USV,BSV):\t\t\t%u \t(%u,%u)', ...
            length(SVRModel.SVR(current_output).Coefficients.SVidx),...
            length(SVRModel.SVR(current_output).Coefficients.USVidx),...
            length(SVRModel.SVR(current_output).Coefficients.BSVidx));
    end
    fprintf('\n\tLeave-one-out error (normalized):\t%13.7e\n', ...
        SVRModel.Error(current_output).LOO_norm);
    if isfield(SVRModel.Error,'Val')
        fprintf('\tValidation error:\t\t\t%13.7e\n\n', ...
            SVRModel.Error(outArray(ii)).Val);
    end

end

fprintf('%%---------------------------------------------------------------------%%\n');

end