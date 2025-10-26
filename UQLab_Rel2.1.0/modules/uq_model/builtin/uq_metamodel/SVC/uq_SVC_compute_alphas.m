function [alpha,exitflag,lambda,K] = uq_SVC_compute_alphas( X, Y, current_model )
%UQ_SVC_COMPUTE_alpha computes the SVC expansion coefficients (alpha)
% given a training set, a kernel function and a set of hyperparameters :
% This function uses a solver Matlab's quadprog (which requires the
% optimization toolbox license) or Matlab SVC solver (SMO, ISDA)


% Obtain the current output
current_output = current_model.Internal.Runtime.current_output ;
% Retrieve the hyperparameters
C = current_model.Internal.Runtime.C ;
KernelOptions = current_model.Internal.Runtime.Kernel ;
evalK_handle = KernelOptions.Handle ;
theta = KernelOptions.Params ;
% Training set size
N = length(Y) ;
if any(strcmpi(current_model.Internal.SVC(current_output).QPSolver, {'smo','isda'}))
    % Solve the QP problem using Matlab's built-in function
    try
        global matlab_theta matlab_kernelOpts
        matlab_theta = theta ;
        matlab_kernelOpts = KernelOptions ;
        switch lower(current_model.Internal.SVC(current_output).QPSolver)
            case 'smo'
                matlab_svc = fitcsvm(X,Y,'BoxConstraint',C,'Kernelfunction','uq_matlab_kernel_wrapper', 'Solver', 'SMO') ;
            case 'isda'
                matlab_svc = fitcsvm(X,Y,'BoxConstraint',C,'Kernelfunction','uq_matlab_kernel_wrapper', 'Solver', 'ISDA') ;
            case 'l1qp' % Linear penalization QP solver - won't be documented as we are doing it directly in UQLab with Quadprog - Only for testing
                matlab_svc = fitcsvm(X,Y,'BoxConstraint',C,'Kernelfunction','uq_matlab_kernel_wrapper', 'Solver', 'L1QP') ;
        end
        
        exitflag = 1 ;
        % Retrieve coefficients
        alpha = zeros(N,1) ;
        alpha(matlab_svc.IsSupportVector,:) = matlab_svc.Alpha ;
        bias = matlab_svc.Bias ;
        lambda = [] ;
        K = [] ;
        current_model.Internal.Runtime.matlab_svc  = matlab_svc ; % Check that this is save donly when necessary i.e. not during optimization
    catch
        alpha = [] ;
        exitflag = -10 ;
        lambda = [] ;
        K = [] ;
    end
    
    current_model.Internal.Runtime.bias = bias ;
else
    %<TRANSPOSE>
    X = X.';
    Y = Y.';    
    %% Set up the quadratic optimization problem
    switch lower(current_model.Internal.SVC(current_output).Penalization)
        case 'linear'
            % Setting up the following quadratic optimization problem:
            % 1/2 [alpha]^T [H] [alpha] + [f] [alpha]
            % s.t. [Aeq] [alpha] = [beq] and 0 <= alpha, alpha* <= C
            % where [alpha] = [alpha alpha*] ;
            
            % Equality constraints
            Aeq = Y ;
            beq = 0 ;
            % Bounds
            lb = zeros(N,1);
            ub = C * ones(N,1) ;
            % Matrices of the quadratic objective function: K and H
            % Calculate K
            K = evalK_handle( X', X', theta, KernelOptions);
            H = K .* (Y'*Y);
            H = (H+H')/2; % Make H perfectly symmetric
            
            % Second term of the equation
            f = -ones(N,1);
            
        case 'quadratic'
            % Setting up the following quadratic optimization problem:
            % 1/2 [alpha]^T [H] [alpha] + [f] [alpha]
            % s.t. [Aeq] [alpha] = [beq] and alpha,alpha* >= 0
            % where [alpha] = [alpha alpha*] ;
            
            
            % Equality constraints
            Aeq = Y ;
            beq = 0 ;
            % Bounds
            lb = zeros(N,1);
            ub = Inf * ones(N,1) ;
            % Calculate the matrices of the quadratic objective function
            % Calculate K
            K = evalK_handle( X', X', theta, KernelOptions);
            H = K .* (Y'*Y);
            H = (H+H')/2; % Make H perfectly symmetric
            % Add 1/C on the diagonal of K to obtain Ktilde
            vectorC = 1/C * ones(N,1);
            H = H + diag(vectorC);
            
            % Second term of the equation
            f = -ones(N,1);
            
    end
    
    %% Solve the optimization problem
    
    switch lower (current_model.Internal.SVC(1).QPSolver)
        case 'ip'  % Using IP from Matlab
            
            options = optimoptions('quadprog','Algorithm','interior-point-convex','Display','none');
            
            % Run the optimization using matlab's built-in QP solver
            [alpha,~,exitflag,~,lambda]= quadprog(H,f,[],[],Aeq,beq,lb,ub,[],options);
            
        case 'qpc' % Using Quadratic programming in C++, an external library whose .mex files are available
            [alpha,err,lambda] = qpip(H,f,[],[],Aeq,beq,lb,ub,0,[],0);
            % Convert the error flag into an exitflag compatible with that of
            % Matlab's quadprog
            if err == 0 && ~isempty(alpha)% x* is optimal
                exitflag = 1;
            else % Optimization somehow failed
                exitflag = 0;
            end
            % Set the lambda (Lagrange coefficients) into a structure similar
            % to those given by Matlab's quadprog
            lambda.upper = lambda.upperbound ;
            lambda.eqlin = lambda.equality ;
        otherwise
            error('Unknown Optimization method \n') ;
    end
end

end