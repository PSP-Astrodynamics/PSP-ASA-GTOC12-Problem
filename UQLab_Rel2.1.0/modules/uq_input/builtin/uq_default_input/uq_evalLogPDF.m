function value = uq_evalLogPDF(X, Input)
% UQ_EVALLOGPDF(X, Input) 
%     calculates the logarithm of the probability density function value of
%     the specified Input (or uq_default_input object) at the points in X. 
%
% See also UQ_EVAL_PDF, UQ_ALL_PDF, UQ_ALL_CDF, UQ_ALL_INVCDF

marginals = Input.Marginals;
copula    = Input.Copula;
logXpdf   = log(uq_all_pdf(X,marginals));
U = uq_all_cdf(X,marginals);
value = sum(logXpdf,2)+uq_CopulaLogPDF(copula, U);
