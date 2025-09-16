function [Results] = uq_linesampling(current_analysis)
% RESULTS = uq_linesampling(current_analysis) performs a line sampling
%     analysis of "current_analysis" and stores the results on the 
%     "Results" struct.
% 
% See also: uq_bayesianlinesampling, uq_linesampling_initialDirection, 
% uq_linesamplinglineProcessing

Options = current_analysis.Internal;

% Keep track of constant marginals:
nonConst = ~ismember(lower({Options.Input.Marginals.Type}),'constant');

% Sampling in the SNS
for kk = 1:length(nonConst)
    if nonConst(kk)
        IOpts.Marginals(kk).Type = 'Gaussian';
        IOpts.Marginals(kk).Parameters = [0,1];
    else
        IOpts.Marginals(kk).Type = 'constant';
        IOpts.Marginals(kk).Parameters = 1;
    end
end

Options.UInput = uq_createInput(IOpts, '-private');

if isfield(Options.Simulation, 'TargetCoV') && ~isempty(Options.Simulation.TargetCoV)
    % The method will stop when TargetCoV is reached
    CoVThreshold = true; 
    TargetCoV = Options.Simulation.TargetCoV;
    
else
    % Do not check CoV convergence
    CoVThreshold = false; 
end

% The maximum number of model evaluations
MaxSampleSize = Options.Simulation.MaxSampleSize;

% Number of samples that is evaluated at once
SampleSize = Options.Simulation.BatchSize;

%% Find important direction
DirectionTotal = uq_linesampling_initialDirection(Options);

%% Loop over number of outputs
NOut = DirectionTotal.NOut;

for oo = 1:NOut
%% Generate Samples and Determine the Distance
LoopNo = 1;

% Performed runs counter
CurrentSample = 0; 

% In case the method needs to iterate:
Distances = [];
FunctionCalls = [];
DirectionHistory = [];
ImportantDirection = [];
InitialDistance = [];
U = [];
X = [];
G = [];
LineData.ImportantDirection = [];
LineData.Hyperplane = [];
LineData.Intersects = [];

% Direction
Direction.ImportantDirection = DirectionTotal.ImportantDirection(oo,:);
Direction.InitialDistance = DirectionTotal.InitialDistance(oo);
Direction.Calls = DirectionTotal.Calls;
Direction.NOut = DirectionTotal.NOut;

while true

    if CurrentSample + SampleSize > MaxSampleSize
        % Decrease the sample size, so CurrentRuns won't exceed MaxSampleSize:
        SampleSize = MaxSampleSize - CurrentSample; 
    end
    
    % Generate Samples in Orthorgonal Hyperplane
    if LoopNo == 1
        % Sample in standard normal space
        SampleU{LoopNo} = uq_getSample(Options.UInput, SampleSize, 'mc');
    else
        % Enrich samples
        SampleU{LoopNo} = uq_enrichSample(cell2mat(SampleU'),...
            SampleSize, 'mc', Options.UInput);
    end
    
    % Determine distances of the generated lines to the limit state
    % Process the lines by proximity as proposed by de Angelis et al.
    Roots = uq_linesampling_lineProcessing(Direction, Options,...
        SampleU{LoopNo}, LoopNo, oo);

    ImportantDirection = [ImportantDirection; Direction.ImportantDirection];
    InitialDistance = [InitialDistance; Roots.InitialDistance];

    % Store points of on hyperplane and intersects of each batch
    LineData.ImportantDirection = [LineData.ImportantDirection; Roots.ImportantDirection];
    LineData.Hyperplane = [LineData.Hyperplane; Roots.HyplerplaneSample];
    LineData.Intersects = [LineData.Intersects; Roots.Intersects];

    % Update important direction if new was calculated
    if isfield(Roots, "Direction")
        Direction = Roots.Direction;
        DirectionHistory = [DirectionHistory; Roots.Direction.History];
    end
    
    % Update counter and data sets
    Distances = [Distances; Roots.Distances];
    FunctionCalls = [FunctionCalls; Roots.Calls];
    CurrentSample = CurrentSample + SampleSize;
    U = [U; Roots.U];
    X = [X; Roots.X];
    G = [G; Roots.G];
    
    if Options.LS.Direction.Adaptive && SampleSize > 1
        % Calculate Pf and Var[Pf] using CLS weights as proposed in
        % Papaioannou, I., & Straub, D. (2021). Combination line sampling 
        % for structural reliability analysis. Structural Safety, 88, 
        % 102025. https://doi.org/10.1016/j.strusafe.2020.102025

        % Determine when important direction is updated
        [~,Idx] = unique(LineData.ImportantDirection,'stable','rows');
        extended_idx = [Idx; length(LineData.ImportantDirection)+1];
        NumDir = diff(extended_idx);
        
        % Weights according to eq. (20)
        Weights = NumDir .* normcdf(-InitialDistance(Idx)) / ...
            sum(NumDir .* normcdf(-InitialDistance(Idx)));
        
        extended_idx(end) = extended_idx(end)-1;
        EstimatePfDir = zeros(length(Idx),1);
        EstimateVarDir = zeros(length(Idx),1);
        
        % Estimate the probability, eq.(12)
        for k = 1:length(Idx)
            EstimatePfDir(k) = mean(normcdf(-Distances(extended_idx(k):extended_idx(k+1))));
            EstimateVarDir(k) = var(normcdf(-Distances(extended_idx(k):extended_idx(k+1))))/NumDir(k);
        end
        EstimatePf = sum(Weights .* EstimatePfDir);

        % Variance of the estimator of Pf, eq. (14)
        EstimateVar = sum(Weights.^2 .* EstimateVarDir);

    else
        % Estimate the probability
        EstimatePf = mean(normcdf(-Distances));

        % Variance of the estimator of Pf
        EstimateVar = var(normcdf(-Distances))/length(Distances);
    end
        
    % Coefficient of variation
    EstimateCoV = sqrt(EstimateVar)./EstimatePf;
    
    % Estimate the confidence bounds
    alpha = Options.Simulation.Alpha;
    EstimateConf = sqrt(EstimateVar)*norminv(1 - alpha/2);
    
    % Save the estimates on the plotting section of the results:
    HistoricPf(LoopNo, :) = EstimatePf;
    HistoricCoV(LoopNo, :) = EstimateCoV;
    HistoricConf(LoopNo, :) = EstimateConf;
    HistoricCalls(LoopNo, :) = sum(Roots.Calls);
    HistoricLines(LoopNo, :) = CurrentSample;
    
    % Check if there is a Target CoV and if it is reached
    if CoVThreshold && all(EstimateCoV <= TargetCoV)
        break
    end

    %Check whether the maximum number of sample evaluations is reached
    if CurrentSample >= MaxSampleSize
        if CoVThreshold && Options.Display > 0
            fprintf('\nWarning: Line Sampling finished before reaching target coefficient of variation.');
            fprintf('\n         Current : %f', EstimateCoV);
            fprintf('\n         Target  : %f', TargetCoV);
            fprintf('\n');
        end
        % Maximum runs reached, exit:
        break   
    else
        
        LoopNo = LoopNo + 1;
        
        if Options.Display > 1
            % Display the basic results of this iteration:
            fprintf('\nLS: Convergence not achieved with %g samples.', CurrentSample);
            fprintf('\nLS: Current CoV : %e', EstimateCoV)
            fprintf('\nLS: Current Pf  : %e', EstimatePf);
            fprintf('\nLS: Sending batch no %g...\n', LoopNo);
        end
    end

end

%% Store the results:
Results.Pf(oo) = EstimatePf;
Results.Beta(oo) = abs(norminv(EstimatePf));
Results.CoV(oo) = EstimateCoV;
Results.ModelEvaluations(oo) = sum(FunctionCalls) + Direction.Calls;
Results.Lines(oo) = CurrentSample;

Results.PfCI(oo, 1) = EstimatePf - EstimateConf;
Results.PfCI(oo, 2) = EstimatePf + EstimateConf;
Results.BetaCI(oo, 1) = abs(norminv(Results.PfCI(oo,2)));
Results.BetaCI(oo, 2) = abs(norminv(Results.PfCI(oo,1)));

% Save the important direction
Results.ImportantDirection(oo,:) = Direction.ImportantDirection;

% Save the historical values of probability and coefficient of variation
for ii = 1:size(HistoricPf, 2)
    Results.History(oo).Pf = HistoricPf(:, ii);
    Results.History(oo).CoV = HistoricCoV(:, ii);
    Results.History(oo).Conf = HistoricConf(:, ii);
    Results.History(oo).NLines = HistoricLines(:, ii);
    Results.History(oo).NCalls = cumsum(HistoricCalls(:, ii));
end

% Save the samples and intersects
 if Options.SaveEvaluations
    Results.History(oo).LineData = LineData;
    Results.History(oo).U = U;
    Results.History(oo).X = X;
    Results.History(oo).G = G;
 end

end

if Options.Display > 0
    fprintf('\nLS: Finished.\n');
end

end