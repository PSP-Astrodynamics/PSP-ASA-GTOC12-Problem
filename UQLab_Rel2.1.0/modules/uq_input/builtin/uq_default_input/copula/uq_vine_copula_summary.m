function uq_vine_copula_summary(Copula, varargin)
% uq_vine_copula_summary(Vine), or uq_vine_copula_summary(VineType, Structure)
%     Prints a summary of the specified vine copula, indicating its 
%     comprising pair copulas, the random variables they couple, the 
%     conditioning variables, and which tree they belong to. 
%
% INPUT:
% Vine : struct
%     A structure describing a vine copula (see uq_VineCopula)
% *OR*
% VineType: char 
%     array containing the vine's type (e.g., 'CVine')
% Structure: array
%     the vine structure (order of its variables)
% Variables: array, optional
%     IDs of the variables coupled by the vine. Default: same as Structure

PCfamily = {};
PCparams = {};
PCstr = {};
if ~isempty(varargin)
    VineType = Copula;
    VineStruct = varargin{1};
    M = length(VineStruct);
    
    if length(varargin) > 1
        Vars = varargin{2};
        if length(Vars) ~= M
            error('Variables must be an array with the same number of elements as Structure')
        end
    else
        Vars = 1:M;
    end
    
    [Pairs, CondVars, Trees] = uq_vine_copula_edges(Copula, VineStruct);
    fprintf('Type: %s\nDimension: %d\nStructure: %s\n\nPair copulas:\n',...
        VineType, M, mat2str(VineStruct))
    fprintf(' Index | Pair Copula \n==================================\n')
    for ii = 1:M*(M-1)/2
        Pair = sprintf('%d,%d', Vars(Pairs{ii}(1)), Vars(Pairs{ii}(2)));
        Cond = strrep(mat2str(Vars(CondVars{ii})), ' ', ',');
        Cond = Cond(2:end-1);
        if isempty(CondVars{ii})
            PCstr{ii} = sprintf('C_%s', Pair);
        elseif length(CondVars{ii}) == 1
            PCstr{ii} = sprintf('C_%s|%d', Pair, Vars(CondVars{ii})); 
        else
            PCstr{ii} = sprintf('C_%s|%s', Pair, Cond); 
        end
        PCstr{ii} = [PCstr{ii} blanks(13-length(PCstr{ii}))];
        %PCstr{ii} = sprintf('%13s', PCstr{ii});
        
        fprintf(' %3d   | %s\n', ii, PCstr{ii})
    end
else
    [Pairs, CondVars, ~] = uq_vine_copula_edges(Copula);
    VineType = Copula.Type;
    VineStruct = Copula.Structure;
    Vars = Copula.Variables;
    M = uq_copula_dimension(Copula);
    PCs = uq_PairCopulasInVine(Copula);
    MaxLength_PCstr = 2*(M+1);
    MaxLength_Params = 0;
    MaxLength_Family = 0;
    for ii = 1:M*(M-1)/2
        PC = PCs{ii};
        Pair = sprintf('%d,%d', Vars(Pairs{ii}(1)), Vars(Pairs{ii}(2)));
        Cond = strrep(mat2str(Vars(CondVars{ii})), ' ', ',');
        Cond = Cond(2:end-1);
        if isempty(CondVars{ii})
            PCstr{ii} = sprintf('C_%s', Pair);
        elseif length(CondVars{ii}) == 1
            PCstr{ii} = sprintf('C_%s|%d', Pair, Vars(CondVars{ii})); 
        else
            PCstr{ii} = sprintf('C_%s|%s', Pair, Cond); 
        end
        PCstr{ii} = [PCstr{ii} blanks(max(2*(M+1),11)-length(PCstr{ii}))];

        PCfamily{ii} = PC.Family;
        PCparams{ii} = mat2str(PC.Parameters);
        PCrot(ii) = uq_pair_copula_rotation(PC);
        
        MaxLength_PCstr = max(MaxLength_PCstr, length(PCstr(ii)));
        MaxLength_Params = max(MaxLength_Params, length(PCparams{ii}));
        MaxLength_Family = max(MaxLength_Family, length(PCfamily{ii}));
        
        PCfamily{ii} = [PCfamily{ii} blanks(12-length(PCfamily{ii}))];
        PCparams{ii} = num2str(PC.Parameters, '%10.4e ');
        PCrot(ii) = uq_pair_copula_rotation(PC);

    end
    
    fprintf('Type: %s\nDimension: %d\nVariables coupled: %s\nStructure: %s\n',...
        VineType, M, mat2str(Vars), mat2str(VineStruct))
    if isfield(Copula, 'Truncation')
        fprintf('Truncation: %d', Copula.Truncation)
        if Copula.Truncation == M
            fprintf(' (none)')
        end
        fprintf('\n')
    end
    fprintf('Pair copulas:\n')
    fprintf('     Index | Pair Copula%s | Family%s | Rot | Parameters%s\n', ...
        blanks(MaxLength_PCstr-11), blanks(6), ...
        blanks(MaxLength_Params-10))
    for ii = 1:M*(M-1)/2
        fprintf('     %3d   | %s | %s | %3d | %s\n', ...
            ii, PCstr{ii}, PCfamily{ii}, PCrot(ii), PCparams{ii})
    end
end

fprintf('\n')

