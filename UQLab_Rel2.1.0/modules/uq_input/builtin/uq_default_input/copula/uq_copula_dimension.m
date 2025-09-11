function M = uq_copula_dimension(Copula)
% M = uq_copula_dimension(Copula)
%     Extract and returns the dimension of a given Copula structure

if length(Copula) == 1
    if strcmpi(Copula.Type, 'Independent')
        if uq_isnonemptyfield(Copula, 'Parameters')
            M = size(Copula.Parameters, 1);
        elseif uq_isnonemptyfield(Copula, 'RankCorr')
            M = size(Copula.RankCorr, 1);
        elseif uq_isnonemptyfield(Copula, 'Dimension')
            M = Copula.Dimension;
        else
            error('uq_copula_dimension: missing field Parameters given copula');
        end

    elseif strcmpi(Copula.Type, 'Pair')
        M = 2;

    elseif strcmpi(Copula.Type, 'Gaussian')
        if isfield(Copula, 'Parameters')
            M = size(Copula.Parameters, 1);
        elseif isfield(Copula, 'RankCorr')
            M = size(Copula.RankCorr, 1);
        else 
            error('uq_copula_dimension: input argument Copula wrongly specified');
        end

    elseif any(strcmpi(Copula.Type, {'CVine', 'DVine'}))
        M = numel(Copula.Structure);

    elseif strcmpi(Copula.Type, 'Infer')
        M = numel(Copula.Inference.Structure);
    end
    
% If Copula contains several copulas, sum their individual dimensions
else
    M = uq_copula_dimension(Copula(1)) + uq_copula_dimension(Copula(2:end));
end

       
