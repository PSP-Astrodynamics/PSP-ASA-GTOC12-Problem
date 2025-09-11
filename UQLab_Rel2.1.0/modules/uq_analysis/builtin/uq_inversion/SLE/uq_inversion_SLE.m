function Results = uq_inversion_SLE(Options)
% UQ_INVERSION_SLE is the wrapper for SLE-based inversion problems

%% initialize
% extract SLE options
metaOpts = Options.Solver.SLE;

% create likelihood uq_model and assign to SSE options
modelOpts.mHandle = Options.Likelihood;
modelOpts.Name = 'Likelihood';
myLikelihood = uq_createModel(modelOpts,'-private');
metaOpts.FullModel = myLikelihood;

% assign prior as input
metaOpts.Input = Options.FullPrior;

%% create SLE
if Options.Display > 0
    fprintf('\nConstructing SLE...\n');
end

% create
mySLE = uq_createModel(metaOpts,'-private');

if Options.Display > 0
    fprintf('\nFinished SLE construction!\n');
end

% Store in Results
Results.SLE = mySLE;