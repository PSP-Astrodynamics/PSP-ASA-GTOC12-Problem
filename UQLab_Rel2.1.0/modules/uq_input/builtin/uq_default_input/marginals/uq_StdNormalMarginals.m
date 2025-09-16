function Marginals = uq_StdNormalMarginals(D)
% Marginals = uq_StdNormalMarginals(M)
%     Create a 1-by-M structure describing M standard normal marginals. 
%     Each marginal has fields .Type='Gaussian' and .Parameters=[0 1].
%
% INPUT:
% M : integer
%     Number of marginal distributions
% 
% OUTPUT:
% Marginals : struct
%     Structure that describes M standard normal marginals.
%
% SEE ALSO: uq_StdUniformMarginals, uq_KernelMarginals

[Marginals(1:D).Type] = deal('Gaussian');
[Marginals(1:D).Parameters] = deal([0 1]);
