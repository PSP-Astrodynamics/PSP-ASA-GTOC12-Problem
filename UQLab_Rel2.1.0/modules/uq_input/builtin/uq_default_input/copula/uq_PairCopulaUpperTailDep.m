function lambdaU = uq_PairCopulaUpperTailDep(Copula)
% lambdaU = UQ_PAIRCOPULAUPPERTAILDEP(Copula)
%     Returns the asymptotic upper tail dependence coefficient of the 
%     specified pair copula, if known as a function of the copula 
%     parameter(s). Raises an error otherwise.
%
% INPUT:
% Copula : struct
%     A structure describing a pair copula (see UQLab's Input manual)
%
% OUTPUT:
% lambdaU : double
%    asymptotic upper tail dependence coefficient of the pair copula.
%
% SEE ALSO: uq_PairCopulaLowerTailDep

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

% Compute lambdaU for the various cases
if rotation == 0
    switch family 
        case 'BB1'
            lambdaU = 2-2^(1/t1);
        case 'BB6'
            lambdaU = 2-2^(1/(t1*t2));
        case 'BB7' 
            lambdaU = 2^-(1/t2);
        case 'Gumbel'
            lambdaU = 2-2^(1/t);
        case {'Joe', 'B5'}
            lambdaU = 2-2^(1/t);
        case 'Tawn1' 
            lambdaU = 1+t3-(1+t3^t1)^(1/t1);
        case 'Tawn2' 
            lambdaU = 1+t2-(1+t2^t1)^(1/t1);   
        case 'Tawn'
            lambdaU = t2+t3-(t2^t1+t3^t1)^(1/t1);
        case {'t', 'Student'}
            lambdaU = 2*tcdf(-sqrt((t2+1)*(1-t1)/(1+t1)), t2+1);
        case {'Independent', 'AMH', 'AsymFGM', 'FGM', 'BB6', 'BB8', 'Frank', ...
              'Gaussian', 'Clayton', 'IteratedFGM', ...
              'PartialFrank', 'Plackett'}
            lambdaU = 0;
        otherwise
            errmsg = 'lambdaU not available analytically for copula family';
            error('%s "%s" (id %d)', errmsg, family)
    end
elseif rotation == 90 || rotation == 270
    lambdaU = 0;
elseif rotation == 180
    Copula_rot0 = Copula;
    Copula_rot0.Rotation = 0;
    lambdaU = uq_PairCopulaLowerTailDep(Copula_rot0);
end
