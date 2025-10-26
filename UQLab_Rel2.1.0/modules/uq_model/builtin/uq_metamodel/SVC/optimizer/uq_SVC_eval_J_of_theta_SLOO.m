function J = uq_SVC_eval_J_of_theta_SLOO(theta,current_model)
% UQ_SVR_J_OF_THETA_SLOO computes the estimated LOO error for an SVR model
% given a set of hyperparameters

% Get the current output being calculated
current_output = current_model.Internal.Runtime.current_output ;
% Non-constant index
nonConst = current_model.Internal.Runtime.nonConstIdx ;
% Retrieve the training points (U = X in the reduced space)
X = current_model.ExpDesign.U(:,nonConst) ;
Y = current_model.ExpDesign.Y(:,current_output) ;

% Get optimal alpha (Lagrange multipliers) by solving the dual
% optimization problem

% Retrieve the current set of hyperparameters
current_model.Internal.Runtime.C = theta(1) ;
current_model.Internal.Runtime.Kernel = current_model.Internal.SVC(current_output).Kernel ;
current_model.Internal.Runtime.Kernel.Params = theta(2:end) ;
% Compute the alpha by solving the SVC QP problem
[alpha,exitflag,lambda,K] = uq_SVC_compute_alphas( X, Y, current_model ) ;
% Save these results for use in uq_calc_SpanLOO
current_model.Internal.Runtime.alpha = alpha ;
current_model.Internal.Runtime.exitflag = exitflag ;
current_model.Internal.Runtime.lambda = lambda ;
current_model.Internal.Runtime.K = K ;

% Set the type of method to compute the LOO at this stage : Span LOO or
% Smoothed span LOO 
current_model.Internal.Runtime.EstimMethod = current_model.Internal.SVC(current_output).EstimMethod ;
J = uq_SVC_calc_SpanLOO( current_model ) ;

end



