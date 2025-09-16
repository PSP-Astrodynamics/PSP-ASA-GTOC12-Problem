function J = uq_SVC_eval_J_of_theta_CV(theta,current_model)
% UQ_SVC_EVAL_J_OF_THETA_CV computes the actual cross- validation error of
% an SVC model given its hyperparameters

current_output = current_model.Internal.Runtime.current_output ;

% Get the hyperparameters
current_model.Internal.Runtime.C = theta(1) ;
current_model.Internal.Runtime.Kernel = current_model.Internal.SVC(current_output).Kernel ;
current_model.Internal.Runtime.Kernel.Params = theta(2:end) ;

% Perform cross-validation and return estimated CV error
[ ~, additional_metrics] = uq_SVC_calc_leaveKout( current_model );
J = additional_metrics.CV_error;

end