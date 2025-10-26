function X = uq_lhs(nsamples, nvar, simple, iterations)
% S = UQ_LHS(NVAR, NSAMPLES) performs latin hypercube sampling of NVAR variables. 
% NSAMPLES samples are collected. Matlab's builtin LHSDESIGN is used if the 
% Statistics_Toolbox license is available, otherwise it is substituted by a simple version.

if ~exist('simple', 'var')
    simple = 0;
end

if ~exist('iterations', 'var')
    iterations = 5;
end
% initialize the output
X = zeros(nsamples, nvar);

if ~simple && (license('checkout', 'Statistics_Toolbox') > 0)
    % use the builtin lhsdesign from MATLAB if available
    X = lhsdesign(nsamples, nvar, 'iterations', iterations);
elseif simple == 1
    % use a simple version of the LHS, based on randomly permuting samples in the 0,1 interval
    R = rand(nsamples, nvar);
    for ii = 1:nvar
        % Permutation index over the number of samples
        idx = randperm(nsamples); 
        % fit each variable in its own "cube"
        X(:,ii) = (idx - R(:,ii))/nsamples;
    end
    
elseif simple == 2
    % simple MATLAB lhsdesign without optimization
    X = lhsdesign(nsamples, nvar, 'criterion', 'none');
end
