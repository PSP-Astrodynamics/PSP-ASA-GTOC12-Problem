function Results = uq_perturbation_method(current_analysis)
% RESULTS = UQ_PERTURBATION_METHOD(ANALYSISOBJ): 
%     calculate 1st order perturbation-based sensitivity indices based on 
%     the configuration of the analysis object ANALYSISOBJ.
%
% See also: UQ_SENSITIVITY,UQ_INITIALIZE_UQ_SENSITIVITY

%% RETRIEVE THE INPUT OPTIONS
Options = current_analysis.Internal;
% Verbosity (if used)
Display = Options.Display;

% Save the user input:
CurrentInput = Options.Input;
Marginals = CurrentInput.Marginals;

% Total number of variables:
M = length(Marginals);

% Only the variables included in the FactorIndex variable need to be
% calculated. The other variables are set to their mean value
FactorIndex = Options.FactorIndex;
% Set the marginals types of the indices to ignore to constant, with mean
% the corresponding mean value
for ii = find(~FactorIndex)
    Marginals(ii).Type = 'Constant';
    Marginals(ii).Parameters = [Marginals(ii).Moments(1) 0];
    Marginals(ii).Moments(2) = 0;
end
% Input variances and means
MuX = zeros(1, M);
StdX = zeros(1, M);
for ii = 1:M
    MuX(ii) = Marginals(ii).Moments(1);
    StdX(ii) = Marginals(ii).Moments(2);
    
    
end


% Function to be used for gradient evaluation
target_function = @(x) uq_evalModel(Options.Model,x);

%% Numerical calculation of the gradient
[GradMu, M_X, Cost, ExpDesign] = ...
    uq_gradient(MuX,...
    target_function,...
    Options.Gradient.Method,...
    Options.Gradient.Step, ...
    Options.Gradient.h,...
    Marginals);

% Permute the Gradient to be in the format the method needs
GradMu = permute(GradMu,[3,2,1]);

% Gradient squared scaled by the variances
GSsquared = bsxfun(@times, GradMu.^2, StdX.^2);

%% RESULTS ASSEMBLY
% Means
Results.Mu = M_X;
% Variances
Results.Var = sum(GSsquared, 2)';
% Sensitivity indices
Results.Sensitivity = (GSsquared./repmat(Results.Var', 1,size(GSsquared,2)))';
if Options.SaveEvaluations
    % Model evaluations if requested
    Results.ExpDesign = ExpDesign;
end
% Total cost of the method
Results.Cost = Cost;
