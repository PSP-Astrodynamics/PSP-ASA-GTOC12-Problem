function Results = uq_morris_indices(current_analysis)
% RESULTS = UQ_MORRIS_INDICES(ANALYSISOBJ): calculate the Morris'
%     sensitivity indices on the analysis object specified in ANALYSISOBJ.
%
% See also: UQ_SENSITIVITY,UQ_CREATE_MORRIS_TRAJECTORY

%% RETRIEVE ANALYSIS CONFIGURATION
Options = current_analysis.Internal;
% Verbosity level
Display = Options.Display;

% The 'Factors' are filtered out to ignore constant variables:
FactorIndex = Options.FactorIndex;
MNonConst = sum(FactorIndex);
M = length(FactorIndex);
InputVariableIdx = find(FactorIndex);

% Define the grid size of each factor and its perturbation Delta:
GridSize = zeros(1, MNonConst);
Delta = zeros(MNonConst,1);

% Check the pertubation steps
if 2*Options.Morris.PerturbationSteps~=Options.Morris.GridLevels
    fprintf('Warning: The grid levels should be twice the pertubation step!\n');
end

% Extract the boundaries of the Factors to a matrix:
Boundaries = zeros(2, MNonConst);
for ii = 1:length(InputVariableIdx)
    Boundaries(:, ii) = Options.Factors(InputVariableIdx(ii)).Boundaries;
    GridSize(ii) = diff(Boundaries(:, ii))/(Options.Morris.GridLevels - 1);
    Delta(ii) = Options.Morris.PerturbationSteps/(Options.Morris.GridLevels - 1);
end

% Separate the elementary effects by factor:
r = Options.Morris.FactorSamples;

% Generate the r trajectories:
[AllTraj, AllSigns, DerIdx] = uq_create_morris_trajectory(MNonConst, r, Options);

% Resize the trajectories to their actual bounds:
AllTraj = bsxfun(@plus, Boundaries(1, :), bsxfun(@times, AllTraj, GridSize));

% Add the constants in the appropriate places of the trajectory:
tmpAllTraj = zeros(size(AllTraj,1),length(FactorIndex));

% Keep only the FactorIndex factors
idx_allTraj = 1;
for fidx = 1:length(FactorIndex)
    IsFixed = ~FactorIndex(fidx);

    if ~IsFixed
        tmpAllTraj(:,fidx) = AllTraj(:,idx_allTraj);
    else
        tmpAllTraj(:,fidx) = ones(size(AllTraj,1),1)* ...
            current_analysis.Internal.Input.Marginals(fidx).Moments(1);
    end
    
    idx_allTraj = ~IsFixed + idx_allTraj;
end

% Retrieve the trajectories for model evaluation
AllTraj = tmpAllTraj;

if Display > 1
    fprintf('\nMorris: Evaluating model...');
end

% Evaluate the model on the calculated trajectories
M_AllTrajTot = uq_evalModel(Options.Model,AllTraj);

% Check the cost and the number of outputs:
[Cost, NOuts] = size(M_AllTrajTot);

% Initialize the outputs:
Mu = zeros(NOuts, M);
MuStar = zeros(NOuts, M);
STD = zeros(NOuts, M);

helpvec = r*((1:MNonConst) - 1);
DerIdx = helpvec(DerIdx);
DerIdx = bsxfun(@plus, DerIdx, (1:r)');
for oo = 1:NOuts
    M_AllTraj = M_AllTrajTot(:, oo);
    % Map the evaluation points back to the values variable, in such a way that
    % each row contains the necessary evaluations for
    % one elementary effect for every factor (one EE is one column)
    % The reshape is done columnwise and we want it row-wise, therefore we need
    % to transpose the result:
    Values = reshape(M_AllTraj, MNonConst + 1, r)';
    EEffects = AllSigns.*(Values(:,2:end) - Values(:,1:end-1));
    EEffects = EEffects(DerIdx);
    EEffects = bsxfun(@rdivide,EEffects', Delta)';
    
    % Compute the mean and the mean of the absolute value
    Mu(oo, FactorIndex) = sum(EEffects,1)/r;
    MuStar(oo, FactorIndex) = sum(abs(EEffects),1)/r;
    
    % Compute the standard deviation:
    STD(oo, FactorIndex) = ...
        sqrt(sum(bsxfun(@minus, EEffects, Mu(oo, FactorIndex)).^2,1)/(r - 1));
end
if Display > 0
    fprintf('Morris: Finished.\n');
end

%% Assemble the results
Results.Mu = Mu';
Results.MuStar = MuStar';
Results.Std = STD';
Results.Cost = Cost;
if Options.SaveEvaluations
    Results.ExpDesign.X = AllTraj;
    Results.ExpDesign.Y = M_AllTrajTot;
end