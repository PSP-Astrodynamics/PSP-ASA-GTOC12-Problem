function [Results] = uq_mc(current_analysis)
% [Results] = UQ_MC(current_analysis) performs a Monte Carlo analysis of 
% "current_analysis" and stores the results on the "Results" struct.
% 
% See also: UQ_EVALLIMITSTATE, UQ_ENRICHSAMPLE


Options = current_analysis.Internal;

Display = Options.Display;

if isfield(Options.Simulation, 'TargetCoV') && ~isempty(Options.Simulation.TargetCoV);
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

%% Start MCS
% Failure counter
TotalFailures = 0;  

% Performed runs counter
CurrentRuns = 0; 

% Number of loops performed
LoopNo = 1; 

% Check if we want to save the evaluation results:
if Options.SaveEvaluations
    SamplePoints = [];
    ModelOutputs = [];
end

% In case the method needs to iterate, the complete sample will be saved
% here:
CompleteSample = [];

% And its evaluations here:
CompleteEvals = [];
CompleteG = [];

%% Start the iterative algorithm
while 1
    if CurrentRuns + SampleSize > MaxSampleSize
        % Decrease the sample size, so CurrentRuns won't exceed.MaxSampleSize:
        SampleSize = MaxSampleSize - CurrentRuns; 
    end
    
    % Get the sample and evaluate it
    if isempty(CompleteSample)
        % It is the first sample we get:
        Sample = uq_getSample(Options.Input,SampleSize, Options.Simulation.Sampling);
        CompleteSample = Sample;
        
    else
        % It needs to be enriched:
        Sample = uq_enrichSample(CompleteSample, SampleSize, Options.Simulation.Sampling, Options.Input);
        
        % Update the sample:
        CompleteSample = [CompleteSample; Sample];
    end
      
        
   if Options.SaveEvaluations     
        [g_X, Y] = uq_evalLimitState(Sample, Options.Model, Options.LimitState, Options.HPC.MC);
        CompleteEvals = [CompleteEvals; Y];
        CompleteG = [CompleteG; g_X];
   else
       [g_X] = uq_evalLimitState(Sample, Options.Model, Options.LimitState, Options.HPC.MC);
   end

   
    % Update the counters:
    TotalFailures = TotalFailures + sum(g_X < 0);
    CurrentRuns = CurrentRuns + SampleSize;
    
    % Estimate the probability and Coeficient of variation
    EstimatePf = TotalFailures/CurrentRuns;
    
    % Variance of the estimator of Pf:
    EstimateVar = EstimatePf.*(1 - EstimatePf)/CurrentRuns;
        
    % Coefficient of variation (equivalent options)
    EstimateCoV = sqrt(EstimateVar)./EstimatePf;
    
    % Estimate the confidence bounds
    EstimateConf = sqrt(EstimateVar)*norminv(1 - Options.Simulation.Alpha/2);
    
    % Save the estimates on the plotting section of the results:
    HistoricPf(LoopNo, :) = EstimatePf;
    HistoricCoV(LoopNo, :) = EstimateCoV;
    HistoricConf(LoopNo, :) = EstimateConf;
    
    % Check if there is a Target CoV and if it is reached
    if CoVThreshold && all(EstimateCoV <= TargetCoV)
        break
    end
    
    %Check whether the maximum number of sample evaluations is reached
    if CurrentRuns >= MaxSampleSize
        if CoVThreshold
            fprintf('\nWarning: Monte Carlo Simulation finished before reaching target coefficient of variation.');
            fprintf('\n         Current : %s', uq_sprintf_mat(EstimateCoV));
            fprintf('\n         Target  : %f', TargetCoV);
            fprintf('\n');
        end
        % Maximum runs reached, exit:
        break   
    else
        
        LoopNo = LoopNo + 1;
        
        if Display > 1
            % Display the basic results of this iteration:
            fprintf('\nMC: Convergence not achieved with %g samples.', CurrentRuns);
            fprintf('\nMC: Current CoV : %e', EstimateCoV)
            fprintf('\nMC: Current Pf  : %e', EstimatePf);
            fprintf('\nMC: Sending batch no %g...\n', LoopNo);
        end
    end
    

end

%% Store the results:
Results.Pf = EstimatePf;
Results.Beta = -norminv(Results.Pf);
Results.CoV = EstimateCoV;
Results.ModelEvaluations(1:length(EstimatePf)) = 0;
Results.ModelEvaluations(1) = CurrentRuns;

Results.PfCI(:, 1) = Results.Pf - EstimateConf;
Results.PfCI(:, 2) = Results.Pf + EstimateConf;
Results.BetaCI(:, 1) = -norminv(Results.PfCI(:,2));
Results.BetaCI(:, 2) = -norminv(Results.PfCI(:,1));

% Save the historical values of probability and coefficient of variation
for oo = 1:size(HistoricPf, 2)
    Results.History(oo).Pf = HistoricPf(:, oo);
    Results.History(oo).CoV = HistoricCoV(:, oo);
    Results.History(oo).Conf = HistoricConf(:, oo);
end

%Save the limit state evaluation results:
 if Options.SaveEvaluations
        Results.History(oo).X = CompleteSample;
        Results.History(oo).G = CompleteG;
 end

if Display > 0
    fprintf('\nMC: Finished.\n ');
end


