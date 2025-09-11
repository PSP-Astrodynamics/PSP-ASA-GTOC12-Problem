function uq_SVC_print(SVCModel, outArray, varargin)

%% Consistency checks and command line parsing
% Check that the model has been computed with success
if ~SVCModel.Internal.Runtime.isCalculated
    fprintf('SVC object %s is not yet calculated!\nGiven Configuration Options:', SVCModel.Name);
    SVCModel.Options
    return;
end

if ~exist('outArray', 'var') || isempty(outArray)
    outArray = 1;
    if length(SVCModel.SVC) > 1
        warning('The selected SVC metamodel has more than 1 output. Only the 1st output will be printed');
        fprintf('You can specify the outputs you want to be displayed with the syntax:\n')
        fprintf('uq_print(SVCModel, OUTARRAY)\nwhere OUTARRAY is the index of desired outputs, e.g. 1:3 for the first three\n\n')
    end
end
if max(outArray) > length(SVCModel.SVC)
    error('Requested output range is too large') ;
end

%% Produce the fixed header
fprintf('\n%%-------------------------- SVC metamodel --------------------------%%\n');
fprintf('\tObject Name:\t\t%s\n', SVCModel.Name);

%% Produce the default printout

M = SVCModel.Internal.Runtime.M;
fprintf('\tInput Dimension:\t%i\n', M);
fprintf('\n\tExperimental Design\n')
fprintf('\t\tSampling:\t%s\n', SVCModel.ExpDesign.Sampling)
fprintf('\t\tX size:\t\t[%s]\n', [num2str(size(SVCModel.ExpDesign.X,1)),'x',num2str(size(SVCModel.ExpDesign.X,2))])
fprintf('\t\tY size:\t\t[%s]\n', [num2str(size(SVCModel.ExpDesign.Y,1)),'x',num2str(size(SVCModel.ExpDesign.Y,2))])

for ii =  1 : length(outArray)
    % Get desired output
    current_output = outArray(ii);
    if length(outArray) > 1
        fprintf('--- Output #%i:\n', current_output);
    end
    % Loss function
    switch lower(SVCModel.Internal.SVC(current_output).Penalization)
        case 'linear'
            fprintf('\n\tLoss function:\t\t%s\n', 'Linear');
        case 'quadratic'
            fprintf('\n\tLoss function:\t\t%s\n', 'quadratic');
        otherwise
            fprintf('\tLoss function:\t\t%s\n', ...
                SVCModel.Internal.SVC(current_output).Penalization) ;
    end
    
        % QP Solver
    switch lower(SVCModel.Internal.SVC(current_output).QPSolver)
        case 'ip'
            fprintf('\tQP Solver:\t\t\t%s\n', 'Quadprog''s IP');
        case 'smo'
            fprintf('\tQP Solver:\t\t\t%s\n', 'Sequential Minimal Opitmizatin (SMO)');
        case 'isda'
            fprintf('\tQP Solver:\t\t\t%s\n', 'Iterative Single Data Algorithm (ISDA) ');
        otherwise
            fprintf('\tQP Solver:\t\t\t%s\n', ...
                SVCModel.Internal.SV(current_output).QPSolver) ;
    end
        
    % Kernel
    if ~strcmpi(func2str(SVCModel.Internal.SVC(current_output).Kernel.Handle),'uq_eval_Kernel')
        % User-defined kernel handle
        fprintf('\tKernel:\t\t\t\t%s (user-defined)\n', strcat('@',func2str(SVCModel.Internal.SVC(current_output).Kernel.Handle)) );
    else
        if isfield(SVCModel.Internal.SVC(current_output).Kernel,'Family')
            if strcmpi(class(SVCModel.Internal.SVC(current_output).Kernel.Family),'function_handle')
                fprintf('\tKernel:\t\t\t\t%s\n', strcat('@',func2str(SVCModel.Internal.SVC(current_output).Kernel.Family)) );
            else
                fprintf('\tKernel:\t\t\t\t%s\n', SVCModel.Internal.SVC(current_output).Kernel.Family );
            end
        end
    end
    % Hyperparameters
    fprintf('\n\tHyperparameters\n')
    fprintf('\t\tC:\t\t\t\t\t\t%f\n', SVCModel.SVC(current_output).Hyperparameters.C); 
    if isempty(SVCModel.SVC(current_output).Hyperparameters.theta)
        fprintf('\t\tkernel params:\t\t\t[ ]\n')
    else
        fprintf('\t\tkernel params:\t\t\t%e\n', SVCModel.SVC(current_output).Hyperparameters.theta(1))
        if length(SVCModel.SVC(current_output).Hyperparameters.theta) > 1
            for jj = 2: length(SVCModel.SVC(current_output).Hyperparameters.theta)
                fprintf('\t\t              \t\t\t%e\n', SVCModel.SVC(current_output).Hyperparameters.theta(jj));
            end
        end
    end
    % Error estimation method
    switch lower(SVCModel.Internal.SVC(current_output).EstimMethod)
        case 'cv'
            fprintf('\t\tEstimation method:\t\t%s\n', 'Cross-validation' )
        case 'spanloo'
            fprintf('\t\tEstimation method:\t\t%s\n', 'Leave-one-out span estimate' )
        case 'smoothloo'
            fprintf('\t\tEstimation method:\t\t%s\n', 'Leave-one-out smoothed span estimate' )
        otherwise
            fprintf('\tEstimation method:\t\t%s\n', ...
                SVCModel.Internal.SVC(current_output).EstimMethod) ;
    end
    % Optimization method
    switch lower(SVCModel.Internal.SVC(current_output).Optim.Method)
        case 'ce'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'Cross-entropy optimization' )
        case 'cmaes'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'CMA-ES' )
        case 'gs'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'Grid search' )
        case 'none'
            fprintf('\t\tOptim. method:\t\t\t%s\n', 'None: User-defined or default parameters are used' )
        otherwise
            fprintf('\t\tOptim. method:\t\t\t%s\n', ...
                SVCModel.Internal.SVC(current_output).Optim.Method) ;
    end
    % Support vectors
    if strcmp(SVCModel.Internal.SVC(current_output).Penalization,'quadratic')
    fprintf('\n\tNumber of SVs (USV,BSV):\t%u \t(--,--)', ...
        length(SVCModel.SVC(current_output).Coefficients.SVidx));
    else
    fprintf('\n\tNumber of SVs (USV,BSV):\t%u \t(%u,%u)', ...
        length(SVCModel.SVC(current_output).Coefficients.SVidx),...
        length(SVCModel.SVC(current_output).Coefficients.USVidx),...
        length(SVCModel.SVC(current_output).Coefficients.BSVidx));       
    end   
    fprintf('\n\tLeave-one-out error:\t\t%f\n', ...
        SVCModel.Error(current_output).LOO);
    if isfield(SVCModel.Error,'Val')
        fprintf('\tValidation error:\t\t\t%f\n\n', ...
            SVCModel.Error(outArray(ii)).Val);
    end

    
end

fprintf('%%---------------------------------------------------------------------%%\n');

end