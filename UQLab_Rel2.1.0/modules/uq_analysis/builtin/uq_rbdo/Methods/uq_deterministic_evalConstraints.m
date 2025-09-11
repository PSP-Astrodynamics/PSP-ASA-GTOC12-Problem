function g_X = uq_deterministic_evalConstraints(d, current_analysis)

Options = current_analysis.Internal ;

if isfield(Options.Input,'EnvVar') && ...
        ~isempty(Options.Input.EnvVar)
    % If some environmetal variables are defined, use their mean value for
    % deterministic optimization
    Z = zeros(1,length(Options.Input.EnvVar)) ;
    for jj = 1:length(Options.Input.EnvVar)
        Z(jj) = Options.Input.EnvVar(jj).Moments(1) ;
    end
    X = [d, Z] ;
else
    X = d ;
end
% Evaluate the model at X (design and/or environmental variables mean
% values)
% s = rng ;
% rng(Options.Runtime.rng) ;
M_X = uq_evalModel(Options.Constraints.Model, X) ;
% rng(s) ;
% Limit-state options
LSOptions = Options.Optim.LimitState ;
TH = LSOptions.Threshold ;
% Get the limit-state function value at X
switch LSOptions.CompOp
    case {'<', '<=', 'leq'}
        g_X  = M_X  - repmat(TH,size(M_X,1),1);
    case {'>', '>=', 'geq'}
        g_X  = repmat(TH,size(M_X,1),1) - M_X;
end
end