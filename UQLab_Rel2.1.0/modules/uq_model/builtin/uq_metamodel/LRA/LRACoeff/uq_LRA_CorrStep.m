function Results = uq_LRA_CorrStep(P, res, StopParam, Method)
% RESULTS = UQ_LRA_CORRSTEP(P,RES,STOPPARAM,METHOD)
% This function performs a correction step using the specified parameters 
% in the stopping criterion and method

% Get information from function input
varY = StopParam.varY;
stop_Derr = StopParam.stop_Derr;
stop_iterNo = StopParam.stop_iterNo;
M = length(P);
p = size(P{1},2)-1;
N = size(P{1},1);

% Initialize variables
u_all = ones(N,M);   
z_l = zeros(p+1,M);

% Initialize parameters of the stopping criterion
Derr = 1; 
iter = 1;
errE_iter(1) = (sum((res-1).^2)/N)/varY;

while Derr >= stop_Derr && iter <= stop_iterNo
    iter = iter+1;
    
    % Begin an iteration over the set of dimensions
    for j=1:M
        % Evaluate "frozen" component
        u_froz = ones(N,1);
        for i = 1:M
            if i ~= j
                u_froz = u_froz.*u_all(:,i);
            end
        end

        % Create information matrix
        A_mat = bsxfun(@times,u_froz,P{j});

        if all(u_froz == 0)
            warning('The regressors for dimension %i are zero. This correction step is ignored.',j);
            z_l(:,j)  = 0;
        else
            % Evaluate polynomial coefficients in j-th dimension
            z_l(:,j) = uq_LRA_solveMinimization(A_mat, res, Method);
        end

        % Update univariate function of j-th variable
        u_all(:,j) = P{j}*z_l(:,j);

    end 
    
    % Update rank-1 component
    w_l = u_froz.*u_all(:,j);

    % Update differential empirical error
    errE_iter(iter) = (sum((res-w_l).^2)/N)/varY;
    Derr = abs(errE_iter(iter)-errE_iter(iter-1));
    
    iter_data(iter-1).errE_iter = errE_iter(iter);
    iter_data(iter-1).Derr = Derr;
    
end

% Get actual number of iterations performed
iter = iter-1;

%% Set function output
Results.z_l = z_l;
Results.w_l = w_l;
Results.iter_data = iter_data;
Results.IterNo = iter;
Results.DiffErr = Derr;

