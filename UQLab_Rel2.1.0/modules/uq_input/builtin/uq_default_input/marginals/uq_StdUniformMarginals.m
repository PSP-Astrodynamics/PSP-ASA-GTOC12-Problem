function Marginals = uq_StdUniformMarginals(M)
% Marginals = uq_StdUniformMarginals(M)
%     Create a 1-by-M structure describing M standard uniform marginals. 
%     Each marginal has fields .Type='Uniform' and .Parameters=[0 1].
%
% INPUT:
% M : integer
%     Number of marginal distributions
% 
% OUTPUT:
% Marginals : struct
%     Structure that describes M standard uniform marginals.
%
% SEE ALSO: uq_StdNormalMarginals, uq_KernelMarginals

[Marginals(1:M).Type] = deal('Uniform');
[Marginals(1:M).Parameters] = deal([0 1]);
