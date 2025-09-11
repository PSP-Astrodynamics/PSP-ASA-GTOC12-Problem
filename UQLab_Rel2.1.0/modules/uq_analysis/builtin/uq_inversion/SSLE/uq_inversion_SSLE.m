function Results = uq_inversion_SSLE(Options)
% UQ_INVERSION_SSLE is the wrapper for SSLE-based inversion problems

%% initialize
% extract SLE options
metaOpts = Options.Solver.SSLE;

% create likelihood uq_model and assign to SSE options
modelOpts.mHandle = Options.Likelihood;
modelOpts.Name = 'Likelihood';
myLikelihood = uq_createModel(modelOpts,'-private');
metaOpts.FullModel = myLikelihood;

% assign prior as input
metaOpts.Input = Options.FullPrior;

%% create SSLE
if Options.Display > 0
    fprintf('\nConstructing SSLE...\n');
end

% create
mySSLE = uq_createModel(metaOpts,'-private');

if Options.Display > 0
    fprintf('\nFinished SSLE construction!\n');
end

% Store in Results
Results.SSLE = mySSLE;