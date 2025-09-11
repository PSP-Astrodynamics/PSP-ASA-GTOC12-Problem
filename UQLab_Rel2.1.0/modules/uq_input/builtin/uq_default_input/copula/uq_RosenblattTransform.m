function Z = uq_RosenblattTransform(X, Marginals, Copula)
% Z = UQ_ROSENBLATTTRANSFORM(X, Marginals, Copula)
%      Computes the Rosenblatt transform Z of the points in the sample set
%      U, having the specified marginals and copula, into the standard 
%      uniform space (uniform marginals in [0,1], independence copula).
%
%      * For a multivariate Gaussian copula, the Nataf transform in used;
%      * For a pair copula, Z=(U_1, U_2|1);
%      * For a vine copula with structure 1:M, the canonical conditioning 
%        order proposed in [1] is used. Thus: Z=(U_1, U_2|1, ...);
%      * For a vine copula with structure {i1, ..., iM}: 
%        Z_i1 = U_i1, Z_i2 = U_i2|i1, etc.
%
% INPUT:
% X : array of size n-by-M
%     observations of points in the unit hypercube (one row per data point)
% Marginals : struct
%     Structure describing the M marginal distributions of X
% Copula : struct
%     A structure describing the M-variate copula of X 
%
% OUTPUT:
% Z : array of size n-by-M
%     the Rosenblatt-transformed points of X
%
% SEE ALSO: uq_NatafTransform, uq_invRosenblattTransform,
%           uq_generalIsopTransform

% Raise error if input vector contains nans
if any(isnan(X(:)))
    error('attempting to perform Rosenblatt transform of data X with nans.')
end

[n, M] = size(X);
idNonConst = find(~strcmpi({Marginals.Type}, 'constant'));
idConst = setdiff(1:M, idNonConst);

% Raise error if there are any non-constant marginals (inverse
% Rosenblatt not defined in this case!)
if ~isempty(idConst)
    msg = 'Rosenblatt transform for constant marginals';
    error('%s %s is not well defined', msg, mat2str(idConst))
end

% Initialize Z (for efficiency)
Z = zeros(n, M);


if length(Copula) == 1
    StdCopulaType = uq_copula_stdname(Copula.Type);
    
    % First transform X into U with standard uniform marginals
    StdUnifMargs = uq_StdUniformMarginals(M);
    U = uq_IsopTransform(X, Marginals, StdUnifMargs);

    % Then perform Rosenblatt transformation based on the specified copula
    if strcmpi(StdCopulaType, 'Independent')
        Z = U;

    elseif strcmpi(StdCopulaType, 'Gaussian')
        % Replace zeros in U with eps^2 and ones with 1-eps to avoid 
        % numerical errors; then use Nataf transform
        Z = 0.5*ones(n, M);
                
        % Restrict attention to non-constant marginals
        UU = U(:, idNonConst);   % Z values associated to non-constant marginals
        MM = length(idNonConst); % Number of non-constant marginals

        % Replace 0s/1s in UU with eps^2/1-eps to avoid numerical errors
        Ueps = min(max(UU, eps^2), 1-eps);
        % Transform UU having standard uniform marginals SUM and Gaussian copula
        % CC into ZZ with independent standard normal marginals
        CC.Type = 'Gaussian';  % Copula between non-constant marginals in UU
        if uq_isnonemptyfield(Copula, 'Parameters')
            CC.Parameters = Copula.Parameters(idNonConst, idNonConst);
        end
        if uq_isnonemptyfield(Copula, 'RankCorr')
            CC.RankCorr = Copula.RankCorr(idNonConst, idNonConst);
        end
        if uq_isnonemptyfield(Copula, 'cholR')
            CC.cholR = Copula.cholR(idNonConst, idNonConst);
        end
        ZZ = uq_NatafTransform(Ueps, uq_StdUniformMarginals(MM), CC);
        % Transform the marginals of ZZ into standard uniform ones
        ZZ = uq_all_cdf(ZZ, uq_StdNormalMarginals(MM));
        ZZ(UU==0) = 0; 
        ZZ(UU==1) = 1;
        Z(:, idNonConst) = ZZ;

    elseif M == 2
        Z = zeros(n, 2);
        Z(:, 1) = U(:,1);
        Z(:, 2) = uq_pair_copula_ccdf1(Copula, U);

    elseif M > 2 && strcmpi(StdCopulaType, 'CVine')
        if all(Copula.Structure == 1:M)
            % Compute the Rosenblatt transform as in Aas et al (2009, algo. 6), 
            % which relies on the simplifying assumption for vine copulas
            [PairCopulas, Indices, Pairs] = uq_PairCopulasInVine(Copula);
            PairsArray = []; 
            for ll = 1:length(Pairs), PairsArray(ll,:) = Pairs{ll}; end;
            Nr_Pairs = length(PairCopulas);

            Z(:,1) = U(:,1); 
            for ii = 2:M
                Z(:, ii) = U(:, ii);
                for jj = 1:(ii-1)                
                    Pair = [jj ii];
                    PCidx = Indices(...
                        find(all(PairsArray == repmat(Pair, Nr_Pairs, 1), 2)));
                    PairCopula = PairCopulas{PCidx};
                    Z(:, ii) = uq_pair_copula_ccdf1(PairCopula, Z(:, Pair));
                end
            end
        else
            UU = U(:, Copula.Structure);
            Copula_SortedStruct = uq_VineCopula(StdCopulaType, 1:M, ...
                Copula.Families, Copula.Parameters, Copula.Rotations);
            Z = uq_RosenblattTransform(UU, StdUnifMargs, Copula_SortedStruct);
            Z(:, Copula.Structure) = Z;
        end        

    elseif M > 2 && strcmpi(StdCopulaType, 'DVine')
        if all(Copula.Structure == 1:M)
            % Compute Rosenblatt transform as in Aas et al (2009, algorithm 6), 
            % which relies on the simplifying assumption for vine copulas
            [PairCopulas, Indices, Pairs] = uq_PairCopulasInVine(Copula);
            PairsArray = []; 
            for ll = 1:length(Pairs), PairsArray(ll,:) = Pairs{ll}; end;

            % Define function that select the pair copula among the given vars
            Nr_Pairs = length(PairCopulas);
            findPC = @(pair) PairCopulas{Indices(...
                find(all(PairsArray == repmat(pair, Nr_Pairs, 1), 2)))};

            V = zeros(n, M-1, 2*M-4); 

            Pair = [1 2]; PairCopula = findPC(Pair); 
            Z(:,1) = U(:,1); 
            Z(:,2) = uq_pair_copula_ccdf1(PairCopula, U(:, Pair));
            V(:,2,1) = U(:,2);
            V(:,2,2) = uq_pair_copula_ccdf2(PairCopula, U(:, Pair));

            for ii = 3:M
                Pair = [ii-1 ii]; PairCopula = findPC(Pair); 
                Z(:,ii) = uq_pair_copula_ccdf1(PairCopula, U(:, Pair));
                for jj = 2:(ii-1)
                    Pair = [ii-jj ii]; PairCopula = findPC(Pair); 
                    Z(:,ii) = uq_pair_copula_ccdf1(PairCopula, ...
                        [V(:, ii-1, 2*(jj-1)), Z(:,ii)]);
                end
                if ii == M, break; end
                V(:,ii,1) = U(:,ii);
                Pair = [ii-1 ii]; PairCopula = findPC(Pair); 
                V(:,ii,2) = uq_pair_copula_ccdf2(PairCopula, ...
                    [V(:,ii-1,1), V(:,ii,1)]);
                V(:,ii,3) = uq_pair_copula_ccdf1(PairCopula, ...
                    [V(:,ii-1,1), V(:,ii,1)]);
                for jj = 1:(ii-3)
                    Pair = [ii-jj-1 ii]; PairCopula = findPC(Pair); 
                    V(:,ii,2*jj+2) = uq_pair_copula_ccdf2(PairCopula, ...
                        [V(:,ii-1,2*jj), V(:,ii,2*jj+1)]);
                    V(:,ii,2*jj+3) = uq_pair_copula_ccdf1(PairCopula, ...
                        [V(:,ii-1,2*jj), V(:,ii,2*jj+1)]);
                end
                V(:,ii,2*ii-2) = uq_pair_copula_ccdf2(PairCopula, ... 
                    [V(:,ii-1,2*ii-4), V(:,ii,2*ii-3)]);
            end
        else
            UU = U(:, Copula.Structure);
            Copula_SortedStruct = uq_VineCopula(StdCopulaType, 1:M, ...
                Copula.Families, Copula.Parameters, Copula.Rotations);
            Z = uq_RosenblattTransform(UU, StdUnifMargs, Copula_SortedStruct);
            Z(:, Copula.Structure) = Z;
        end        

    else
        error('Rosenblatt transform of %s copula unknown or not supported yet', ...
            Copula.Type);
    end

else
    for cc = 1:length(Copula)
        Vars = Copula(cc).Variables;
        x = X(:, Vars);
        Margs = Marginals(Vars);
        Cop = Copula(cc);
        Z(:, Vars) = uq_RosenblattTransform(x, Margs, Cop);
    end
end

if any(isnan(Z(:)))
    error('Rosenblatt transform of nans-free data X contains nans. Error somewhere?')
end

