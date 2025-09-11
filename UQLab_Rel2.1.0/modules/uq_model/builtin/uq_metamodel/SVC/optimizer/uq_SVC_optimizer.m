function [alphas,exitflag,lambda,K] = uq_SVC_optimizer( X, Y, current_model )
% UQ_SVC_OPTIMIZER solves the QPC problem to find the support vectors
% INPUT
%   - X: Experimental design - input
%   - Y: Experimental design - output
%   - current_model: Options of the metamodel
% OUTPUT
%   - alphas: support vector coefficients
%   - exitflag: exit flag of the qpc solver
%   - lambda: Lagrange multipliers
%   - K: Kernel matrix

% Obtain the current output
current_output = current_model.Internal.Runtime.current_output ;
% N = size(current_model.ExpDesign.Y, 1);
C = current_model.SVC(current_output).C ;

% Transpose the data
X = X.';
Y = Y.';
N = length(Y);

% Set up the quadratic optimization problem
switch lower(current_model.Internal.SVC(current_output).Penalization)
    case 'linear'
        
        % Equality constraints
        Aeq = Y ;
        beq = 0 ;
        
        % Bounds
        lb = zeros(N,1);
        ub = C * ones(N,1) ;
        
        % Calculate the matrices of the quadratic objective function
        theta = current_model.SVC(current_output).Kernel.Params;
        K_Family = current_model.SVC(current_output).Kernel.Family;
        K = uq_SVC_eval_K( X, X, theta, K_Family);
        H = K .* (Y'*Y);
        if norm(H-H',inf) > eps    % Make H perfectly symmetric if necessary
            norm(H-H',inf);
            H = (H+H')/2;
        end
        
        f = -ones(N,1) ;
        
    case 'quadratic'
        
        % Equality constraints
        Aeq = Y ;
        beq = 0 ;
        
        % Bounds
        lb = zeros(N,1);
        ub = Inf * ones(N,1) ;
        vectorC = 1/C * ones(N,1);
        
        % Calculate the matrices of the quadratic objective function
        theta = current_model.SVC(current_output).Kernel.Params;
        K_Family = current_model.SVC(current_output).Kernel.Family;
        K = uq_SVC_eval_K( X, X, theta, K_Family);
        H = K .* (Y'*Y);
        if norm(H-H',inf) > eps % Make H perfectly symmetric if necessary
            norm(H-H',inf);
            H = (H+H')/2;
        end
        H = H + diag(vectorC);
        
        f = -ones(N,1);
        
end
% Save the results and intermediate data
current_model.Internal.H = H;
current_model.Internal.f = f;
current_model.Internal.Aeq = Aeq;
current_model.Internal.beq = beq;

% Specify the options for different solvers
switch lower (current_model.Internal.SVC(1).QPSolver)
    case 'ip'
        options = optimoptions('quadprog','Algorithm','interior-point-convex','Display','none','TolX',1e-15,'TolCon',1e-15);
    case 'as'
        options = optimoptions('quadprog','Algorithm','active-set','Display','none','TolX',1e-15,'TolCon',1e-15);
    case 'smo'
        error('SMO Optimization method is not yet implemented \n')
    otherwise
        error('Unknown Optimization method \n')
end

% Solve the optimization problem
[alphas,~,exitflag,~,lambda]= quadprog(H,f,[],[],Aeq,beq,lb,ub,[],options);

end