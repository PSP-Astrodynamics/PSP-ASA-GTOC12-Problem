function results = uq_LRA_lars(regressors, Y_ED, MethodOptions)
% This function calls the lar algorithm and returns the respective outputs

results = uq_lar(regressors, Y_ED, MethodOptions.LARS);

end
