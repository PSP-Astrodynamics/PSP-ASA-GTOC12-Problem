function results = uq_cotter_indices(current_analysis)
% RESULTS = UQ_COTTER_INDICES(ANALYSISOBJ): Calculate the Cotter sensitivity
% indices using the options specified in the analysis object ANALYSISOBJ
%
% See also: UQ_SENSITIVITY

%% RETRIEVE THE OPTIONS
Options = current_analysis.Internal;

% Verbosity level
Display = Options.Display;

% Factor indices (do not include factors that are not in the index)
FactorIndex = Options.FactorIndex;

% Factors
Factors = Options.Factors;

% Check the problem dimension:
M = length(Factors);
% Effective dimension (factoring in the desired factors only)
MNonConst = sum(FactorIndex);
% Initialize the base points:
LowPoint = zeros(1, M);
HighPoint = zeros(1, M);

% Get the factor boundaries
for ii = 1:M
    if FactorIndex(ii)
        LowPoint(ii) = Factors(ii).Boundaries(1);
        HighPoint(ii) = Factors(ii).Boundaries(2);
    else % use the midpoint between boundaries for uninteresting parameters
        LowPoint(ii) = mean(Factors(ii).Boundaries);
        HighPoint(ii) = mean(Factors(ii).Boundaries);
    end
end

% Get the ranges
PointDiff = HighPoint - LowPoint;
% Ignore the factors that are not used
PointDiff = PointDiff(FactorIndex);
PointDiffMat = diag(PointDiff);

% This is the matrix that contains all the points at a low level, switching
% one to its high level at a time (the first column is the vector with all
% factors at its low level)
LowLevels = repmat(LowPoint, MNonConst + 1, 1);
LowLevels(2:end, FactorIndex) = LowLevels(2:end, FactorIndex) + PointDiffMat;

% Now the same, but for high levels
HighLevels = repmat(HighPoint, MNonConst + 1, 1);
HighLevels(1:end - 1, FactorIndex) = HighLevels(1:end - 1, FactorIndex) - PointDiffMat;
if Display > 1
    fprintf('\Cotter: Evaluating model...');
end

% Evaluate everything in a vectorized operation
M_y = uq_evalModel(Options.Model,[LowLevels; HighLevels]);


% Check the cost and the number of outputs
[Cost, NOuts] = size(M_y);

%% CALCULATE THE COTTER INDICES

% Preallocation
CotterIdx = zeros(M, NOuts);
EvenOrderEffect = zeros(M, NOuts);
OddOrderEffect = zeros(M, NOuts);

for oo = 1:NOuts % Loop over the outputs
    % initialize active factors index
    aidx = 0;
    for ii = 1:M % Loop over the factors
        if FactorIndex(ii) % Only update active factors
            % increase the active factors index
            aidx = aidx + 1;
            % Odd order effects
            OddOrderEffect(ii, oo) = ((M_y(end, oo) - M_y(MNonConst + 1 + aidx, oo)) + ...
                (M_y(aidx + 1, oo) - M_y(1, oo)))/4;
        
            EvenOrderEffect(ii, oo) =((M_y(end, oo) - M_y(MNonConst + 1 + aidx, oo)) - ...
                (M_y(aidx + 1, oo) - M_y(1, oo)))/4;
            
            CotterIdx(ii, oo) = abs(EvenOrderEffect(ii, oo)) + abs(OddOrderEffect(ii, oo));
        end
    end
    

end

%% STORE THE RESULTS
results.CotterIndices = CotterIdx;
results.EvenOrder = EvenOrderEffect;
results.OddOrder = OddOrderEffect;
if Options.SaveEvaluations
    results.ExpDesign.X = [LowLevels, HighLevels];
    results.ExpDesign.Y = M_y;
end
results.Cost = Cost;

if Display > 0
    fprintf('Cotter: Finished.\n');
end
