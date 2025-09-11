function results = uq_SRC_indices(current_analysis)
% RESULTS = UQ_SRC_INDICES(ANALYSISOBJ): calculate the
%     Standard Regression Coefficient-based (SRC) sensitivity indices on the
%     analysis object specified in ANALYSISOBJ. The results are stored in
%     the RESULTS structure
%
% See also: UQ_SENSITIVITY,UQ_INITIALIZE_UQ_SENSITIVITY

%% RETRIEVE THE ANALYSIS OPTIONS
Options = current_analysis.Internal;

M = Options.M;

%% Get a sample of points if the sample is not yet provided
%  If the sample was provided as an option, there is no need to
%  recalculate it.

if isfield(current_analysis.Internal.SRC, 'Sample')
    try 
        Sample.X = current_analysis.Internal.SRC.Sample.X;
        Sample.Y = current_analysis.Internal.SRC.Sample.Y;
        NSamples = size(Sample.Y,1);
        InputFlag = 0;
    catch me
        fprintf('The specified sample is not compatible with UQLab format: ')
        current_analysis.Internal.SRC.Sample
        rethrow(me);
    end
else
    try % default to LHS sampling if not specified
        NSamples = current_analysis.Internal.SRC.SampleSize;
        if ~isfield(current_analysis.Internal.SRC, 'Sampling')
            Sampling = 'LHS';
        else 
            Sampling = current_analysis.Internal.SRC.Sampling;
        end
        Sample.X = uq_getSample(Options.Input, NSamples, Sampling);
        Sample.Y = uq_evalModel(Options.Model,Sample.X);
        InputFlag = 1;
    catch me
        rethrow(me);
    end
end

%% NOW EVALUATE THE CORRELATION COEFFICIENTS
% To avoid NaNs the constant terms are simply ignored:
Sample.X = Sample.X(:,find(Options.FactorIndex));

% add the constant term
X = [ones(size(Sample.X(:,1))), Sample.X];


SRCIdx = zeros(size(Sample.X,2), size(Sample.Y,2));
SRRCIdx = SRCIdx;
% loop over the output components
for oo = 1:size(Sample.Y,2)
    Y = Sample.Y(:,oo);
    SRC = X'*X\X'*Y;
    % Remove the constant term (not used)
    B0 = SRC(1);
    SRCIdx(:,oo) = SRC(2:end);
    
    RX = [ones(size(Sample.X(:,1))), tiedrank(Sample.X)];
    RY = tiedrank(Y);
    
    
    SRRC = RX'*RX\RX'*RY;
    gamma0 = SRRC(1);
    SRRCIdx(:,oo) = SRRC(2:end);
    
    
    SigmaY = std(Y)';
    current_input = current_analysis.Internal.Input;
    switch InputFlag
        case 1
            SigmaX = vertcat(current_input.Marginals(find(Options.FactorIndex)).Moments);
            SigmaX = SigmaX(:,2);
        case 0
            SigmaX = std(Sample.X)';
    end
    SRCIdx(:,oo) = SRCIdx(:,oo).*(SigmaX/SigmaY);
end

% For consistency the results of the constant terms are added back to the
% results as zeros
totSRCIdx      = zeros(M,oo);
totSRRCIdx = totSRCIdx;
totSRCIdx((Options.FactorIndex),:)  = SRCIdx;
totSRRCIdx((Options.FactorIndex),:) = SRRCIdx;


%% AND REPORT BACK THE RESULTS
results.SRCIndices = totSRCIdx;
results.SRRCIndices = totSRRCIdx;

if Options.SaveEvaluations
    results.ExpDesign = Sample;
end

if Options.Display > 0
    fprintf('SRC: Finished.\n');
end

results.Cost = NSamples;
