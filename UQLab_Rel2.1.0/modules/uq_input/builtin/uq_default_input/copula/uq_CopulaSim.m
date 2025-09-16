function [U, Z] = uq_CopulaSim(Copula, n, method, LHSiterations)
% [U, Z] = UQ_COPULASIM(Copula, n, method)
%     Generates n observations from a random vector having uniform 
%     marginals in the interval [0,1] and the specified copula. 
%
% INPUT:
% Copula : struct
%     A structure describing a copula (see the UQlab Input Manual)
% n : positive integer
%     Number of observations to generate
% (method: char, optional)
%     Sampling method. Can be 'grid', 'MC', 'LHS', 'simpleLHS', 'Sobol', 
%     'Halton'. See also: uq_sampleU
% (LHSiterations: int, optional)
%     If method='LHS', LHSiterations specifies the number of iterations.
%     Default: 5
%
% OUTPUT:
% U : array n-by-M
%     n observations from the specified M-variate copula model.
% Z : array n-by-M
%     Rosenblatt transform of the points in U. Each row is an
%     observation in [0,1]^M from the M-variate independence copula.
%
% SEE ALSO: uq_invRosenblattTransform

if nargin <= 2, method = 'MC'; end
if nargin <= 3, LHSiterations = 5; end
M = uq_copula_dimension(Copula);

if length(Copula) == 1
    
    Opts.Method = method;
    Opts.LHSiterations = LHSiterations;
    Z = uq_sampleU(n, M, Opts);

    if strcmpi(Copula.Type, 'Independent')
        U = Z;
    elseif any(strcmpi(Copula.Type, {'Gaussian', 'CVine', 'DVine'}))
        U = uq_invRosenblattTransform(Z, uq_StdUniformMarginals(M), Copula);
    elseif M == 2
        U = Z;
        U(:,2) = uq_pair_copula_invccdf1(Copula, Z);
    else
        error('Specified copula unknown or not supported yet')
    end

else % if Copula contains several copulas
    % Initialize U
    U = -ones(n, M);
    for ii = 1:length(Copula)
        U(:, Copula(ii).Variables) = uq_CopulaSim(...
            Copula(ii), n, method, LHSiterations);
    end
end