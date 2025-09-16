function [theta, rot, LL] = uq_fit_pair_copula(U, family, rotations)
% [theta, rot, LL] = uq_fit_pair_copula(U, family, rotations)
%     Fit the parameter vector theta of a pair copula on bivariate data U.
%     Fitting is performed by likelihood maximization
%
% INPUT: 
% U : array n-by-2
%     n samples from a bivariate random vector with values in [0,1]
% family : char
%     a pair copula family name
% (rotations : array of integers 0,90,180 or 270; optional)
%     rotations of the pair copula to test. The rotation yielding best 
%     fitting is selected. 
%     Default: [0 90 180 270]
%     
% OUTPUT:
% theta : array
%     vector of parameter estimates for the specified pair copula family.
% rot : float
%     The pair copula rotation that yields the largest likelihood
% LL : float
%     Total log-likelihood of the pair copula with estimated parameters
%     on the specified data U

family = uq_copula_stdname(family);

% If no pair copula rotations are specified, try all
if nargin == 2
    rotations = 0:90:270;
end

% If rotations was set to empty, throw error
if isempty(rotations)
    error('uq_fit_pair_copula: specify at least one rotation value')
end

% Remove equivalent rotations (for symmetric copula: remove 180 and 270)
rotations = unique(uq_pair_copula_equivalent_rotation(family, rotations));

% If the copula is independent, nothing needs to be done
if strcmpi(family, 'Independent')
    theta = [];
    rot = 0;
    LL = 0;
    
% If the pair copula is gaussian, rotations have no effect and the
% parameter is the correlation coefficient of the bivariate Gaussian 
% distribution with the same copula and standard normal marginals
elseif strcmpi(family, 'gaussian')
    params = corr(norminv(U));
    params = (params+params')/2;
    theta = params(1,2);
    
    % Constrain theta to be within the allowed range
    ParamsRange = uq_PairCopulaParameterRange(family);
    theta = min(max(theta, ParamsRange(1)), ParamsRange(2));
    
    rot = 0;
    LL = uq_CopulaLL(uq_PairCopula(family, theta, rot), U);
    
% For all other pair copulas, proceed by numerical optimization
else
    % Set range and starting value for parameter optimisation
    ParamsRange = uq_PairCopulaParameterRange(family);
    Lower = reshape(max(ParamsRange(:,1), -50), 1, []);
    Upper = reshape(min(ParamsRange(:,2), +50), 1, []);
    Start = (Lower>=0) .* (0.7*Lower+0.3*Upper) + ...
            (Lower<0).*(Upper>0) .* (.55*Lower+.45*Upper) + ...
            (Upper <=0) .* (0.7*Upper+0.3*Lower);

    % Optimisation involves calculation of log-likelihoods, which are +-Inf
    % or 0 at the borders of the unit hypercube. Avoid this by constraining 
    % values of U within [eps, 1-eps]
    U = min(max(U, eps), 1-eps);
    
    % Optimize for first rotation value provided. The objective function is
    % the negative log-likelihood, here redefined as a function of theta
    rot1 = rotations(1);
    NLLfun = @(theta) -uq_CopulaLL(uq_PairCopula(family, theta, rot1), U);
    
    % Use the BFGS method if the Optim toolbox is available, UQLab builtin
    % CMAES otherwise
    if logical(license('test','optimization_toolbox')) && logical(exist('fmincon','file'))
        opt = optimset('Display', 'off');
        [theta1, NLL1] = fmincon(NLLfun,Start,[],[],[],[],Lower,Upper,[],opt);
    else
        opt.isVectorized = false;
        opt.Display = 'none';
        opt.MaxFunEval = 100;
        [theta1, NLL1] = uq_cmaes(NLLfun,Start,[],Lower,Upper,opt);
    end
    LL1 = -NLL1;
    
    if length(rotations) == 1 % if only one rotation was provided: done!
        LL = LL1;
        rot = rot1;
        theta = theta1;
    else % otherwise, make recursive call for remaining rotation values
        [theta2, rot2, LL2] = uq_fit_pair_copula(U, family, rotations(2:end));
        % Choose the rotation yielding the highest log-likelihood
        if LL1 > LL2
            LL = LL1;
            rot = rot1;
            theta = theta1;
        else
            LL = LL2;
            rot = rot2;
            theta = theta2;
        end     
    end
end

end
