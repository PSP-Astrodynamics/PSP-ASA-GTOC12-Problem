function TruncVine = uq_TruncateVineCopula(Vine, truncation, verbose)
% TruncVine = uq_TruncateVineCopula(Vine, truncation, verbose)
%     truncate a vine copula at the desired level. Truncation T sets all 
%     conditional pair copulas with (strictly) more than T conditioning 
%     variables to the independence pair copula
%
% INPUT:
% Vine: struct
%     vine copula to be truncated
% truncation: int
%     level at which to truncate the vine. A vine of dimension M has M-1
%     trees. Truncating at level 1 makes all pair copulas independent, thus
%     making the vine equivalent to the independent copula of dimension M.
%     Specifying level M or higher corresponds to no truncation.

if nargin <= 2
    verbose = 1;
end

if isfield(Vine, 'Truncation') && (Vine.Truncation == truncation)
    if verbose
        warning('The input vine is truncated at the specified level already')
    end
    TruncVine = Vine;
    
elseif isfield(Vine, 'Truncation') && (Vine.Truncation < truncation)
    if verbose
        warning('The input vine is truncated at a lower level already')
    end
    TruncVine = Vine;
    
else
    TruncVine = uq_VineCopula(Vine.Type, Vine.Structure, Vine.Families, ...
        Vine.Parameters, Vine.Rotations, truncation, verbose);
end
