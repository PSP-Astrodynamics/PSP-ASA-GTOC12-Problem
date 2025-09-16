function uq_check_copula_is_defined(Copula)
% uq_check_copula_is_defined(Copula)
%     raises error if the pair copula is not well defined

if length(Copula) == 1
    uq_check_copula_type_supported(Copula.Type)

    if strcmpi(Copula.Type, 'pair')
        uq_check_copula_is_pair(Copula)
        if isfield(Copula, 'Rotation')
            uq_check_pair_copula_parameters(...
                Copula.Family, Copula.Parameters, Copula.Rotation);
        else
            uq_check_pair_copula_parameters(Copula.Family, Copula.Parameters);
        end

    elseif any(strcmpi(Copula.Type, {'cvine', 'dvine'}))
        PCs = uq_PairCopulasInVine(Copula);
        for pp = 1:length(PCs)
            PC = PCs{pp};
            uq_check_copula_is_defined(PC);
        end

    elseif strcmpi(Copula.Type, 'gaussian')
        if isfield(Copula, 'Parameters')
            if ~all(abs(Copula.Parameters) <=1)
                error('Copula parameters must be in the range [-1,1]');
            end
        elseif isfield(Copula, 'RankCorr')
            if ~all(abs(Copula.RankCorr) <=1)
                error('Copula rank correlations must be in the range [-1,1]');
            end
        else
            error('Gaussian copula need fields .Parameters or .RankCorr')
        end

    elseif any(strcmpi(Copula.Type, {'independence', 'independent'}))
        if isfield(Copula, 'Parameters')
            if ~all(all(Copula.Parameters == eye(size(Copula.Parameters))))
                error('Independence copula parameters must be identity matrix');
            end
        end

    elseif strcmpi(Copula.Type, 'auto')
        error('The given copula is undetermined (to be inferred)')

    else
        error('Copula of type %s unknwon or not supported yet', Copula.Type)
    end

else
    
    for ii = 1:length(Copula)
        uq_check_copula_is_defined(Copula(ii))
    end
end
