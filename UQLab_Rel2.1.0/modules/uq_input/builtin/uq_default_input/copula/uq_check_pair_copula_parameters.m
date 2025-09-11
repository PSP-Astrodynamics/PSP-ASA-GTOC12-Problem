function uq_check_pair_copula_parameters(family, theta, rotation)
% UQ_CHECK_PAIR_COPULA_PARAMETERS(family, theta, rotation)
%     Checks the parameter vector theta is compatible with the given pair 
%     copula family (correct number of parameters, and all parameters lie 
%     in the allowed range). If rotation is provided, also checks that it
%     is one of 0, 90, 180, 270. Raises an error otherwise.
%
% INPUT:
% family : char 
%     The pair copula family (see uq_SupportedPairCopulas)
% theta : array 
%     the pair-copula parameters (for parameter-free copulas, set [])
% (rotation: double, optional)
%     the copula rotation. Can be: 0 (default), 90, 180, 270.
%
% OUTPUT:
% none

if nargin <=2, rotation = 0; end;

I = uq_PairCopulaParameterRange(family);
P = size(I, 1);    % number of parameters of the specified pair copula 
p = length(theta); % number of parameters provided

% Check that the number of parameters is correct
if ~isa(theta, 'double')
    error('parameter vector theta cannot be of type %s', class(theta))
elseif p < P
    error('Copula %s: only %d of %d required parameters provided',...
        family, p, P)
elseif p>P
    error('%d parameters provided. Please specify only %d parameters',p,P)
end

% Check that each parameter is a scalar and falls in its allowed range
for ii=1:p
    par = theta(ii);
    if not(isa(par, 'double')) || not(isreal(par))
        error('theta must be an array of scalars')
    end
    Min = I(ii,1);
    Max = I(ii,2);
    if par < Min || par > Max
        msg = ['Pair copula "' family '": the specified parameter theta', ...
               sprintf('(%d)=%f falls outside the allowed', ii, par), ...
               sprintf(' range [%d,%d]', Min, Max)];
        error(msg)
    end
end

uq_check_pair_copula_rotation(rotation);
