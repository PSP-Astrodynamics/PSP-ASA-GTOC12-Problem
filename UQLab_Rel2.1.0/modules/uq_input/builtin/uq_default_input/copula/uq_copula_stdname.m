function stdname = uq_copula_stdname(name)
% stdname = uq_copula_stdname(name)
%     converts a given copula type/family name to a standard name.
%     E.g.: 'Independence' -> 'Independent', 'Normal'->'Gaussian'
%     This function is used internally in uqlab to interpret synonyms.
% 
% INPUT:
% name : char
%
% OUTPUT: 
% stdname : char 

name = lower(name);

switch name
    case {'independent', 'independence'}
        stdname = 'Independent';
    case {'gaussian', 'normal'}
        stdname = 'Gaussian';
    case 't'
        stdname = 't';
    case 'cvine'
        stdname = 'CVine';
    case 'dvine'
        stdname = 'DVine';
    otherwise
        stdname = [upper(name(1)), lower(name(2:end))]; 
end
