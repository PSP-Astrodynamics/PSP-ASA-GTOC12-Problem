function [myCopula, GoF] = uq_infer_copula(U, Copula)
% [myCopula, GoF] = uq_infer_copula(U, Copula, alpha, stat, correction)
%     Fit copula to a sample U of points in the unit hypercube.
%
% INPUT
% -----
% U : array n-by-M
%    n observations (rows) of an M-variate random vector 
% Copula : struct
%    Copula specifications. (see the UQLab Inference Manual). 
%
% OUTPUT
% ------
% myCopula : struct
%     copula inferred from data U.
% GoF : cell 1-by-M
%     GoF is a containers.Map object which contains the goodness-of-fit 
%     measures for each copula class fitted on X(:,jj), jj=1,...,M.
%     GoF{jj}('<name>') is a structure which contains the log-likelihood 
%     (.LL), and the Akaike/Bayesian information criteria (.AIC/.BIC) of 
%     distribution '<name>' on X(:,jj).


%% Make sure no NaNs are present in the data
if any(isnan(U(:)))
    error(sprintf('Copula inference data contains NaNs, inference cannot be performed.\nPlease cleanup data prior to performing inference\n'));
end

% =========================================================================
% Set defaults
% =========================================================================
PCfamilies_default = 'auto';    % PC families for inference of PCs and vines
Truncation_default = 2;         % vine truncation
VineStructure_default = 'auto';

default_pairindeptest = struct();
default_pairindeptest.Alpha = 0.1;
default_pairindeptest.Type = 'Kendall';
default_pairindeptest.Correction = 'auto';

pairindeptest = default_pairindeptest;
if isfield(Copula, 'Inference') && isfield(Copula.Inference, ...
        'PairIndepTest')
    pairindeptest = uq_overwrite_fields(...
        Copula.Inference.PairIndepTest, default_pairindeptest, {}, ...
        {'Alpha', 'Type', 'Correction'});
end

[n, M] = size(U);
log_n = log(n);

if ~uq_isnonemptyfield(Copula, 'Variables')
    Copula.Variables = 1:M;
end

% ============================================================
% PART 1: initialization, setting variables to standard types
% ============================================================

% Make various checks for input arguments
% uq_check_data_in_unit_hypercube(U);

if ~isa(Copula, 'struct')
    error('input Copula must be a struct')
end

% Restructure Copula.Type as a cell, if it is a char.
% If it is the string 'auto', define all types to choose among
if M == 2
    SupportedTypes = {'Independent', 'Pair'};
elseif M==3
    SupportedTypes = {'CVine', 'Gaussian', 'Independent'};    
elseif M>3
    SupportedTypes = {'CVine', 'DVine', 'Gaussian', 'Independent'};
end

CopulaTypes = Copula.Type; 
if isa(CopulaTypes, 'char')
    if strcmpi(CopulaTypes, 'auto')
        CopulaTypes = SupportedTypes;
        if M == 2
            CopulaTypes = setdiff(CopulaTypes, {'CVine', 'DVine', 'Gaussian'});
        else
            CopulaTypes = setdiff(CopulaTypes, {'Pair'});
            if M == 3
                CopulaTypes = setdiff(CopulaTypes, {'DVine'});
            end
        end
    else
        CopulaTypes = {CopulaTypes};
    end
elseif ~isa(CopulaTypes, 'cell')
    errmsg = 'must be a char or a cell of chars'; 
    error('Copula.Type %s', errmsg)
end

% (Only if a vine has been included in the copula types to infer from):
% Restructure Copula.Inference.PCfamilies as a cell, if it is a char.
% If it is the string 'auto', define all distributions to choose among.
SupportedPCs = uq_SupportedPairCopulas;
SupportedPCs = [SupportedPCs(:,2)];

if any(ismember({'cvine', 'dvine', 'pair'}, lower(CopulaTypes)))
    % ...check that the field .PCfamilies exists
    if ~isfield(Copula.Inference, 'PCfamilies')
        Copula.Inference.PCfamilies = PCfamilies_default;
    end
    
    % ...build a list of all allowed PC families for inference
    allowed_PCfamilies = Copula.Inference.PCfamilies;
    if isa(allowed_PCfamilies, 'char')
        if strcmpi(allowed_PCfamilies, 'auto')
            allowed_PCfamilies = SupportedPCs;
        else
            allowed_PCfamilies = {allowed_PCfamilies};
        end
    elseif ~isa(allowed_PCfamilies, 'cell')
        errmsg = 'must be a char or a cell of chars'; 
        error('Marginals(%d).Inference.Families %s', ii, errmsg)
    end
    Copula.Inference.PCfamilies = allowed_PCfamilies;
    
    % ...check that all specified PC families are supported
    l = numel(allowed_PCfamilies);
    for ll=1:l
        name = allowed_PCfamilies{ll};
        if ~any(strcmpi(name, SupportedPCs))
            errmsg = 'uq_infer_copula: PC family';
            error('%s ''%s'' unknown or not supported yet', errmsg, name)
        end
    end
    
    % Define a structure that describes a PairCopula to be inferred.
    % It is going to be used for inference of each pair copula on Vines.
    PC = {};
    PC.Type = 'Pair';
    PC.Inference.PCfamilies = allowed_PCfamilies;
end

% (Only if a vine has been included in the copula types to infer from):
% set default structure of the vine as to be obtained by inference
if any(strcmpi(Copula.Type, 'CVine'))
    if ~isfield(Copula.Inference, 'CVineStructure')
        Copula.Inference.CVineStructure = VineStructure_default;
    end
end

if any(strcmpi(Copula.Type, 'dvine'))
    if ~isfield(Copula.Inference, 'DVineStructure')
        Copula.Inference.DVineStructure = VineStructure_default;
    end
end

if any(ismember(lower(Copula.Type), {'cvine', 'dvine'}))
    if ~isfield(Copula, 'Truncation')
        Copula.Truncation = Truncation_default;
    elseif Copula.Truncation == 0 % && verbose
            msg = 'vine truncation 0 (all pair copulas independent)';
            warning('%s requested. Independent copula will be returned', msg)
    elseif Copula.Truncation > M
        if verbose
            msg = sprintf('vine truncation %d out of range [0 %d]', ...
                Copula.Truncation, M);
            warning('%s. Set to %d (no truncation) instead', msg, M)
        end
        Copula.Truncation = M;
    elseif Copula.Truncation < 0
        error('negative vine truncation level provided. Specify an integer between 0 and M')
    end
elseif isfield(Copula, 'Truncation') 
    msg1 = 'Copula inference: Vine truncation level specified  but no';
    msg2 = '\nvine copula requested. Truncation will be ignored.';
    warning('%s%s', msg1, msg2)
end



% ============================================================
% PART 2: Inference
% ============================================================

% Initialize outputs myMarginals and GoF

if isa(Copula.Type, 'char') && ~strcmpi(Copula.Type, 'auto') ...
        && isfield(Copula, 'Parameters') ... % If copula not to be inferred
        && ~isa(Copula.Parameters, 'char') ...
        && (any(strcmpi(Copula.Type, {'independence', 'independent'})) ...
            || ~isempty(Copula.Parameters))
            
    myCopula = Copula;     % copy it to output struct

    k = length(Copula.Parameters);

    S = struct();
    S.LL = uq_CopulaLL(Copula, U);    
    S.AIC = 2    *k - 2*S.LL;
    S.BIC = log_n*k - 2*S.LL;

    % Add results to output variable GoF
    CopType = Copula.Type;
    if strcmpi(CopType, 'Pair')
        CopType = [CopType, Copula.Family];
    end
    GoF.(CopType) = S;

else  % If the copula has to be inferred from data
        
    % Check that Copula has the field .Inference
    if ~isfield(Copula, 'Inference')
       error('uq_infer_copula: missing field Copula.Inference')
    end

    % Define selection criterion
    if isfield(Copula.Inference, 'Criterion')
        SelCriterion = Copula.Inference.Criterion;
    else
        SelCriterion = 'AIC'; % default: AIC
    end

    % Perform inference
    l = length(CopulaTypes);
    LL_copula = zeros(1, l);        % initialize log-likelihood to 0
    bestGoF = +inf;                 % initialize best GoF to +inf 
    for ll = 1:l % For each class of copulas to fit on U...  
        CopulaType = CopulaTypes{ll};
        
        % Initialize FittedCopula structure
        FittedCopula = struct();
        
        % Constraining U strictly in (0,1) is necessary to perform
        % inference avoiding NaNs in the log-likelihood
        U = min(max(U, eps), 1-eps);
        
        % Fit the copula of given type
        if any(strcmpi(CopulaType, {'independent', 'independence'}))
            CopulaType = 'Independent';
            params = eye(M);
            NrPar = 0;
            FittedCopula.Type = CopulaType;
            FittedCopula.Parameters = params;

        elseif strcmpi(CopulaType, 'Gaussian')
            params = corrcoef(norminv(U)); 
            params = (params+params')/2; % correct small machine errors
            % Add nugget if correlation matrix is not positive definite
            try
                L = chol(params);
                % FittedCopula.cholR = L; % revive?
            catch
                params = (params + eps * eye(M)) / (1+eps);
            end
            NrPar = M*(M-1)/2;
            FittedCopula.Type = CopulaType; 
            FittedCopula.Parameters = params;

        elseif strcmpi(CopulaType, 'Pair')
            FittedCopula.Type = CopulaType; 

            % Check that U has two columns
            % Perform independence test, if requested
            isIndep = [0 0; 0 0];
            if ~isempty(pairindeptest.Alpha)
                [pVal, isIndep, threshold, testStat] = ...
                    uq_test_pair_independence(U, pairindeptest.Alpha, ...
                    pairindeptest.Type, pairindeptest.Correction);
                FittedCopula.PairIndepTest.pvalue = pVal;
                FittedCopula.PairIndepTest.result = isIndep;
                FittedCopula.PairIndepTest.threshold = threshold;
                FittedCopula.PairIndepTest.testStat = testStat;
                FittedCopula.PairIndepTest.Type = pairindeptest.Type;
            end
            
            if isIndep(1,2)
                FittedCopula.Type = 'Independent';
                params = eye(2);
                NrPar = 0;
                GoF.PairIndependence.LL = 0;
                GoF.PairIndependence.AIC = 0;
                GoF.PairIndependence.BIC = 0;
            else
                % Fit all allowed pair copulas, and retain the best                         
                LL0 = -Inf;
                AIC0 = Inf;
                BIC0 = Inf;
                bestGoF = Inf;
                params = [];
                NrPar = -1;
                for ii = 1:length(allowed_PCfamilies)
                    PCfamily = allowed_PCfamilies{ii};
                    rots = unique(uq_pair_copula_equivalent_rotation(...
                        PCfamily, 0:90:270));
                    [theta, rot, LL] = uq_fit_pair_copula(U, PCfamily, rots);
                    k = length(theta);
                    AIC = 2*(k-LL);
                    BIC = log_n*k - 2*LL;
                    GoF.(['Pair' PCfamily]).LL = LL;
                    GoF.(['Pair' PCfamily]).AIC = AIC;
                    GoF.(['Pair' PCfamily]).BIC = BIC;
                    
                    if strcmpi(SelCriterion, 'ML')
                        thisGoF = -LL;
                    elseif strcmpi(SelCriterion, 'AIC')
                        thisGoF = AIC;
                    elseif strcmpi(SelCriterion, 'BIC')
                        thisGoF = BIC;
                    else
                        error('Copula inference criterion wrongly specified')
                    end

                    if ~isfinite(thisGoF)
                        error('something is wrong: %s is not finite', ...
                            SelCriterion)
                    elseif thisGoF < bestGoF
                        bestGoF = thisGoF;
                        FittedCopula.Family = PCfamily;
                        FittedCopula.Rotation = rot;
                        params = theta;
                    end
                end
            end
            FittedCopula.Parameters = params;
            
        elseif strcmpi(CopulaType, 'CVine')
            
            % If vine truncation is 0, assign independent copula and 
            % continue to next copula type
            if Copula.Truncation == 0
                msg1 = 'inferred vine has truncation parameter 0; ';
                warning([msg1 'independent copula returned'])
                CopulaType = 'Independent';
                params = eye(M);
                NrPar = 0;
                FittedCopula.Type = CopulaType;
                FittedCopula.Parameters = params;
            else
            
                params = {};
                families = {};
                NrPar = 0;
                if isfield(Copula.Inference, 'CVineStructure')
                    Structure = Copula.Inference.CVineStructure;
                    if isa(Structure, 'char') && strcmpi(Structure, 'auto')
                        Structure = uq_inferVineStructure(U, CopulaType);
                    elseif ~isa(Structure, 'double') || numel(Structure) ~= M
                        errmsg = 'Copula.Inference.CVineStructure must be an ';
                        error('%s array with %d integers', errmsg, M);
                    end
                else
                    Structure = uq_inferVineStructure(U, CopulaType);
                end

                % Reorder U into UU in order to use vine structure 1:M
                UU = U(:, Structure);
                [Pairs, CondVars, Trees] = uq_vine_copula_edges('CVine', 1:M);

                % Infer each pair copula, starting from the first tree
                V = zeros(n, M, M); 
                V(:,1,1:M) = UU;  
                PCidx = 0;
                for jj = 1:min(Copula.Truncation, M-1)      % For each tree jj
                    for ii = 1:M-jj 
                        PCidx = PCidx + 1;
                        % Infer the PC between V(:,jj,1) and V(:,jj,1+ii)
                        Pair = [jj jj+ii];
                        PairCopula = uq_infer_copula(...
                            [V(:,jj,1),V(:,jj,1+ii)], PC);
                        if uq_isIndependenceCopula(PairCopula)
                            families{PCidx} = 'Independent';
                            params{PCidx} = [];
                            rotations(PCidx) = 0;                        
                        else
                            families{PCidx} = PairCopula.Family;
                            params{PCidx} = PairCopula.Parameters;
                            rotations(PCidx) = uq_pair_copula_rotation(PairCopula);
                        end
                        % Transform observations into conditional observations
                        if jj < M-1
                            V(:,jj+1,ii) = uq_pair_copula_ccdf1(...
                                PairCopula, [V(:,jj,1), V(:,jj,ii+1)]);
                            % Force the transformation to be within (0,1)
                            % (not present in original algorithm by Aas et al
                            % but important for numerical stability)
                            V(:,jj+1,ii) = min(max(V(:,jj+1,ii), eps), 1-eps);
                        end
                    end
                end            
                FittedCopula = uq_VineCopula(...
                    CopulaType, Structure, families, params, rotations, ...
                    Copula.Truncation, 0);
            end
            
        elseif strcmpi(CopulaType, 'DVine')
            
            if Copula.Truncation == 0
                msg1 = 'inferred vine has truncation parameter 0; ';
                warning([msg1 'independent copula returned'])
                CopulaType = 'Independent';
                params = eye(M);
                NrPar = 0;
                FittedCopula.Type = CopulaType;
                FittedCopula.Parameters = params;
            else
                PairCopula = {};
                params = {};
                families = {};
                NrPar = 0;
                if isfield(Copula.Inference, 'DVineStructure')
                    Structure = Copula.Inference.DVineStructure;
                    if isa(Structure, 'char') && strcmpi(Structure, 'auto')
                        Structure = uq_inferVineStructure(U, CopulaType);
                    elseif ~isa(Structure, 'double') || numel(Structure) ~= M
                        errmsg = 'Copula.Inference.DVineStructure must be an ';
                        error('%s array with %d integers or the char ''auto''.', errmsg, M);
                    end
                else
                    Structure = uq_inferVineStructure(U, CopulaType);
                end
                % Reorder U into UU in order to use vine structure 1:M
                UU = U(:, Structure);
                [Pairs, CondVars, Trees] = uq_vine_copula_edges('DVine', 1:M);

                % Initialize vector V of conditional pseudo-observations.
                % Set V(:,1,ii) = U(:,ii) for ii=1,...,M
                V = -ones(n, M, max(M, 2*M-4)); 
                V(:,1,1:M) = UU;  % first for loop in algo 4 by Aas et al (2009)
                PCidx = 0;

                % First tree of the vine: infer the unconditional pair copulas.
                % Set: V(:,2,1)=U_1|2
                for ii = 1:M-1
                    PCidx = PCidx+1;
                    Pair = [ii, ii+1];
                    Vpair = [V(:,1,Pair(1)), V(:,1,Pair(2))];
                    PairCopula{Pair(1), Pair(2)} = uq_infer_copula(Vpair, PC);
                    if uq_isIndependenceCopula(PairCopula{Pair(1), Pair(2)})
                        families{PCidx} = 'Independent';
                        params{PCidx} = [];
                        rotations(PCidx) = 0;                        
                    else
                        families{PCidx} = PairCopula{Pair(1), Pair(2)}.Family;
                        params{PCidx} = PairCopula{Pair(1), Pair(2)}.Parameters;
                        rotations(PCidx) = uq_pair_copula_rotation(...
                            PairCopula{Pair(1), Pair(2)});
                    end

                    if ii==1 % assignment "v(1,1)=..." in algo 4 by Aas et al
                        V(:,2,1) = uq_pair_copula_ccdf2(...
                            PairCopula{Pair(1), Pair(2)}, Vpair);
                    end
                end

                % Stop here if truncation is 1
                if Copula.Truncation > 1

                    % Evaluate conditional CDFs of order 1 wrt both arguments
                    % (3rd for-loop and row below it in algo 4 by Aas et al, 2009).
                    % Set: V(:,2,2*kk)   = U_kk+2|kk+1, kk=1,...,M-2
                    %      V(:,2,2*kk+1) = U_kk+1|kk+2, kk=1,...,M-3
                    % -> V(:,2,1:2*M-4) = {U_1|2, U_3|2, U_2|3, U_4|3,..., U_M|M-1}
                    for kk = 1:M-2
                        Pair = [kk+1, kk+2];
                        Vpair = [V(:, 1, Pair(1)), V(:, 1, Pair(2))];
                        V(:,2,2*kk) = uq_pair_copula_ccdf1(...
                            PairCopula{Pair(1), Pair(2)}, Vpair);
                        if kk <= M-3
                            V(:,2,2*kk+1) = uq_pair_copula_ccdf2(...
                                PairCopula{Pair(1), Pair(2)}, Vpair);
                        end
                    end

                    % Infer remaining conditional copulas
                    for jj = 2:min(Copula.Truncation, M-1) % for each tree
                        for ii = 1:M-jj % for each 1st variable in each tree's PC
                            PCidx = PCidx+1;
                            % Infer the Pair Copula between ii and ii+jj
                            Pair =[ii ii+jj];
                            Vpair = [V(:, jj, 2*ii-1), V(:, jj, 2*ii)];
                            PairCopula{Pair(1),Pair(2)} = uq_infer_copula(Vpair,PC);
                            if uq_isIndependenceCopula(PairCopula{Pair(1),Pair(2)})
                                families{PCidx} = 'Independent';
                                params{PCidx} = [];
                                rotations(PCidx) = 0;                        
                            else
                                families{PCidx} = PairCopula{Pair(1),Pair(2)}.Family;
                                params{PCidx} = PairCopula{Pair(1),Pair(2)}.Parameters;
                                rotations(PCidx) = uq_pair_copula_rotation(...
                                    PairCopula{Pair(1),Pair(2)});
                            end
                        end

                        if jj == M-1, break; end

                        % Take the Pair Copula between 1 and 1+jj.
                        % Set V(:,jj+1,1) = U_1|2,...,jj+1
                        Pair =[1 1+jj];
                        V(:,jj+1,1) = uq_pair_copula_ccdf2(...
                            PairCopula{Pair(1),Pair(2)}, [V(:,jj,1), V(:,jj,2)]);

                        if M > 4
                            for ii = 1:M-jj-1
                                Pair =[ii+1 ii+jj+1];
                                Vpair = [V(:,jj,2*ii+1), V(:,jj,2*ii+2)];
                                V(:,jj+1,2*ii) = uq_pair_copula_ccdf1(...
                                    PairCopula{Pair(1),Pair(2)}, Vpair);
                                if ii <= M-jj-2
                                    V(:,jj+1,2*ii+1) = uq_pair_copula_ccdf2(...
                                        PairCopula{Pair(1),Pair(2)}, Vpair);
                                end
                            end
                        end

                        % Set V(:,jj+1,2M-2j-2) = U_M-jj|M-jj+1,...,M
                        Pair =[M-jj M];
                        Vpair = [V(:,jj,2*M-2*jj-1), V(:,jj,2*M-2*jj)];
                        V(:,jj+1,2*M-2*jj-2) = uq_pair_copula_ccdf2(...
                            PairCopula{Pair(1),Pair(2)}, Vpair);
                    end
                end

                FittedCopula = uq_VineCopula(...
                    CopulaType, Structure, families, params, rotations, ...
                    Copula.Truncation, 0);
            end
        else 
            error('Copula of type ''%s'' unknown or not supported yet', ...
                CopulaType);
        end
        
        % ...compute AIC/BIC of the current distribution on data;
        LL_copula(ll) = uq_CopulaLL(FittedCopula, U);
        AIC_copula(ll) = 2 * NrPar - 2 * LL_copula(ll);
        BIC_copula(ll) = log_n * NrPar - 2 * LL_copula(ll);

        S = struct();
        S.LL = LL_copula(ll);
        S.AIC = AIC_copula(ll);
        S.BIC = BIC_copula(ll);
        
        if ~strcmpi(CopulaType, 'Pair')
           GoF.(CopulaType) = S;
        end

        % Define the goodness of fit (GoF) of the current (ll-th)
        % distribution F as either its LL, its AIC, or its BIC; if 
        % lower than the previous lowest value found, select F as the
        % current best-fitting model and continue to the next distrib.
        if strcmpi(SelCriterion, 'ML')
            thisGoF = -LL_copula(ll);
        elseif strcmpi(SelCriterion, 'AIC')
            thisGoF = AIC_copula(ll);
        elseif strcmpi(SelCriterion, 'BIC')
            thisGoF = BIC_copula(ll);
        elseif strcmpi(SelCriterion, 'KS')
            thisGoF = S.KSstat;
        else
            error('Margins(%d).Inference.Criterion wrongly specified')
        end

        if ~isfinite(thisGoF)
            error('something is wrong: GoF is not finite')
        elseif thisGoF < bestGoF
            bestGoF = thisGoF;
            myCopula = FittedCopula;
        end
    end
    
    myCopula.Inference = Copula.Inference;
    myCopula.Variables = Copula.Variables;
end
