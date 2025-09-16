function [coeffnew,lh] = uq_SPCE_optimize_NLogLikelihood(Y,coeff0,sigma,XBasis,ZBasis,SPCEOpt)
%% Compute the coefficients of the SPCE model
% Y: the output data
% coeff0: initial points of the SPCE coefficients
% sigma: std of the noise term
% XBasis: information of the input basis functions (see UQ_PCE_CALCULATE_REGRESSION for its definition)
% ZBasis: information of the latent basis functions (see UQ_PCE_CALCULATE_REGRESSION for its definition)
% options: options for the likelihood evaluation
% ----- Output -----
% coeffnew: fitted coefficients
% lh: negative log-likelihood


% display level
if SPCEOpt.DisplayLevel>1
    verbose = 'iter';
else
    verbose = 'notify';
end

% get total number of the output (contains possible replications)
N_data = numel(Y) ;

stop = 0;
n_it = 0;
coeff_old = coeff0;

% set optimization options
opt = optimoptions(@fminunc,'Display',verbose,'MaxIter',5000,'MaxFunEvals',5000,'FunctionTolerance',(1e-5)/N_data,'StepTolerance',1e-6,'OptimalityTolerance',1e-6,'SpecifyObjectiveGradient',true,'Algorithm','quasi-newton');

% perform the maximum likelihood estimation
while ~stop
    try
        [coeffnew,lh,exitflag,~,grad]=fminunc(@(coeff)uq_SPCE_NLogLikelihood(Y,coeff,sigma,XBasis,ZBasis,SPCEOpt),coeff_old,opt);
    catch
        coeffnew = coeff_old;
        lh = uq_SPCE_NLogLikelihood(Y,coeffnew,sigma,XBasis,ZBasis,SPCEOpt);
        break;
    end
    
    % check whether to stop (2 possible stopping criteria, the algorithm is stopped whenever one is fulfilled)
    % the first one is that the maximum gradient is less then 1e-4
    stop1 = max(abs(grad))<1e-4;
    
    % the second one is that the relative changes in the coefficients is
    % less than 1e-3
    checkind = coeffnew~=0;
    diff = max(abs(coeff_old(checkind)-coeffnew(checkind))./coeffnew(checkind));
    stop2 = ((exitflag==1)|(diff<1e-3));
    stop = stop1|stop2;
    
    % update the coefficients
    coeff_old = coeffnew;
    
    % if the iteration time reaches 5, we would leave the optimization to
    % save computational time
    n_it = n_it+1;          
    if n_it>5
       break;
    end
end
end