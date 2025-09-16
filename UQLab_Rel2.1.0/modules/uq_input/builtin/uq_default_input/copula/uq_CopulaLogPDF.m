function LL = uq_CopulaLogPDF(Copula, U)
% P = uq_CopulaLogPDF(Copula, U)
%     Computes the log-likelihood of the specified copula at each point in
%     the array U of observations in the unit hypercube.
%
% INPUT:
% Copula : struct
%     A structure describing a copula (see the UQlab Input Manual)
% U : array of size n-by-M
%     coordinates of points in the unit hypercube (one row per data point)
%
% OUTPUT:
% P : array n-by-1
%     the value of the natural logarithm of the copula density at the 
%     points in U
%
% SEE ALSO: uq_CopulaPDF, uq_CopulaLL, uq_CopulaAIC

if length(Copula) == 1
    M = uq_copula_dimension(Copula);

    n = size(U, 1);

    if strcmpi(Copula.Type, 'Independent')
        LL = zeros(n,1);

    elseif strcmpi(Copula.Type, 'Gaussian') 
        % Convert U into std normal quantiles X and transpose(size: MxN)
        X = norminv(U)'; 
        R = Copula.Parameters;
        a = R\X - X;
        b = sum(X .* a, 1); % vector of size 1xN
        LL = -1/2 * (log(det(R)) + b)';
        % Special cases: u_i = 0 or u_i=1 -> the copula's ll is +/-inf; take
        % the sign from points  close by in the internal of the unit hypercube
        idx = find(any((U==0) + (U==1), 2));
        if ~isempty(idx)
            e=1e-9; Ue = max(min(U(idx,:), 1-e), e); 
            LL(idx) = inf * sign(uq_CopulaLogPDF(Copula, Ue));
        end
    elseif strcmpi(Copula.Type, 'Pair')    
        family = Copula.Family;
        theta = Copula.Parameters;

        if isfield(Copula, 'Rotation')
            rotation = Copula.Rotation;
        else
            rotation = 0;
        end

        % Define abbreviated variable names
        u = U(:,1);
        v = U(:,2);

        switch length(theta)
            case 1
                t = theta;
            case 2
                t1 = theta(1); t2=theta(2);
            case 3
                t1 = theta(1); t2=theta(2); t3=theta(3);
        end

        % Compute PDF of pair copula
        if rotation == 0
            switch family
                case 'Independent'  
                    LL = zeros(n,1);
                case 'Clayton' 
                    if t < 1e-6   % Independence copula for t->0
                        LL = zeros(n,1); 
                    else
                        % See Joe (book), pp.168, eq 4.10, for the PDF. The 
                        % last line is equivalent to log(u.^-t+v.^-t-1), but 
                        % avoids Inf for u,v~=0 or ~=1.
                        m=min(u,v); M=max(u,v);
                        LL = log(1+t) - (1+t)*(log(u)+log(v)) - (2+1/t)*...
                            (-t*log(m)+log(1+(m./M).^(t)-m.^t));
                        % Limit cases (u==0 or v==0 or both; u,v=1 are OK)
                        LL(all([m==0, M >0],2)) = -inf;
                        LL(all([m==0, M==0],2)) = +inf;
                    end
                case 'Frank' 
                    if abs(t) < 1e-6   % Independence copula for t->0
                        LL = zeros(n,1); 
                    else
                        et = exp(-t);
                        LL = log(t)+log(1-et)-t*(u+v)-2*log((1-et-(1-et.^u).*(1-et.^v)));
                    end
                case 'Gaussian' 
                    if t == 0
                        LL = zeros(n,1);
                    else
                        X = norminv(U)'; 
                        R = [1 t; t 1];
                        a = R\X - X;
                        b = sum(X .* a, 1); % vector of size 1xN
                        LL = -1/2 * (log(det(R)) + b)';
                        LL(all([u==0, v==0],2)) = +inf; % +inf at (0,0)
                        LL(all([u==1, v==1],2)) = +inf; % +inf at (1,1)
                        LL(all([u==0, v==1],2)) = -inf; % +inf at (1,1)
                        LL(all([u==1, v==0],2)) = -inf; % +inf at (1,1)
                        % If u\in{0,1} and 0<v<1 (or viceversa): pdf=0, ll=-inf
                        LL(sum(~isfinite(X),1)==1) = -inf;
                    end
                case 'Gumbel' 
                    if t == 1
                        LL = zeros(n,1);
                    else
                        lu = -log(u);
                        lv = -log(v);
                        s = lu.^t + lv.^t;
                        m=min(lu,lv); M=max(lu,lv); 
                        Mmt = (M./m).^t;
                        logs = t*log(m)+log(1+Mmt); % equiv to log(s)
                        logs(Mmt==inf) = t*log(M(Mmt==inf));
                        LL = -s.^(1/t) + log(s.^(1/t)+t-1) + (1/t-2)*logs ...
                            + (t-1)*(log(lu)+log(lv)) + lu + lv;
                        % Deal with boundary cases (note: the LL is a loglog,
                        % trend is very slow!)...
                        % ...if u=0, 0<v<=1 or viceversa: ll=(1-t)*log(u)->-inf
                        LL(all([lu==inf, lv <inf],2)) = -inf;
                        LL(all([lu <inf, lv==inf],2)) = -inf;
                        % ...if u=0, v=0: ll=-c1*log(u)+c2, c1<0, => ll->+inf
                        LL(all([lu==inf, lv==inf],2)) = +inf;
                        % ...if u=v=1: ll->-log(-log(u))->+inf, pdf->+inf
                        LL(all([u==1, v==1],2)) = +inf; 
                    end
                case 't' 
                    X = tinv(U, t2);
                    X2 = X.^2;
                    % See Joe (book, 2015), pp.181, eq.(4.34) for the pdf,
                    % expressed as const*numer/denom
                    logconst = -1/2 * log(1-t1^2) + gammaln((t2+2)./2) + ...
                        gammaln(t2./2) - 2*gammaln((t2+1)./2);
                    C = 1/(t2*(1-t1^2));
                    if C < 1
                        F = log(1 + C*(sum(X2,2)-2*t1*prod(X,2)));
                    else
                        F = log(C) + log(1/C + sum(X2,2)-2*t1*prod(X,2));
                    end
                    lognumer = -(t2+2)./2 .* F;
                    logdenom = -(t2+1)./2 * sum(log(1 + X2./t2), 2);
                    LL = logconst + lognumer - logdenom;
                    % Solve limit cases u,v={0,1}...
                    % ...if u\in{0,1} and 0<v<1 (or viceversa): pdf=0, ll=-inf
                    LL(sum(~isfinite(X),2)==1) = -inf;
                    % if u\in{0,1} and v\in{0,1}: pdf=+inf, ll=+inf
                    LL(sum(~isfinite(X),2)==2) = +inf;
            end 
        else % if the pair copula is rotated
            u = U(:,1);
            v = U(:,2);
            Copula_rot0 = Copula;
            Copula_rot0.Rotation = 0;
            if rotation == 180
                LL = uq_CopulaLogPDF(Copula_rot0, 1-U);
            elseif rotation == 90
                LL = uq_CopulaLogPDF(Copula_rot0, [1-u, v]);
            elseif rotation == 270
                LL = uq_CopulaLogPDF(Copula_rot0, [u, 1-v]);
            end
        end

    elseif strcmpi(Copula.Type, 'CVine')
        if all(Copula.Structure == 1:M)    
            % Take edges of the vine (for the case: vine structure ~= 1:M) 
            [PairCopulas, Indices, Pairs] = uq_PairCopulasInVine(Copula);
            PairsArray = zeros(length(Pairs), 2); 
            for ll = 1:length(Pairs), 
                PairsArray(ll,:) = Pairs{ll}; 
            end;
            Nr_Pairs = length(PairCopulas);

            % See algo 3 by Aas et al (2009)
            n = size(U, 1);
            LL = zeros(n, 1);
            V = -ones(n, M, M);
            V(:,1,:) = U;  % first for loop in algo 3 by Aas et al (2009)
            for jj = 1:M-1
                for ii = 1:M-jj
                    % Take the Pair Copula between jj and ii
                    Pair =[jj jj+ii];
                    PairCopula = PairCopulas{Indices(find(all(...
                        PairsArray == repmat(Pair, Nr_Pairs, 1), 2)))};

                    % Compute the PDF of that copula on the transformed obs.
                    LL = LL + uq_CopulaLogPDF(PairCopula, ...
                        [V(:,jj,1),V(:,jj,ii+1)]);
                    if jj < M-1
                        V(:,jj+1,ii) = uq_pair_copula_ccdf1(...
                            PairCopula, [V(:,jj,1), V(:,jj,ii+1)]);
                        % Force the transformation to be within (0,1)
                        % (not present in original algorithm by Aas et al)
                        V(:,jj+1,ii) = min(max(V(:,jj+1,ii), eps), 1-eps);
                    end
                end
            end
        else % if the structure of the vine is not 1:M
            UU = U(:, Copula.Structure);
            Copula_SortedStruct = uq_VineCopula(Copula.Type, 1:M, ...
                Copula.Families, Copula.Parameters, Copula.Rotations);
            LL = uq_CopulaLogPDF(Copula_SortedStruct, UU);
        end

    elseif strcmpi(Copula.Type, 'DVine')
        if all(Copula.Structure == 1:M)    
            % Take edges of the vine (for the case: vine structure ~= 1:M) 
            [PairCopulas, Indices, Pairs] = uq_PairCopulasInVine(Copula);
            PairsArray = zeros(length(Pairs), 2); 
            for ll = 1:length(Pairs)
                PairsArray(ll,:) = Pairs{ll}; 
            end
            Nr_Pairs = length(PairCopulas);

            % See algo 4 by Aas et al (2009)
            n = size(U, 1);
            LL = zeros(n, 1);
            V = -ones(n, M, max(M, 2*M-4)); % nr. samples x dim x 2*MaxNrConditioningVars
            V(:,1,1:M) = U;  % first for loop in algo 4 by Aas et al (2009)
            % First tree of the vine: multiply the unconditional PC's PDFs
            % (second for loop in algo 4 by Aas et al (2009))
            for ii = 1:M-1
                Pair = [ii, ii+1];
                PairCopula = PairCopulas{Indices(...
                    find(all(PairsArray == repmat(Pair, Nr_Pairs, 1), 2)))};
                Vpair = [V(:, 1, Pair(1)), V(:, 1, Pair(2))];
                LL = LL + uq_CopulaLogPDF(PairCopula, Vpair);
                if ii==1 % assignment "v(1,1)=... in algo 4 by Aas et al (2009)
                    V(:,2,1) = uq_pair_copula_ccdf2(PairCopula, Vpair);
                end
            end
            % Evaluate conditional CDFs of order 1 wrt both arguments
            % (third for loop and row below it in algo 4 by Aas et al (2009))
            for kk = 1:M-2
                Pair = [kk+1, kk+2];
                PairCopula = PairCopulas{Indices(...
                    find(all(PairsArray == repmat(Pair, Nr_Pairs, 1), 2)))};
                Vpair = [V(:, 1, Pair(1)), V(:, 1, Pair(2))];
                V(:,2,2*kk) = uq_pair_copula_ccdf1(PairCopula, Vpair);
                if kk <= M-3
                    V(:,2,2*kk+1) = uq_pair_copula_ccdf2(PairCopula, Vpair);
                end
            end

            for jj = 2:M-1
                for ii = 1:M-jj
                    % Take the Pair Copula between ii and ii+jj
                    Pair =[ii ii+jj];
                    PairCopula = PairCopulas{Indices(find(all(...
                        PairsArray == repmat(Pair, Nr_Pairs, 1), 2)))};
                    % Compute the PDF of that copula on the transformed obs.
                    Vpair = [V(:, jj, 2*ii-1), V(:, jj, 2*ii)];
                    if any(max(Vpair)>1) || any(min(Vpair)<0)
                        error('ugh')
                    end
                    PCll = uq_CopulaLogPDF(PairCopula, Vpair);
                    LL = LL + PCll;
                end
                if jj == M-1, break; end
                % Take the Pair Copula between ii and ii+jj
                Pair =[1 1+jj];
                PairCopula = PairCopulas{Indices(...
                    find(all(PairsArray == repmat(Pair, Nr_Pairs, 1), 2)))};
                V(:,jj+1,1) = uq_pair_copula_ccdf2(...
                    PairCopula, [V(:,jj,1), V(:,jj,2)]);
                if M > 4,
                    for ii = 1:M-jj-2
                        Pair =[ii+1 ii+jj+1];
                        PairCopula = PairCopulas{Indices(find(all(...
                            PairsArray == repmat(Pair, Nr_Pairs, 1), 2)))};
                        Vpair = [V(:,jj,2*ii+1), V(:,jj,2*ii+2)];
                        V(:,jj+1,2*ii) = uq_pair_copula_ccdf1(PairCopula, Vpair);
                        V(:,jj+1,2*ii+1) = uq_pair_copula_ccdf2(PairCopula, Vpair);
                    end
                end
                Pair =[M-jj M];
                PairCopula = PairCopulas{Indices(find(all(...
                    PairsArray == repmat(Pair, Nr_Pairs, 1), 2)))};
                Vpair = [V(:,jj,2*M-2*jj-1), V(:,jj,2*M-2*jj)];
                V(:,jj+1,2*M-2*jj-2) = uq_pair_copula_ccdf2(PairCopula, Vpair);
            end
        else % if the structure of the vine is not 1:M
            UU = U(:, Copula.Structure);
            Copula_SortedStruct = uq_VineCopula(Copula.Type, 1:M, ...
                Copula.Families, Copula.Parameters, Copula.Rotations);
            LL = uq_CopulaLogPDF(Copula_SortedStruct, UU);
        end
    else
        error('Copula of type ''%s'' unknown or not supported yet',Copula.Type)
    end
    
else % if multiple copulas, sum their individual LL values
    LL = 0;
    for ll = 1:length(Copula)
        Cop = Copula(ll);
        UU = U(:, Cop.Variables);
        LL = LL + uq_CopulaLogPDF(Cop, UU);
    end
end

% Numerical instability may cause the log-pdf at points inside the unit 
% hypercube to be +/-inf, instead of +/- very_large_value. Set those to 
% log(realmax) instead.
idx_inf = isinf(LL);
idx_int = all([U>0, U<1], 2);
idx_to_cap = all([idx_inf, idx_int], 2);
LL(idx_to_cap) = sign(LL(idx_to_cap)) .* log(realmax); 
