function P = uq_CopulaPDF(Copula, U)
% P = UQ_COPULAPDF(Copula, U)
%     Computes the PDF of the specified copula at each point in U.
%
% INPUT:
% Copula : struct
%     A structure describing a copula (see the UQlab Input Manual)
% U : array of size n-by-M
%     coordinates of points in the unit hypercube (one row per data point)
%
% OUTPUT:
% P : array n-by-1
%     the value of the copula density at the points in U
%
% SEE ALSO: uq_CopulaCDF, uq_CopulaLogPDF

P = exp(uq_CopulaLogPDF(Copula, U));
