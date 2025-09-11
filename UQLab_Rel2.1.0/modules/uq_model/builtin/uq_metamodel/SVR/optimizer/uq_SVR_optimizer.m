function [alpha,exitflag,lambda,K] = uq_SVR_optimizer( X, Y, current_model )
% UQ_SVR_OPTIMIZER solves the QPC problem to find the support vectors
% INPUT
%   - X: Experimental design - input
%   - Y: Experimental design - output
%   - current_model: Options of the metamodel
% OUTPUT
%   - alphas: support vector coefficients
%   - exitflag: exit flag of the qpc solver
%   - lambda: Lagrange multipliers
%   - K: Kernel matrix

% Obtain the current output and options of the metamodel
current_output = current_model.Internal.Runtime.current_output ;
C = current_model.SVR(current_output).C ;
epsilon = current_model.SVR(current_output).epsilon ;
KerOptions = current_model.SVR(current_output).Kernel ;
theta = KerOptions.Params ;

% Transpose the data
X = X.';
Y = Y.';
N = length(Y);

% Set up the quadratic optimization problem
switch lower(current_model.Internal.SVR(1).Loss)
    case 'l1-eps'
        
    % Equality constraints
    Aeq = [ones(1,N), -ones(1,N)] ;
    beq = 0 ;
    
    % Bounds
    lb = zeros(2*N,1);
    ub = C * ones(2*N,1) ;
    
    % Calculate the matrices of the quadratic objective function
    % Calculate K
    evalK_handle = current_model.Internal.SVR(current_output).Kernel.Handle ;
    K = evalK_handle( X, X, theta, KerOptions);
    H = [K -K; -K K];
    H = (H+H')/2 ;
    e = ones(1,N);
    f = [epsilon * e - Y, epsilon * e + Y];
    
    case 'l2-eps'
        
    % Equality constraints
    Aeq = [ones(1,N), -ones(1,N)] ;
    beq = 0 ;
    
    % Bounds
    lb = zeros(2*N,1);
    ub = Inf * ones(2*N,1) ;
    
    % Calculate the matrices of the quadratic objective function
    % Calculate K
    evalK_handle = current_model.Internal.SVR(current_output).Kernel.Handle ;
    K = evalK_handle( X, X, theta, KerOptions);
    vectorC = (1./C)*ones(N,1);
    K = K + diag(vectorC);
    H = [K -K; -K K];

    e = ones(1,N);
    f = [epsilon * e - Y, epsilon * e + Y];
end  
    current_model.Internal.H = H;
    current_model.Internal.f = f;
    current_model.Internal.Aeq = Aeq;
    current_model.Internal.beq = beq;
    
% Solve the optimization problem using different methods
switch lower (current_model.Internal.SVR(1).QPSolver)
    case 'ip'
    options = optimoptions('quadprog','Algorithm','interior-point-convex','Display','none','TolX',1e-15,'TolCon',1e-15);

    % Run the optimization
    [alpha,~,exitflag,~,lambda]= quadprog(H,f',...
        [],[],...
        Aeq,beq,...
        lb,ub, [],options);
    
    case 'as'
    options = optimoptions('quadprog','Algorithm','active-set','Display','none','TolX',1e-15,'TolCon',1e-15);
    
    % Run the optimization
    [alpha,~,exitflag,~,lambda]= quadprog(H,f',...
        [],[],...
        Aeq,beq,...
        lb,ub, [],options);
    case 'smo'
        error('\n SMO Optimization method is not yet implemented! \n')

    otherwise
        error('\n Unknown Optimization method \n')
end