function [lhcv,coeffout] = uq_SPCE_CVScore(Y,coeff0,logsigma,XBasis,ZBasis,SPCEOpt)
%% evaluate the cross-validation score
% ----- Input -----
% Y: the output data
% coeff0: the initial point for the coefficient
% logsigma: log transform of the sigma value. The transform is mainly used
% for optimization
% XBasis: basis information of the input (see UQ_PCE_CALCULATE_REGRESSION for its definition)
% ZBasis: basis information of the latent variable (see UQ_PCE_CALCULATE_REGRESSION for its definition)
% SPCEOpt: options of SPCE
% ----- Output -----
% lhcv: array of the cross validation score for each CV-fold
% coeffout: the estimated coeffcients for the first fold. This 
% quantity is mainly used in guiding the optimization in UQ_PCE_CALCULATE_REGRESSION

% recover the sigma value
sigma = exp(logsigma);

% initialize the cvscore
lhcv = zeros(SPCEOpt.Sigma.CVFolds,1);

% get sigma options
SPCEOpt.Sigma.current_latent = SPCEOpt.current_latent;

XBasisTmp = XBasis;
for icv = 1:SPCEOpt.Sigma.CVFolds
    % for training
    ind = SPCEOpt.Sigma.CV.training(icv);
    XBasisTmp.PsiX = XBasis.PsiX(ind,:);
    coeffnew = uq_SPCE_optimize_NLogLikelihood(Y(ind),coeff0,sigma,XBasisTmp,ZBasis,SPCEOpt);
    
    % for testing
    ind = SPCEOpt.Sigma.CV.test(icv);
    XBasisTmp.PsiX = XBasis.PsiX(ind,:);
    lhcv(icv) = uq_SPCE_NLogLikelihood(Y(ind),coeffnew,sigma,XBasisTmp,ZBasis,SPCEOpt.Sigma);
    
    % update the coefficients to reduce the computing time (mainly for the iteration in UQ_PCE_CALCULATE_REGRESSION)
    coeff0 = coeffnew;
    if icv==1
        coeffout=coeffnew;
    end
end

end