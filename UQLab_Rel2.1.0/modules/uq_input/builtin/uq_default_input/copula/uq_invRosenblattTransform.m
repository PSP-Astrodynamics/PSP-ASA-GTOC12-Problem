function X = uq_invRosenblattTransform(Z, Marginals, Copula)
% X = UQ_INVROSENBLATTTRANSFORM(Z, Marginals, Copula)
%      Computes the inverse Rosenblatt transform X of the points in Z
%      from the standard uniform space to the probability space with the
%      specified marginals and copula. If Z has uniform marginals in [0,1] 
%      and independent components, X has the specified marginals and copula
%
% INPUT:
% Z : array of size n-by-M
%     coordinates of points in the unit hypercube (one row per data point)
% Marginals : struct
%     Structure describing the M marginal distributions desired for X
% Copula : struct
%     A structure describing the copula of X (see the UQlab Input Manual)
%
% OUTPUT:
% X : array of size n-by-M
%     the inverse-Rosenblatt transformed points of Z. 
%
% SEE ALSO: uq_invNatafTransform, uq_RosenblattTransform

% Raise error if input vector contains nans
if any(isnan(Z(:)))
    error('attempting to perform inverse Rosenblatt transform of data Z with nans.')
end

[n, M] = size(Z);
idNonConst = find(~strcmpi({Marginals.Type}, 'constant'));
idConst = setdiff(1:M, idNonConst);

% Raise error if there are any non-constant marginals (inverse
% Rosenblatt not defined in this case!)
if ~isempty(idConst)
    msg = 'inverse Rosenblatt transform for constant marginals';
    error('%s %s is not well defined', msg, mat2str(idConst))
end

% Initialize X (for efficiency)
X = zeros([n, M]);


if length(Copula) == 1
    uq_check_data_dimension(Z, M);
    StdCopulaType = uq_copula_stdname(Copula.Type);

    % Transform Z, which is taken to have independent standard uniform marginals,
    % into U with standard uniform marginals and specified copula
    
    if strcmpi(StdCopulaType, 'Independent')
        X = uq_IsopTransform(Z, uq_StdUniformMarginals(M), Marginals);
        
    elseif strcmpi(StdCopulaType, 'Gaussian')
        Zeps = min(max(Z, eps), 1-eps);
        U = uq_all_invcdf(Zeps, uq_StdNormalMarginals(M)); 
        U = uq_invNatafTransform(U, uq_StdUniformMarginals(M), Copula);
        U(Z==0) = 0; 
        U(Z==1) = 1;
        X = uq_IsopTransform(U, uq_StdUniformMarginals(M), Marginals);
        
    elseif M == 2
        U = Z;
        U(:,2) = uq_pair_copula_invccdf1(Copula, Z);
        % Transform U with U([0,1]) marginals into X with wanted marginals
        X = uq_IsopTransform(U, uq_StdUniformMarginals(M), Marginals);

        
    elseif M > 2 && strcmpi(StdCopulaType, 'CVine')
        if all(Copula.Structure == 1:M)
            % Compute the inverse Rosenblatt transform as in Aas et al (2009), 
            % algo 1, which relies on the simplifying assumption for vines        
            U(:,1) = Z(:,1); 
            V = zeros(n, M, M); 
            V(:, 1, 1) = Z(:, 1);

            [PairCopulas, Indices, Pairs] = uq_PairCopulasInVine(Copula);
            PairsArray = []; 
            for ll = 1:length(Pairs), PairsArray(ll,:) = Pairs{ll}; end;
            Nr_Pairs = length(PairCopulas);

            for ii = 2:M
                V(:,ii,1) = Z(:,ii);
                for kk = ii-1:-1:1
                    Pair = [kk ii];
                    PairCopula = PairCopulas{Indices(find(all(...
                        PairsArray == repmat(Pair, Nr_Pairs, 1), 2)))};
                    V(:,ii,1) = uq_pair_copula_invccdf1(...
                        PairCopula, [V(:,kk,kk), V(:,ii,1)]);
                end
                U(:,ii) = V(:,ii,1);
                if ii == M 
                    break;
                end
                for jj = 1:ii-1
                    Pair = [jj,ii];
                    PairCopula = PairCopulas{(find(all(...
                        PairsArray == repmat(Pair, Nr_Pairs, 1), 2)))};
                    V(:,ii,jj+1) = uq_pair_copula_ccdf1(...
                        PairCopula, [V(:,jj,jj), V(:,ii,jj)]);
                end
            end
        else % if the structure of the vine is not 1:M
            ZZ = Z(:, Copula.Structure);
            Copula_SortedStruct = uq_VineCopula(StdCopulaType, 1:M, ...
                Copula.Families, Copula.Parameters, Copula.Rotations);
            U = uq_invRosenblattTransform(...
                ZZ, uq_StdUniformMarginals(M), Copula_SortedStruct);
            U(:, Copula.Structure) = U;
        end
               
        % Transform U with U([0,1]) marginals into X with wanted marginals
        X = uq_IsopTransform(U, uq_StdUniformMarginals(M), Marginals);
        
    elseif M > 2 && strcmpi(StdCopulaType, 'DVine')
        if all(Copula.Structure == 1:M)
            % Compute the inverse Rosenblatt transform as in Aas et al (2009), 
            % algo 2, which relies on the simplifying assumption for vines
            % Extract all pair copulas in the vine
            [PairCopulas, Indices, Pairs] = uq_PairCopulasInVine(Copula);
            PairsArray = []; 
            for ll = 1:length(Pairs), PairsArray(ll,:) = Pairs{ll}; end;
            Nr_Pairs = length(PairCopulas);

            % Define function that selects the pair copula among the given vars
            findPC = @(pair) PairCopulas{Indices(...
                find(all(PairsArray == repmat(pair, Nr_Pairs, 1), 2)))};

            V = zeros(n, M, 2*M-2); 
            U(:,1) = Z(:,1); 
            V(:,1,1) = Z(:,1);

            Pair = [1 2]; PairCopula = findPC(Pair);
            U(:,2) = uq_pair_copula_invccdf1(PairCopula, [V(:,1,1), Z(:,2)]);
            V(:,2,1) = U(:,2);

            V(:,2,2) = uq_pair_copula_ccdf2(PairCopula, [V(:,1,1), V(:,2,1)]);

            for ii = 3:M
                V(:,ii,1) = Z(:,ii);
                for kk = ii-1:-1:2
                    Pair = [ii-kk ii]; PairCopula = findPC(Pair);
                    V(:,ii,1) = uq_pair_copula_invccdf1(PairCopula, ...
                        [V(:,ii-1,2*kk-2), V(:,ii,1)]);
                end

                Pair = [ii-1 ii]; PairCopula = findPC(Pair);
                V(:,ii,1) = uq_pair_copula_invccdf1(PairCopula, ...
                    [V(:, ii-1,1), V(:, ii,1)]);
                U(:,ii) = V(:,ii,1);
                if ii == M, break; end
                V(:,ii,2) = uq_pair_copula_ccdf2(PairCopula, ...
                    [V(:, ii-1,1), V(:, ii,1)]);
                V(:,ii,3) = uq_pair_copula_ccdf1(PairCopula, ...
                    [V(:, ii-1,1), V(:, ii,1)]);

                if ii > 3
                    for jj = 2:ii-2
                        Pair = [ii-jj ii]; PairCopula = findPC(Pair);
                        V(:,ii,2*jj) = uq_pair_copula_ccdf2(PairCopula, ...
                            [V(:, ii-1,2*jj-2), V(:, ii,2*jj-1)]);
                        V(:,ii,2*jj+1) = uq_pair_copula_ccdf1(PairCopula, ...
                            [V(:, ii-1,2*jj-2), V(:, ii,2*jj-1)]);
                    end
                end

                Pair = [1 ii]; PairCopula = findPC(Pair);
                V(:,ii,2*ii-2) = uq_pair_copula_ccdf2(PairCopula, ...
                            [V(:, ii-1,2*ii-4), V(:, ii,2*ii-3)]);
            end    
        else % if the structure of the vine is not 1:M
            ZZ = Z(:, Copula.Structure);
            Copula_SortedStruct = uq_VineCopula(StdCopulaType, 1:M, ...
                Copula.Families, Copula.Parameters, Copula.Rotations);
            U = uq_invRosenblattTransform(...
                ZZ, uq_StdUniformMarginals(M), Copula_SortedStruct);
            U(:, Copula.Structure) = U;
        end
        
        % Transform U with U([0,1]) marginals into X with wanted marginals
        X = uq_IsopTransform(U, uq_StdUniformMarginals(M), Marginals);
        
    else
        error('Copula of type %s unknown or not supported yet', Copula.Type);
    end

else
    for cc = 1:length(Copula)
        Vars = Copula(cc).Variables;
        z = Z(:, Vars);
        Margs = Marginals(Vars);
        Cop = Copula(cc);
        X(:, Vars) = uq_invRosenblattTransform(z, Margs, Cop);
    end
end

if any(isnan(X(:)))
    error('Rosenblatt transform of nans-free data Z contains nans. Error somewhere?')
end

