function Marginals = uq_ConstantMarginals(C)
% Marginals = uq_ConstantMarginals(C)
%     Create a structure describing degenerate constant marginals with 
%     parameters from the one-dimensional array C.
%     Each marginal i has fields .Type='Uniform' and .Parameters=C(i).
%
% INPUT:
% C : 1-dimensional array
%     Constant value of the degenerate marginal distributions
% 
% OUTPUT:
% Marginals : struct
%     Structure that describes constant marginals
%
% SEE ALSO: 
%     uq_StdNormalMarginals, uq_StdUniformMarginals, uq_KernelMarginals
if sum(size(C) > 1) > 1
    error('C must be a row or column vector of floats, one per marginal')
end

C = C(:);

M = length(C);
for ii = 1:M
    Marginals(ii).Type = 'Constant';
    Marginals(ii).Parameters = C(ii);
end
