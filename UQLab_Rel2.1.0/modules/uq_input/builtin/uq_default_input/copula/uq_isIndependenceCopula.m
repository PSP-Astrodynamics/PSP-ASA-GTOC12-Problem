function pass = uq_isIndependenceCopula(Copula, check_gaussian)
% pass = uq_isIndependenceCopula(Copula, check_gaussian)
%     Returns true is the specified copula is the independence copula
%     or is equivalent to one (e.g., a vine copula consisting of
%     independence pair copulas only, or a Gaussian copula with diagonal 
%     correlation matrix), false otherwise.
%
%     NOTE: This function does not check that the copula is well defined.
%     For instance, it returns true if the copula has .Type='Independent'
%     and (meaningless) parameters [1 2].
%
% SEE ALSO: uq_isGaussianCopula

if nargin < 2, check_gaussian = true; end;

if length(Copula) == 1
    pass = false;

    Synonims = {'independent', 'independence'};

    isSynonim = @(S) all(ismember(lower(S), Synonims));

    if isSynonim(Copula.Type)
        pass = true;
    elseif strcmpi(Copula.Type, 'Pair') && isfield(Copula, 'Family') && ...
            isSynonim(Copula.Family)
        pass = true;
    elseif strcmpi(Copula.Type, 'Pair') && isfield(Copula, 'Family') && ...
            isSynonim(Copula.Family)
    elseif any(strcmpi(Copula.Type, {'cvine', 'dvine'})) && ...
            isfield(Copula, 'Families') && ...
            isSynonim(Copula.Families)
        pass = true;
    elseif check_gaussian && uq_isGaussianCopula(Copula)
        if isfield(Copula, 'Parameters')
            Matrix = Copula.Parameters;
            M = size(Matrix, 1);
            Eye = eye(M);
            if all(Matrix(:) == Eye(:))
                pass = true;
            end
        elseif isfield(Copula, 'RankCorr')
            Matrix = Copula.RankCorr;
            M = size(Matrix, 1);
            Eye = eye(M);
            if all(Matrix(:) == Eye(:))
                pass = true;
            end
        end
    end

else
    pass = uq_isIndependenceCopula(Copula(1)) && ...
           uq_isIndependenceCopula(Copula(2:end));
end
