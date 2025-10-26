function AIC = uq_CopulaAIC(Copula, U)
% AIC = UQ_COPULAAIC(Copula, U)
%     Computes the Akaike information criterion (AIC) of the specified 
%     copula on a given data set U of points in the unit square:
%                         AIC = 2 * (K - LL),
%     where K in the number of copula parameters and LL its total 
%     log-likelihood, evaluated over the data set U.
%
% INPUT:
% Copula : struct
%     Structure describing a copula of any dimension M>=2
%     (see uq_PairCopula, uq_VineCopula, ...)
% U : array of size n-by-M
%     coordinates of points in the unit square (one row per data point)
%
% OUTPUT:
% AIC : double
%    AIC of the copula evaluated at the data points in U
%
% SEE ALSO: uq_CopulaPDF, uq_CopulaLL

if isa(Copula.Parameters, 'double')
    AllParams = Copula.Parameters;
else
    AllParams = [Copula.Parameters{:}];
end

Nr_Params = length(AllParams);
AIC = 2 * (Nr_Params - uq_CopulaLL(Copula, U));

