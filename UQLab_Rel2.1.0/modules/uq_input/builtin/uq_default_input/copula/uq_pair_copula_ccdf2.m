function U2 = uq_pair_copula_ccdf2(Copula, U)
% P = UQ_PAIRCOPULACCDF2(Copula, U)
%     Computes the derivative of the specified pair copula wrt the second
%     argument. For random variables (U1, U2) with that copula and uniform
%     marginals in [0,1], this corresponds to the conditional CDF of U1
%     given U2. This function is also the "h(.) function" in [1].
%
% INPUT:
% Copula : struct
%     A structure describing a pair copula (see UQLab's Input manual)
% U : array n-by-2
%     the points in the unit square where to compute the pair copula CDF
%
% OUTPUT:
% P : array n-by-1
%     the value of the conditional copula CDF at the specified points
%
% SEE ALSO: uq_PairCopulaCDF, uq_PairCopulaPDF, uq_pair_copula_invccdf2;
%
% References:
% [1] Aas, Czado, Frigessi, Bakken: Pair-copula constructions of multiple 
%     dependence. Insurance: Mathematics and Economics, 44(2):182–198,2009.

% Make standard checks

M = uq_copula_dimension(Copula);
if M > 2
    error('Copula must have dimension 2, not %d', M)
end

if strcmpi(Copula.Type, 'Independent')
    family = 'Independent';
    theta = [];
    rotation = 0;
else
    family = Copula.Family;
    theta = Copula.Parameters;
    rotation = uq_pair_copula_rotation(Copula);
end

% uq_check_data_in_unit_hypercube(U);
% uq_check_pair_copula_family_supported(family);
% uq_check_pair_copula_parameters(family, theta);
% uq_check_data_dimension(U, 2);

% Shorten the name of theta(i) for convenience
if length(theta) == 1
    t = theta;
elseif length(theta) == 2
    t1 = theta(1); t2 = theta(2);
elseif length(theta) == 3
    t1 = theta(1); t2 = theta(2); t3 = theta(3);
end

u = U(:,1);
v = U(:,2);

% Compute CCDF (only for the points where u is not 0 or 1) 
if rotation == 0
    n = size(U, 1);
    u_is_0 = find(u==0);
    u_is_1 = find(u==1);
    u_not_01 = setdiff(setdiff(1:n, u_is_0), u_is_1);

    % Initialize U2: 0 where u=0, 1 where u=1;
    uu = u(u_not_01);
    vv = v(u_not_01);
    U2 = zeros(n, 1);
    U2(u_is_1) = 1;

    switch family
        case 'Independent'
            U2(u_not_01) = U(u_not_01, 1);
        case 'Clayton' % see Joe, pp.168, with u and v switched
            if t == 0  % Independence case
                U2(u_not_01) = U(u_not_01, 1); 
            else       % Other cases (t>0)
                % the CCDF is of the type (1+h)^k. When h is positive but 
                % very small (0<h<eps), 1+h is set to 1. If 1e-20<h<=eps, 
                % set the CCDF to 1-eps instead.
                h = (vv.^t) .* (uu.^(-t)-1);
                tmp = zeros(size(h));
                tmp(h>eps) = (1+h(h>eps)).^(-1-1/t); % exact formula
                eps2 = 1e-20;
                tmp(eps2<h & h<=eps) = 1-eps;
                tmp(h<=eps2) = 1;
                U2(u_not_01) = tmp;
                % Set special boundary cases (conditioning var = 0 or 1):
                v_is_0 = find(v==0);
                v_is_1 = find(v==1);
                U2(v_is_0) = 1; % degenerate at 0: C_1|2(u|v=0)=1, 0<=u<=1
                U2(v_is_1) = u(v_is_1).^(1+t); 
            end
        case 'Frank' % see Joe, pp.165-166, with u and v switched, and simplified
            et = exp(-t);
            etu = et.^u; etuu = etu(u_not_01);
            etv = et.^v; etvv = etv(u_not_01);
            U2(u_not_01) = etvv.*(etuu-1)./(etuu.*etvv-etuu-etvv+et);
            % Set special boundary cases (conditioning var = 0)
            v_is_0 = find(v==0);
            v_is_1 = find(v==1);
            U2(v_is_0) = (1-etu(v_is_0))./(1-et);
            U2(v_is_1) = (1./etu(v_is_1)-1)/(1/et -1);
        case 'Gaussian'
            U2(u_not_01) = normcdf((norminv(uu)-t*norminv(vv))/sqrt(1-t^2));
            % Set special boundary cases (conditioning var = 0)
            v_is_0 = find(v==0);
            if t > 0 
                U2(v_is_0) = 1; % degenerate at 0
            elseif t < 0
                U2(v_is_0) = (u(v_is_0) == 1); % degenerate at 1
            end
        case 'Gumbel' % see Joe, pp.172, with u and v switched
            if t == 1  % Independence case
                U2(u_not_01) = U(u_not_01, 1); 
            else       % Other cases (t>1)
                U2tmp = zeros(size(uu));
                x = -log(uu); xt = x.^t;
                y = -log(vv); yt = y.^t;
                % The analytical expression of the CCDF is of the type 
                % h = h2*h3, where h2=h0/v and h3=(1+h1)^r may be in 
                % [1-eps,1) and be rounded to 1 due to limited machine 
                % precision. These cases are handled separately.
                h0 = exp(-(xt+yt).^(1/t)); delta = h0-vv; 
                h1 = xt./yt;
                r = (1/t-1);
                h0bad = find(abs(delta) < eps); 
                h0ok = find(abs(delta) >= eps);
                h1bad = find(abs(xt./yt) < eps); 
                h1ok = find(abs(xt./yt) >= eps);
                % case 1: all fine, none of the "bad conditions" occurs
                case1 = intersect(h0ok, h1ok);
                U2tmp(case1) = h0(case1)./vv(case1) .* (1+h1(case1)).^r;
                % case2: only h2=h0/v problematic: write it as 1+delta/v
                % and distribute it: h = delta*h3/v + h3
                case2 = intersect(h0bad, h1ok);
                h3 = (1+h1(case2)).^r;
                U2tmp(case2) = delta(case2) .* h3 ./ vv(case2) + h3;
                % case3: only h3=(1+h1)^r problematic: approx it as 1+r*h1
                % and distribute it: h = h2 + r*h1*h2
                case3 = intersect(h0ok, h1bad);
                h2 = h0(case3) ./ v(case3);
                U2tmp(case3) = r.* h1(case3) .* h2 + h2;
                % case4: both h2=h0/v and h3=(1+h1)^r problematic: write
                % h2=delta/v+1, h3=r*h1+1 -> h=r*xt*h1/v/yt+xt/v/yt+r*h1+1
                case4 = intersect(h0bad, h1bad);
                U2tmp(case4) = delta(case4)./v(case4) + ...
                            r./v(case4).*xt(case4).*h1(case4)./yt(case4)+...
                            r*h1(case4) + 1;
                % The function h below is the analytical CCDF. For some
                % values of u and v, machine errors may lead to values of h
                % <0 or >1; constrain the values in the interval [0,1].
                % h = exp(-(xt+yt).^(1/t))./vv .* (1+xt./yt).^(1/t-1);
                U2(u_not_01) = min(max(U2tmp, 0), 1);
                % Set special boundary cases (conditioning var = 0 or 1):
                v_is_0 = find(v==0);
                v_is_1 = find(v==1);
                U2(v_is_0) = 1; % degenerate at 0: C_1|2(u|v=0) = 1, 0<=u<=1
                U2(v_is_1) = (u(v_is_1)==1); % degenerate at 1
            end
        case 't'
            if t1 == 0  % Independence case
                U2(u_not_01) = U(u_not_01, 1); 
            else       % Other cases (t>0)
                % The CCDF equals tcdf(K*A/B, t2+1), where K, A, B are 
                % defined below
                tinv_uu = tinv(uu, t2); % inverse of the t- CDF at uu 
                tinv_vv = tinv(vv, t2); % inverse of the t- CDF at vv
                A = (tinv_uu -  t1 * tinv_vv);
                B = sqrt(t2 + tinv_vv.^2);
                K = sqrt((t2+1)/(1-t1^2));                
                KAB = K*A./B;
                % In some cases (when A and or B are nan; indicated as 
                % case not1), K*A/B is nan. Deal with these cases below
                not1 = find(isnan(KAB));           % cases: K*A/B = nan
                % K*A/B is nan if and only if tinv_vv = +/- inf. If so, 
                % the expression for K*A/B simplifies to 
                % K*A/B = K * (tinv_uu/|tinv_vv| - t1*sign(tinv_vv)),  (1)
                % which, for |tinv_uu|<inf, further simplifies to
                % K*A/B = - K * t1* sign(tinv_vv)                      (2)
                case2 = find(abs(tinv_uu)<+Inf);     % cases: |tinv_uu|<inf
                not1and2 = intersect(not1, case2); 
                KAB(not1and2) = -K*t1*sign(tinv_vv(not1and2));
                % If both |tinv_uu=inf| and |tinv_vv|=inf, and uu=vv, then
                % K*A/B=0.
                not2 = setdiff(1:length(uu), case2); % cases: |tinv_uu|=inf
                not1not2 = intersect(not1, not2);
                case3 = (uu==vv);                    % cases: uu=vv
                not1not2and3 = intersect(not1not2, case3);
                KAB(not1not2and3) = K*(1-t1)*sign(tinv_vv(not1not2and3));
                % Final case: |tinv_uu=inf|, |tinv_vv|=inf, uu not= vv.
                % Noting that, for uu<<1 and vv<<1, 
                %      tinv_uu/tinv_vv ~= (vv/uu)^(1/nu)
                % and for generic uu, vv (also close to 1), 
                %        tinv_uu = -tinv(min(uu,1-uu)) * sign(uu-0.5),
                %      |tinv_vv| = -tinv(min(vv,1-vv)),
                % one obtains
                %      tinv_uu / |tinv_vv| = sign(uu-0.5) * ...
                %          tinv(min(uu,1-uu)) / tinv(min(vv,1-vv)) ~=
                %          sign(uu-0.5) * (vv/uu)^(1/nu);
                not3 = setdiff(1:length(uu), case3); % cases: uu not= vv
                not1not2not3 = intersect(not1not2, not3);
                uuu = uu(not1not2not3);
                vvv = vv(not1not2not3);
                
                Ratio = (uuu>.5) .* ...
                    (min(vvv,1-vvv)./min(uuu,1-uuu)).^(1/t2);
                KAB(not1not2not3) = K * (Ratio - ...
                    t1*sign(tinv_vv(not1not2not3)));
                
                U2(u_not_01) = tcdf(KAB, t2+1);

                % Set special boundary cases (conditioning var = 0 or 1):
                v_is_0 = find(v==0);
                v_is_1 = find(v==1);
                p = tcdf(t1*sqrt(t2+1)/sqrt(1-t1^2), t2+1);
                U2(v_is_0) = p + (1-p)*(u(v_is_0)==1) ; % mass p at 0, 1-p at 1
                U2(v_is_1) = (1-p) + p*(u(v_is_1)==1) ; % mass 1-p at 0, p at 1
            end
        otherwise
            error('CCDF2 not implemented yet for %s copula', family)
    end
    
else
    Copula_rot0 = Copula;
    Copula_rot0.Rotation = 0;
    if rotation == 90
        % C90 is defined as v-C(1-u,v), therefore dC90(u,v)/dv=1-dC(1-u,v)/dv;
        U2 = 1 - uq_pair_copula_ccdf2(Copula_rot0, [1-u, v]);
    elseif rotation == 180
        % C180 is defined as u+v-1+C(1-u,1-v), therefore dC180(u,v)/dv=
        % = 1 + dC(1-u,1-v)/d(1-v) * d(1-v)/dv = 1 - d_v C(1-u,1-v);
        U2 = 1 - uq_pair_copula_ccdf2(Copula_rot0, 1-U);
    elseif rotation == 270
        % C270 is defined as u-C(u,1-v), therefore dC270(u,v)/dv=d_v C(u,1-v);
        U2 = uq_pair_copula_ccdf2(Copula_rot0, [u, 1-v]);
    end
end

% Correct small machine errors that lead to values slightly outside [0 1]
U2(U2>1 & U2<=1+eps) = 1;
U2(U2<0 & U2>=-eps) = 0;
  
