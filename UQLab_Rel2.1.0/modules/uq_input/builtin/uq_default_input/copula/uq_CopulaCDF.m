function P = uq_CopulaCDF(Copula, U)
% P = UQ_COPULALL(Copula, U)
%     Computes the CDF of the specified copula at each point in U.
%
% INPUT:
% Copula : struct
%     A structure describing a copula (see the UQlab Input Manual)
% U : array of size n-by-M
%     coordinates of points in the unit hypercube (one row per data point)
%
% OUTPUT:
% P : array n-by-1
%     the value of the copula CDF at the points in U
%
% SEE ALSO: uq_CopulaPDF

uq_check_copula_is_defined(Copula);
uq_check_data_in_unit_hypercube(U);
M = uq_copula_dimension(Copula);
uq_check_data_dimension(U, M)

StdCopulaType = uq_copula_stdname(Copula.Type);
if strcmpi(StdCopulaType, 'Independent')
    P = prod(U,2);
    
elseif strcmpi(StdCopulaType, 'Pair')
    family = Copula.Family;
    theta = Copula.Parameters;
    rotation = Copula.Rotation;

    % Make standard checks
    uq_check_pair_copula_family_supported(family);
    uq_check_pair_copula_parameters(family, theta);

    % Define abbreviated variable names and 
    n = size(U, 1);
    P = zeros(n, 1);
    uv_both_1 = find(all(U==1, 2));
    P(uv_both_1) = 1;
    
    uv_not_0 = find(U(:,1) .* U(:,2) > 0);
    uv_not_1 = setdiff(1:n, uv_both_1);  
    uv_not_both0or1 = intersect(uv_not_0, uv_not_1);
    if not(isempty(uv_not_both0or1))
        UU = U(uv_not_both0or1,:);
        uu = UU(:,1);
        vv = UU(:,2);

        if rotation == 0
            % Define abbreviated parameter names for convenience
            switch length(theta)
                case 1
                    t = theta;
                case 2
                    t1 = theta(1); t2=theta(2);
                case 3
                    t1 = theta(1); t2=theta(2); t3=theta(3);
            end

            switch uq_copula_stdname(family)
                case 'Upper'
                    PP = min(UU, [], 2);
                case 'Lower'
                    PP = max([uu+vv-1, zeros(n,1)], [], 2);
                case 'Independent'  % Independence (0)
                    PP = prod(UU,2);
                case 'Clayton' % Clayton (7)
                    PP = (sum(UU.^-t, 2) -1).^-(1/t);
                case 'Frank' % Frank (9)
                    if abs(t) < 1e-6   % Independence copula for t->0
                        PP = prod(UU,2); 
                    else
                        et = exp(-t);
                        PP = -1/t * log((1-et-(1-et.^uu).*(1-et.^vv))/(1-et));
                    end
                case 'Gaussian' % Gaussian (10)
                    PP = mvncdf(norminv(UU), zeros(1,M), [1 t; t 1]);
                case 'Gumbel' % Gumbel (11)
                    min_uu_vv = min([uu,vv], [], 2);
                    max_uu_vv = uu+vv-min_uu_vv;
                    PP = min_uu_vv .^ ((1+(log(max_uu_vv)./log(min_uu_vv)).^t).^(1/t));
                    PP(vv==1) = uu(vv==1);
                    PP(uu==1) = vv(uu==1);
                case 't' % t (19)
                    PP = mvtcdf(tinv(UU,t2), [1 t1; t1 1], t2);
                otherwise
                    error('not implemented yet for %s pair copula', ...
                        Copula.Family)
            end   
        else
            Copula_rot0 = Copula;
            Copula_rot0.Rotation = 0;
            if rotation == 180
                PP = uu + vv - 1 + uq_CopulaCDF(Copula_rot0, 1-UU);
            elseif rotation == 90
                PP = vv - uq_CopulaCDF(Copula_rot0, [1-uu, vv]); % flipping
                % PP = u - uq_CopulaCDF(Copula_rot0, [1-v, u]); % rotation
                % PP = v - uq_CopulaCDF(Copula_rot0, [v, 1-u]); % (clockwise rotation)
            elseif rotation == 270
                PP = uu - uq_CopulaCDF(Copula_rot0, [uu, 1-vv]); % flipping
                % PP = v- uq_CopulaCDF(Copula_rot0, [v, 1-u]); % rotation
                % PP = u - uq_CopulaCDF(Copula_rot0, [1-v, u]); % (clockwise rotation)
            end
        
            % Check that the provided CDF is in [-eps, 1+eps] (tolerate
            % small machine errors)
            if any(PP<-eps) || any(PP>1+eps)
                errmsg = 'badly defined: values outside [0 1]';
                error('CDF of %s pair copula %s', Copula.Family, errmsg)
            end
            
            % Fix machine errors: set pair copula CDF to exactly 1 when 
            % both arguments are 1, and enforce Frechet bounds.
            PP(all([uu==1, vv==1], 2)) = 1;
            Min = max(sum(UU,2)-1, 0); Max = min(UU,[],2);
            PP = max(PP,Min); PP = min(PP, Max);
        end    
        P(uv_not_both0or1) = PP;
    end
    
elseif strcmpi(StdCopulaType, 'Gaussian') 
    if ~isfield(Copula, 'Parameters')
        Copula.Parameters = 2*sin(pi*Copula.RankCorr/6);
    end
    P = mvncdf(norminv(U), zeros(1,M), Copula.Parameters);
    
elseif any(strcmpi(StdCopulaType, {'CVine', 'DVine'}))
    errmsg = 'CDF of vine copulas not available analytically!';
    error('%s Need numerical integration of the PDF.', errmsg);
end
