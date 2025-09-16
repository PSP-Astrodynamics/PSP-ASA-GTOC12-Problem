function U1 = uq_pair_copula_ccdf1(Copula, U)
% P = UQ_PAIR_COPULA_CCDF1(Copula, U)
%     Computes the derivative of the specified pair copula wrt the first
%     argument. For random variables (U1, U2) with that copula and uniform
%     marginals in [0,1], this corresponds to the conditional CDF of U2
%     given U1.
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

u = U(:,1);
v = U(:,2);

PCisSymmetric = uq_pair_copula_is_symmetric(family);

% Compute CCDF
if rotation == 0
    if  PCisSymmetric 
        U1 = uq_pair_copula_ccdf2(Copula, [v, u]);
    else
        error('CCDF1 not implemented yet for asymmetric copulas')
    end
else
    Copula_rot0 = Copula;
    Copula_rot0.Rotation = 0;
    if rotation == 90
        % C90 is defined as v-C(1-u,v), therefore dC90(u,v)/du=dC(1-u,v)/dv;
        U1 = uq_pair_copula_ccdf1(Copula_rot0, [1-u, v]);
    elseif rotation == 180
        % C180 is defined as u+v-1+C(1-u,1-v), therefore dC180(u,v)/du =
        % = 1 + dC(1-u,1-v)/d(1-v) * d(1-u)/du = 1 - d_u C(1-u,1-v);
        U1 = 1 - uq_pair_copula_ccdf1(Copula_rot0, 1-U);
    elseif rotation == 270
        % C270 is defined as u-C(u,1-v), therefore dC270(u,v)/du=1-d_u C(u,1-v);
        U1 = 1 - uq_pair_copula_ccdf1(Copula_rot0, [u, 1-v]);
    end
end
