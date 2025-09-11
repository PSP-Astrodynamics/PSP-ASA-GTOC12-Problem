function LL = uq_CopulaLL(Copula, U)
% LL = UQ_COPULALL(Copula, U)
%     Computes the total log-likelihood (LL) of the specified copula 
%     on a given data set U of points in the unit hypercube. 
%
% INPUT:
% Copula : struct
%     A structure describing a copula (see the UQlab Input Manual)
% U : array of size n-by-M
%     coordinates of points in the unit hypercube (one row per data point)
%
% OUTPUT:
% LL : double
%    total log-likelihood of the copula evaluated at the data points in U 
%    (sum of the log-likelihoods at each point).
%
% SEE ALSO: uq_CopulaPDF

LL = sum(uq_CopulaLogPDF(Copula, U));
