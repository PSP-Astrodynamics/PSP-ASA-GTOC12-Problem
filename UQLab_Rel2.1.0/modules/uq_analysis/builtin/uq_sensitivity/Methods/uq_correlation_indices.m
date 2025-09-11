function results = uq_correlation_indices(current_analysis)
% RESULTS = UQ_CORRELATION_INDICES(ANALYSISOBJ): calculate the
%     correlation-based sensitivity indices on the analysis object
%     specified in ANALYSISOBJ. The results are stored in the RESULTS
%     structure.
%
% See also: UQ_SENSITIVITY,UQ_INITIALIZE_UQ_SENSITIVITY

Options = current_analysis.Internal;

% Get the list of factors that need to be evaluated
FactorIndex = Options.FactorIndex;

%% Get a sample of points if the sample is not yet provided
% figure out if we were already provided a sample or if we have to
% calculate one.

if isfield(Options.Correlation, 'Sample')
    try 
        Sample.X = Options.Correlation.Sample.X;
        Sample.Y = Options.Correlation.Sample.Y;
        NSamples = size(Sample.Y,1);
    catch me
        fprintf('The specified sample is not compatible with UQLab format: ')
        Options.Correlation.Sample
        rethrow(me);
    end
else
    try % default to LHS sampling if not specified
        NSamples = Options.Correlation.SampleSize;
        if ~isfield(Options.Correlation, 'Sampling')
            Sampling = 'LHS';
        else 
            Sampling = Options.Correlation.Sampling;
        end
        Sample.X = uq_getSample(Options.Input, NSamples, Sampling);
        Sample.Y = uq_evalModel(Options.Model,Sample.X);
    catch me
        rethrow(me);
    end
end

%% NOW EVALUATE THE CORRELATION COEFFICIENTS
CorrIdx = corr(Sample.X, Sample.Y);
RankCorrIdx = corr(Sample.X, Sample.Y, 'type', 'Spearman');

% Remove the unwanted factors
CorrIdx(~FactorIndex) = 0;
RankCorrIdx(~FactorIndex) = 0;

%% AND REPORT BACK THE RESULTS
results.CorrIndices = CorrIdx;
results.RankCorrIndices = RankCorrIdx;

if Options.SaveEvaluations
    results.ExpDesign = Sample;
end

if Options.Display > 0
    fprintf('Correlation: Finished.\n');
end

results.Cost = NSamples;
