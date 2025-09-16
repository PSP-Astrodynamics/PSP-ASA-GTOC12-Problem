function F = uq_ks_pdf( X, parameters, varargin)
% F = UQ_KS_PDF(X, parameters) calculate the Probability Density Function value
%     of samples X  whose density was estimated from existing by
%     kernel-smoothing. This is achieved by interpolating the PDF 
%     values given the ones that were used for kernel-smoothing.
%
% See also: UQ_KS_CDF,UQ_KS_INVCDF 

F = interp1(parameters.u, parameters.pdf, X);


