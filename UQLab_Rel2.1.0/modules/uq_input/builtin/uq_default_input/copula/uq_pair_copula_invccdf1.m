function U1 = uq_pair_copula_invccdf1(Copula, U)
% Q = UQ_PAIR_COPULA_INVCCDF1(Copula, U)
%     Computes the inverse of CCDF1(v|u), the derivative of a pair copula 
%     C(u,v) with respect to u, at v.
%
%     For random variables (U1, U2) with copula C and uniform marginals in 
%     [0,1], the inverse of CCDF1 represents the quantile function of U2 
%     given U1. 
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
% SEE ALSO: uq_PairCopulaCDF, uq_PairCopulaPDF, uq_pair_copula_ccdf2

rotation = uq_pair_copula_rotation(Copula);
u = U(:,1);
v = U(:,2);

PCisSymmetric = uq_pair_copula_is_symmetric(Copula.Family);

% Compute inverse CCDF (only for the points where u is not 0 or 1) 
if rotation == 0
    if PCisSymmetric
        U1 = uq_pair_copula_invccdf2(Copula, [v, u]);
    else
        error('InvCCDF1 not supported yet for non-symmetric pair copulas.')
    end
else
    Copula_rot0 = Copula;
    Copula_rot0.Rotation = 0;    
    if rotation == 90
        % C90 is defined as v-C(1-u,v), therefore dC90(u,v)/du=dC(1-u,v)/du;
        % One easily obtains: invCCDF2_90(v|u) = invCCDF2(1-u,v);
        U1 = uq_pair_copula_invccdf1(Copula_rot0, [1-u, v]);
    elseif rotation == 180
        % C180 is defined as u+v-1+C(1-u,1-v)-> dC180(u,v)/dv=1-d_u C(1-u,1-v);
        % One easily obtains: invCCDF2_180(v|u) = 1-invCCDF1(1-u,1-v);
        U1 = 1 - uq_pair_copula_invccdf1(Copula_rot0, 1-U);
    elseif rotation == 270
        % C270 is defined as u-C(u,1-v), therefore dC270(u,v)/du=1-d_u C(u,1-v);
        U1 = 1 - uq_pair_copula_invccdf1(Copula_rot0, [u, 1-v]);
    end
end
