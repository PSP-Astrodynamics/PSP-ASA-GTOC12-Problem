function tauK = uq_PairCopulaKendallTau(Copula)
% tauK = UQ_PAIRCOPULAKENDALLTAU(Copula)
%     Returns the Kendall's tau of the specified pair copula, if known 
%     as a function of the parameter(s) theta.
%     Raises an error otherwise.
%
% INPUT:
% Copula : struct
%     A structure describing a pair copula (see UQLab's Input manual)
%
% OUTPUT:
% tauK : double
%    Kendall's tau of the pair copula.

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

% Compute tauK for the various cases
switch family 
    case 'Independent'
        tauK = 0;
    case 'AMH'   
        if t == 1 
            tauK = 0;  % limit of the expression below for t->1
        else
            tauK = 1-(2*t+2*(1-t)^2*log(1-t))/(3*t^2);
        end
    case 'AsymFGM'
        tauK = t/18;
    case 'BB1'
        tauK = 1-2/(t1*(t2+2));
    case 'Clayton'
        tauK = t/(t+2);
    case 'FGM'
        tauK = 2*t/9;
    case 'Frank'
        Integrand = @(s) s.*(exp(s)-1).^-1;
        tauK = 1+ 4/t * (1/t * integral(Integrand, 0, t) - 1);
    case 'Gaussian'
        tauK = 2/pi * asin(t);
    case 'Gumbel'
        tauK = (t-1)/t;
    case 'IteratedFGM'
        tauK = 2*t1/9 + (25+t1)*t2/450;
    case {'Joe', 'B5'}
        tauK = 1 + 2/(2-t)*(psi(2)-psi(2/t+1));
    case {'t', 'Student'}
        tauK = 2/pi * asin(t1);
    otherwise
        errmsg = 'tauK not known analytically for copula family';
        error('%s "%s" (id %d)', errmsg, PCname, PCid)
end   

if any(rotation == [90, 270])
    tauK = -tauK;
elseif ~any(rotation == [0, 180]) 
    error('Pair Copula with rotation %d not supported', rotation);
end
