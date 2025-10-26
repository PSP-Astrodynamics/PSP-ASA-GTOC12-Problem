function uq_CopulaSummary(Copula, varargin)
% uq_CopulaSummary(Copula), or uq_CopulaSummary(CopulaType, varargin)
%     Print a summary of the specified copula: its type, dimension, and 
%     parameters. This function has two uses:
%     * uq_CopulaSummary(Copula), where Copula is a structure which 
%       describes a copula distribution in UQLab.
%     * uq_CopulaSummary(CopulaType, varargin), where CopulaType is a char 
%       which indicates the type of copula and varargin contains additional
%       information.
%
% INPUT:
% Copula : struct
%     A structure describing a copula distribution (see the Input manual)
% *OR*
% CopulaType: char 
%     array containing the copula type (e.g., 'Gaussian', 'CVine', ...)
% varargin: array
%     additional information on the copula:
%     - varargin{1}:
%         * if CopulaType is 'Independent' or 'Gaussian', is the  
%           square matrix of copula parameters 
%         * if CopulaType is 'CVine' or 'DVine', varargin{1} is the vine 
%           structure (order of the variables in the vine)
%     - varargin{2}: ids of the variables coupled by the copula, as
%       integer floats. Optional
%
% EXAMPLES:
% uq_CopulaSummary('CVine', [4 2 1 3])
% uq_CopulaSummary('Gaussian', [1 .3; .3 1])

if ~isa(Copula, 'struct') || (isa(Copula, 'struct') && length(Copula) == 1)
    
    % Deal with the case that Copula is a char representing a copula type
    % and varargin contains info on the copula 
    if ~isempty(varargin)
        CopulaType = Copula;
        if ~isa(CopulaType, 'char')
            msg = 'two arguments are provided, the first one must be a char';
            error('uq_CopulaSummary: if %s', msg)
        end

        if any(strcmpi(CopulaType, {'Gaussian', 'Independent'}))
            Parameters = varargin{1};
            if size(Parameters, 1) ~= size(Parameters, 2)
                msg = 'For a %s copula, the second argument must be its ';
                error([msg 'linear correlation matrix'], CopulaType)
            end
            M = size(Parameters, 1);
            fprintf('Type: %s\nDimension: %d\n', CopulaType, M);

            if length(varargin) > 1
                Vars = varargin{2};
            else
                Vars = 1:M;
            end
            fprintf('Variables coupled: %s\n', mat2str(Vars))

            ParamStr = '\t[';
            for ii = 1:M
                RowStr = '';
                for jj = 1:M
                    Param = Parameters(ii,jj);
                    Sign = '+'; if Param<0, Sign = '-'; end
                    RowStr = [RowStr, sprintf('%s%6.4f ', Sign, abs(Param))]; 
                end
                if ii==1
                    RowStr = [RowStr ';\n'];
                elseif ii<M
                    RowStr = ['\t ' RowStr ';\n'];
                else
                    RowStr = ['\t ' RowStr ']\n'];
                end
                ParamStr = [ParamStr RowStr];
            end
            
            if M>1 && ~strcmpi(CopulaType, 'independent') && M<=10
                fprintf(['Parameters:\n', ParamStr, '\n']);
            end
            
        elseif strcmpi(CopulaType, 'Pair')
            fprintf('Type: Pair\n')

        elseif any(strcmpi(CopulaType, {'CVine', 'DVine'}))
            VineStruct = varargin{1};
            M = length(VineStruct);
            if length(varargin) > 1
                Vars = varargin{2};
                assert(length(Vars) == M)
            else
                Vars = 1:M;
            end
            uq_vine_copula_summary(CopulaType, VineStruct, Vars)

        else
            error('Copula Type %s unknown or not supported yet', CopulaType)
        end
        
    % Deal with the case that Copula is a structure representing a copula
    else
        uq_check_copula_is_defined(Copula);

        if any(strcmpi(Copula.Type, {'Gaussian', 'Independent'}))
            uq_CopulaSummary(Copula.Type, Copula.Parameters, Copula.Variables);

        elseif any(strcmpi(Copula.Type, {'Pair'}))
            fprintf('Type: Pair\n')
            fprintf('Variables coupled: %s\n', mat2str(Copula.Variables))
            fprintf('%15s: %s\n', 'Family', Copula.Family)
            fprintf('%15s: %d\n', 'Rotation', uq_pair_copula_rotation(Copula))
            fprintf('%15s: %s\n\n', 'Parameters', ...
                mat2str(Copula.Parameters, 4))    

        elseif any(strcmpi(Copula.Type, {'CVine', 'DVine'}))
            uq_vine_copula_summary(Copula);

        else
            error('Copula Type %s unknown or not supported yet', Copula.Type)
        end 
    end

else % If several copulas have been provided
    NrCopulas = length(Copula);
    
    fprintf('Tensor product of %d copulas between the random vectors\n\t', ...
        NrCopulas)
    for ii = 1:(NrCopulas-1)
        fprintf('X_%s, ', mat2str(Copula(ii).Variables))
    end
    fprintf('X_%s\n\n', mat2str(Copula(end).Variables))
    
    for ii = 1:NrCopulas
        fprintf('Copula %d, of X_%s:\n', ii, mat2str(Copula(ii).Variables))
        uq_CopulaSummary(Copula(ii))
    end
end

        
    
