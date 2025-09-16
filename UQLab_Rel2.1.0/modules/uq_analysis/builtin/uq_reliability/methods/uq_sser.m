function Results = uq_sser(CurrentAnalysis)
% UQ_SSER is the wrapper for SSE-based reliability problems

% extract options
Options = CurrentAnalysis.Internal;

% extract SSE options
metaOpts = Options.SSER;
metaOpts.Type = 'metamodel';
metaOpts.MetaType = 'SSE';
metaOpts.Name = 'SSER';

%% create SSE of limit-state function
% create limit-state uq_model and assign to SSE options
modelOpts.mHandle = @(x) uq_evalLimitState(x, Options.Model, Options.LimitState);
modelOpts.isVectorized = true;
modelOpts.Name = 'Limit-state';
myLimitState = uq_createModel(modelOpts, '-private');
metaOpts.FullModel = myLimitState;

% assign input
metaOpts.Input = Options.Input;

% create SSER
mySSER = uq_createModel(metaOpts,'-private');

% extract Pf and beta evolution
history = uq_SSE_extractPfBeta(mySSER.SSE);

% add limit state evaluations
if Options.SaveEvaluations
    for rr = 1:mySSER.SSE.currRef
        currIdx = mySSER.ExpDesign.ref == rr;
        history.X{rr} = mySSER.ExpDesign.X(currIdx,:);
        history.G{rr} = mySSER.ExpDesign.Y(currIdx);
    end
end

% Store in Results
Results.SSER = mySSER;
Results.History = history;
Results.Pf = history.Pf(end,1);
Results.PfCI = history.Pf(end,2:3);
Results.CoV = history.CoV(end);
Results.Beta = history.Beta(end,1);
Results.BetaCI = history.Beta(end,2:3);
Results.ModelEvaluations = size(mySSER.SSE.ExpDesign.X,1);