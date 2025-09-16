function R = uq_PairCopulaParameterRange(family, k)
% R = UQ_PAIRCOPULAPARAMETERRANGE(family)
%     Returns the matrix R of allowed range of values of   
%     each parameter of the specified pair copula family,
%     or for the k-th parameter only (if k specified).
%
% INPUT:
% family : char
%     Pair copula name
% (k : integer or array, optional)
%    Parameter(s) for which to return the range. If not provided, all
%    parameter ranges are returned (one per row of output arraay R).
%    Default: -1 (all parameter ranges)
%
% OUTPUT:
% R : array k-by-2 (k: number of copula parameters)
%     Each row of R represents the allowed range for one 
%     parameter of the specified pair copula family
%
% See also: uq_SupportedPairCopulas

if nargin == 1, k='all'; end
    
family = uq_copula_stdname(family);
supported_families = uq_SupportedPairCopulas();
for ii = 1:length(supported_families)
    if strcmpi(supported_families{ii,2}, family)
        R = supported_families{ii, 3};
        break
    end
end

if ~(isa(k, 'char') && strcmp(k, 'all'))
    R = R(k, :);
end


