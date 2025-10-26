function pass = uq_isGaussianCopula(Copula)
% pass = uq_isGaussianCopula(Copula)
%     Returns true is the specified copula is the Gaussian copula
%     or is equivalent to one (e.g., a vine copula consisting of
%     gaussian pair copulas only.
%     For a structure containing multiple copulas, it returns true if all 
%     copulas are Gaussian (in which case, their tensor product is Gaussian).
%
%     NOTE: This function does not check that the copula is well defined.
%     For instance, it returns true if the copula has .Type='Independent'
%     and (meaningless) parameters [1 2].
%
% SEE ALSO: uq_isIndependenceCopula

if length(Copula) == 1
    pass = false;

    Synonims = {'gaussian'};

    isSynonim = @(S) all(ismember(lower(S), Synonims));

    if isSynonim(Copula.Type)
        pass = true;
    elseif strcmpi(Copula.Type, 'Pair') && isfield(Copula, 'Family') && ...
            isSynonim(Copula.Family)
        pass = true;
    elseif any(strcmpi(Copula.Type, {'cvine', 'dvine'})) && ...
            isfield(Copula, 'Families') && ...
            isSynonim(Copula.Families)
        pass = true;
    elseif uq_isIndependenceCopula(Copula, false)
        pass = true;
    end

else
    pass = uq_isGaussianCopula(Copula(1)) && ...
           uq_isGaussianCopula(Copula(2:end));
end
