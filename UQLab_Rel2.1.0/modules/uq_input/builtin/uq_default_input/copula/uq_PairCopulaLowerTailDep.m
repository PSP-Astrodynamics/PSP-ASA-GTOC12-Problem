function lambdaL = uq_PairCopulaLowerTailDep(Copula)
% tau = UQ_PAIRCOPULALOWERTAILDEP(Copula)
%     Returns the asymptotic lower tail dependence coefficient of the 
%     specified pair copula, if known as a function of the copula 
%     parameter(s). Raises an error otherwise.
%
% INPUT:
% Copula : struct
%     A structure describing a pair copula (see UQLab's Input manual)
%
% OUTPUT:
% lambdaL : double
%    asymptotic lower tail dependence coefficient of the pair copula.
%
% SEE ALSO: uq_PairCopulaUpperTailDep

family = uq_copula_stdname(Copula.Family);
theta = Copula.Parameters;
rotation = uq_pair_copula_rotation(Copula);
uq_check_pair_copula_parameters(family, theta, rotation);

% Shorten the name of theta(i) for convenience
if length(theta) == 1
    t = theta;
elseif length(theta) == 2
    t1 = theta(1); t2 = theta(2);
elseif length(theta) == 3
    t1 = theta(1); t2 = theta(2); t3 = theta(3);
end

if rotation == 0
    % Compute lambdaL for the various cases
    switch family 
        case 'AMH'   
            lambdaL = 0.5 * (t==1);  % 0.5 if theta==1, 0 otherwise
        case 'BB1'
            lambdaL = 2^-(1/(t1*t2));
        case 'BB7' 
            lambdaL = 2^-(1/t1);
        case 'Clayton'
            lambdaL = 2^(-1/t);
        case {'t', 'Student'}
            lambdaL = 2*tcdf(-sqrt((t2+1)*(1-t1)/(1+t1)), t2+1);
        case {'Independent', 'AsymFGM', 'FGM', 'BB6', 'BB8', 'Frank', ...
              'Gaussian', 'Gumbel', 'IteratedFGM', 'Joe', 'B5', ...
              'PartialFrank', 'Plackett', 'Tawn1', 'Tawn2', 'Tawn'}
            lambdaL = 0;
        otherwise
            errmsg = 'lambdaL not available analytically for copula family';
            error('%s "%s"', errmsg, family)
    end    
elseif rotation == 90 || rotation == 270
    lambdaL = 0;
elseif rotation == 180
    Copula_rot0 = Copula;
    Copula_rot0.Rotation = 0;
    lambdaL = uq_PairCopulaUpperTailDep(Copula_rot0);
end
