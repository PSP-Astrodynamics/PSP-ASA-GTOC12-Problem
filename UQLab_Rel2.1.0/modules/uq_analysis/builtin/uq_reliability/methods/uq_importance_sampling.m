function [Results, Internal] = uq_importance_sampling(LimitStateFcn, SourceInput, InstrumentalInput, Options)
% UQ_IMPORTANCE_SAMPLING conducts an importance sampling analysis based on
% an instrumental density and a limit state function
%
% See also: UQ_SR_IMPORTANCE_SAMPLING

% Now, select the instrumental input, for sampling during the method:
%SourceMarginals = SourceInput.Marginals;
%SourceCopula = SourceInput.Copula;

if ~isfield(Options, 'Display') || ~isnumeric(Options.Display)
    [~, Options] = uq_initialize_display(Options, Options);
end
Display = Options.Display;

if nargin < 4
    Options.Display = 1;
    Options.Simulation.MaxSampleSize = 1e4;
    Options.Simulation.BatchSize = 1e3;
    Options.Simulation.Alpha = 0.05;
end


%% Get the input options 
SimOpts = Options.Simulation;
MaxSampleSize = SimOpts.MaxSampleSize;
SampleSize = SimOpts.BatchSize;
Alpha = SimOpts.Alpha;

% Save evaluations or not:
if isfield(Options, 'SaveEvaluations');
    switch 1
        case islogical(Options.SaveEvaluations) || isnumeric(Options.SaveEvaluations)
            % These are both fine
        case ischar(Options.SaveEvaluations)
            % Parse the string:
            switch lower(Options.SaveEvaluations)
                case {'yes', 'true'}
                    Options.SaveEvaluations = true;
            end
        otherwise
            Options.SaveEvaluations = false;
    end
else
    Options.SaveEvaluations = false;
end

% If there is no sampling strategy provided, stick to Monte Carlo:
if ~isfield(SimOpts, 'Sampling') || ~ischar(SimOpts.Sampling);
    SimOpts.Sampling = 'mc';
end

if isfield(SimOpts, 'TargetCoV') && ~isempty(SimOpts.TargetCoV);
    % The method will stop when TargetCoV is reached
    CoVThreshold = true; 
    TargetCoV = SimOpts.TargetCoV;
    
else
    % Do not check CoV convergence
    CoVThreshold = false; 
    
end


%% START IMPORTANCE SAMPLING:
% Initialize the sum of the probability estimator
SumY = 0; 

% Initialize the sum of the variance estimator
Ysquare = 0;

% Failure counter
TotalFailures = 0;

% Performed runs counter
CurrentRuns = 0; 

% Number of loops performed
LoopNo = 1;

% In case the method needs to iterate, the complete sample will be saved
% here:
CompleteSample = [];

% And its evaluations here:
CompleteEvals = [];

while 1
    if CurrentRuns + SampleSize > MaxSampleSize
        % Decrease the sample size, so CurrentRuns won't exceed.MaxSampleSize:
        SampleSize = MaxSampleSize - CurrentRuns; 
    end
    
    % Get the sample and evaluate it
    if isempty(CompleteSample)
        % It is the first sample we get:
        InstrumentalChunk = uq_getSample(InstrumentalInput,SampleSize, SimOpts.Sampling);
        CompleteSample = InstrumentalChunk;
        
    else
        % It needs to be enriched:
        InstrumentalChunk = uq_enrichSample(CompleteSample, SampleSize, SimOpts.Sampling, InstrumentalInput);     
        
        % Update the sample:
        CompleteSample = [CompleteSample; InstrumentalChunk];
    end
    
    
    % Evaluate the limit state function
    Evals = LimitStateFcn(InstrumentalChunk);

    if isfield(Options, 'Output')
        Evals = Evals(:, Options.Output);
    end
    Index =  Evals <= 0;
    
    % Save these evaluations:
    if Options.SaveEvaluations
        CompleteEvals = [CompleteEvals; Evals];
    end
        
    % Check the failures:
    FailureChunk = InstrumentalChunk(Index, :);
    
    % Update the counters:
    TotalFailures = TotalFailures + sum(Index);
    CurrentRuns = CurrentRuns + SampleSize;
    
    % Update the partial terms of the estimators (uq_evalLogPDF will take
    % into account the copula if it is defined)
    UpperTerms_log = uq_evalLogPDF(...
        FailureChunk, SourceInput);
    
    LowerTerms_log = uq_evalLogPDF(...
        FailureChunk, InstrumentalInput);
    
    YTerms = exp(UpperTerms_log - LowerTerms_log);
    SumY = SumY + sum(YTerms);
    Ysquare = Ysquare + sum(YTerms.^2);
    
    % Update the current estimators:
    EstimatePf = (1/CurrentRuns)*SumY;
    
    % Variance of the estimator of Pf:
    EstimateVar = 1/((CurrentRuns - 1)*CurrentRuns)*(Ysquare + CurrentRuns*EstimatePf^2 - 2*EstimatePf*SumY);
    
    % Coefficient of variation:
    EstimateCoV = sqrt(EstimateVar)/EstimatePf;
    
    % Confidence for the intervals:
    EstimateConf = sqrt(EstimateVar)*norminv(1 - Alpha/2);
    
    % Save the estimates on the plotting section of the results:
    HistoricPf(LoopNo) = EstimatePf;
    HistoricCoV(LoopNo) = EstimateCoV;    
    HistoricConf(LoopNo) = EstimateConf;
    
    % Check if the loop should continue
    if CoVThreshold && EstimateCoV <= TargetCoV
        % Check if there is a Target CoV and if it is reached
            break
    end
    
    if CurrentRuns >= MaxSampleSize
        
        if CoVThreshold
            fprintf('\nWarning: Importance Sampling finished before reaching target coefficient of variation.');
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
            fprintf('\nIS: Convergence not achieved with %g samples.',CurrentRuns);
            fprintf('\nIS: Current CoV: %e',EstimateCoV)
            fprintf('\nIS: Current Pf : %e',EstimatePf);
            fprintf('\nIS: Sending batch no %g...\n',LoopNo);
        end
    end
    
end


%% Store the results:
Results.Pf = EstimatePf;
Results.Beta = -norminv(Results.Pf);
Internal.EstimateVar = EstimateVar;
Internal.EstimateSD = sqrt(EstimateVar);
Results.CoV = EstimateCoV;

% Confidence interval:
Results.PfCI(1) = Results.Pf - EstimateConf;
Results.PfCI(2) = Results.Pf + EstimateConf;
Results.BetaCI(1) = -norminv(Results.PfCI(2));
Results.BetaCI(2) = -norminv(Results.PfCI(1));

% Counters
Results.ModelEvaluations = CurrentRuns;

Results.History.Pf = HistoricPf;
Results.History.CoV = HistoricCoV;
Results.History.Conf = HistoricConf;

%Save the limit state evaluation results:
 if Options.SaveEvaluations
        Results.LSFvals.X = CompleteSample;
        Results.LSFvals.G = CompleteEvals;
 end

if Display > 0
    fprintf('\nIS: Finished.\n ');
end