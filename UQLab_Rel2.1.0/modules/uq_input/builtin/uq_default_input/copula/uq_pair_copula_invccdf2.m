function U2 = uq_pair_copula_invccdf2(Copula, U)
% Q = UQ_PAIR_COPULA_INVCCDF2(Copula, U)
%     Given a pair copula and and array U=[u,v] with elements in [0,1],
%     computes the inverse of CCDF2(u|v), the derivative of the pair copula
%     with respect to v, at u.
%
%     For random variables (U1, U2) with copula C and uniform marginals in 
%     [0,1], the inverse of CCDF2 represents the quantile function of U1 
%     given U2. This function is also the "inverse h(.) function" in:
%     Aas, Czado, Frigessi, Bakken: Pair-copula constructions of multiple 
%     dependence. Insurance: Mathematics and Economics, 44(2):182–198,2009,
%     and it can be used for sampling from the specified pair copula.
%
%     NOTE: for pair copulas whose inverse CCDF is not available
%     analytically, a numerical solution is sought, down to a maximum error
%     of 1e-8.
%
% INPUT:
% Copula : struct
%     A structure describing a pair copula (see UQLab's Input manual)
% U : array n-by-2
%     the points in the unit square where to compute the pair copula CDF
%
% OUTPUT:
% Q : array n-by-1
%     the value of the inverse conditional CDF at the specified points
%
% SEE ALSO: uq_pair_copula_ccdf2, uq_pair_copula_invccdf1

family = uq_copula_stdname(Copula.Family); 
theta = Copula.Parameters;
rotation = uq_pair_copula_rotation(Copula);

% Make standard checks
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
n = size(U, 1);

nonAnalytical = {'Gumbel'}; % pair copulas without analytical invCCDF

% Compute inverse CCDF (only for the points where u is not 0 or 1) 
if rotation == 0
    u_is_0 = find(u==0);
    u_is_1 = find(u==1);
    u_not_01 = setdiff(1:n, union(u_is_0, u_is_1));

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
                aux1 = (uu.^(-t/(1+t))-1).*(vv.^(-t));
                aux2 = zeros(size(aux1));
                aux2(aux1>eps) = (1+aux1(aux1>eps)).^(-1/t);
                aux2(aux1<=eps) = 1-aux1(aux1<=eps)/t;
                U2(u_not_01) = aux2; %(aux1+1).^(-1/t);
                % Set special boundary cases (conditioning var = 0 or 1):
                v_is_0 = find(v==0);
                v_is_1 = find(v==1);
                U2(v_is_1) = u(v_is_1).^(1/(1+t)); 
                % Since C1|2(u|v=0) = 1 forall v, C1|2 is not invertible 
                % at v=0. Arbitrarily assign it the value 0 (unless u is 1,
                % in which case leave the already assigned value 1)
                U2(setdiff(v_is_0, u_is_1)) = 0;
            end
        case 'Frank' % see Joe, pp.165-166, with u and v switched and simplified
            e = exp(-t);
            d = (1./uu - 1).*(e.^vv);
            % The invCCDF2 takes the form U2 = -1/t * log(1-(1-e)/(1+d)). 
            % Both e and d can take very small (~0) values. In this case, 
            % compute f(e,d) = 1-(1-e)/(1+d) as (e+d)/(1+d)
            Expr = 1-(1-e)./(1+d);
            if e <= eps
                d_too_small = (d <= eps);
                Expr(d_too_small) = (e+d(d_too_small))./(1+d(d_too_small));
            end
            U2(u_not_01) = -1/t * log(Expr);
        case 'Gaussian' % see Joe, pp. 163 for the CCDF (easy to invert)
            U2(u_not_01) = normcdf(sqrt(1-t^2).*norminv(uu)+t.*norminv(vv));
        case 't'
            % Easily obtained from the CCDF by inversion
            tinv_uu = tinv(uu, t2+1); % inverse of the t- CDF at uu 
            tinv_vv = tinv(vv, t2);   % inverse of the t- CDF at vv
            U2(u_not_01) = tcdf(sqrt((1-t1^2)*(t2+tinv_vv.^2)/(t2+1)) .* ...
                tinv_uu + t1*tinv_vv, t2);
            % Set special boundary cases (conditioning var = 0 or 1):
            v_is_0 = find(v==0); %intersect(find(v==0), u_not_1);
            v_is_1 = find(v==1); %intersect(find(v==1), u_not_1);
            p = tcdf(t1*sqrt(t2+1)/sqrt(1-t1^2), t2);
            U2(v_is_0) = p + (1-p)*(u(v_is_0)==1) ; % mass p at 0, 1-p at 1
            U2(v_is_1) = (1-p) + p*(u(v_is_1)==1) ; % mass 1-p at 0, p at 1
        case nonAnalytical
            nn = length(u_not_01);
            err = 1e-8;
            Left = zeros(nn,1); 
            Right = ones(nn,1);
            
            max_iter = ceil(-log(err)/log(2));

            for iter = 1:max_iter
                U2(u_not_01) = (Left+Right)/2; % next guess: mid of range
                P_new = uq_pair_copula_ccdf2(Copula, [U2(u_not_01), vv]);
                Pnew_islargerthen_P = P_new > uu;
                Pnew_issmallerthen_P = 1 - Pnew_islargerthen_P;
                Left = Left .* Pnew_islargerthen_P + U2(u_not_01) .* Pnew_issmallerthen_P;
                Right = U2(u_not_01) .* Pnew_islargerthen_P + Right .* Pnew_issmallerthen_P;
            end
        otherwise
            error('Pair copula family %s unknown or not supported yet', ...
                family)
    end
    
else
    Copula_rot0 = Copula;
    Copula_rot0.Rotation = 0;
    if rotation == 90
        % C90=v-C(1-u,v), thus dC90(u,v)/dv=1-dC(1-u,v)/dv.
        % One easily obtains: invCCDF2_90(u|v) = 1-invCCDF2(1-u,v);
        U2 = 1 - uq_pair_copula_invccdf2(Copula_rot0, [1-u, v]);
    elseif rotation == 180
        % C180=u+v-1+C(1-u,1-v), thus dC180(u,v)/dv=1-d_v C(1-u,1-v).
        % One easily obtains: invCCDF2_180(u|v) = 1-invCCDF2(1-u,1-v);
        U2 = 1 - uq_pair_copula_invccdf2(Copula_rot0, 1-U);
    elseif rotation == 270
        % C270=u-C(u,1-v), thus dC270(u,v)/dv=d_v C(u,1-v);
        % One easily obtains: invCCDF2_270(u|v) = invCCDF2(u,1-v);
        U2 = uq_pair_copula_invccdf2(Copula_rot0, [u, 1-v]);
    end
end

% Correct small machine errors that lead to values slightly outside [0 1]
U2(U2>1 & U2<=1+eps) = 1;
U2(U2<0 & U2>=-eps) = 0;

if min(U2)<0 || max(U2)>1
    msg = 'Something is wrong: inverse CCDF returned values outside [0,1]';
    error(' for %s copula with parameter(s) %s', ...
        msg, Copula.Type, mat2str(Copula.Parameters))
end
  
