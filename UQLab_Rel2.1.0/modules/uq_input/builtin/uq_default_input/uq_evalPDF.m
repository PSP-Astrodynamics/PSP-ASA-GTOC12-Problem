function value = uq_evalPDF(X, Input)
% UQ_EVALPDF(X, Input) 
%     calculates the joint probability density function value of the 
%     specified Input (or uq_default_input object) at the points in X. 
%
% See also UQ_EVAL_LOGPDF, UQ_ALL_PDF, UQ_ALL_CDF, UQ_ALL_INVCDF

value = exp(uq_evalLogPDF(X, Input));
