function success = uq_Reliability_test_APCKMCS_inout(level)
% SUCCESS = UQ_RELIABILITY_TEST_APCKMCS_INOUT(LEVEL):
%     This test investigates whether the custom options are passed to the
%     output model
%
% See also: UQ_SELFTEST_UQ_RELIABILITY

%% Start test:
uqlab('-nosplash');
if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
seed = 1;

%% create the input
% Marginals:
M = 5;
for ii = 1:M
    IOpts.Marginals(ii).Name = 'R';
    IOpts.Marginals(ii).Type = 'Gaussian';
    IOpts.Marginals(ii).Moments = [1 1];
end

% Create the input:
uq_createInput(IOpts);
rng(seed);

%% create the computational model
MOpts.mString = 'sum(X,2).*sin(X(:,1))';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% set the options of AKMCS
akopts.Type = 'Reliability';
akopts.Method = 'AKMCS';

%related to the simulation
akopts.Simulation.BatchSize = 5e2;
akopts.Simulation.MaxSampleSize = 1e3;

%limit state function
akopts.LimitState.Threshold = 0;
akopts.LimitState.CompOp = '<';

%related to AKMCS sample addition
akopts.AKMCS.MaxAddedED = 5;

%related to the Kriging meta-model
akopts.AKMCS.MetaModel = 'PCK';
akopts.AKMCS.PCK.Kriging.Corr.Family = 'Gaussian';
akopts.AKMCS.PCK.Kriging.Corr.Type = 'Separable';
akopts.AKMCS.PCK.Mode = 'optimal';

%experimental design
akopts.AKMCS.IExpDesign.N = 10;
akopts.AKMCS.IExpDesign.Sampling = 'LHS';

%stopping criterion
akopts.AKMCS.Convergence = 'stopPf';

%display options
akopts.Display = 'quiet';

%create the analysis
AKAnalysis = uq_createAnalysis(akopts);
Int = AKAnalysis.Internal;
Histo = AKAnalysis.Results.History;


%% check the response structure
crit = [
         %check whether the correct options were passed
         Int.Simulation.BatchSize ~= akopts.Simulation.BatchSize
         Int.Simulation.MaxSampleSize == akopts.Simulation.MaxSampleSize
         Int.LimitState.Threshold == akopts.LimitState.Threshold
         Int.LimitState.CompOp == akopts.LimitState.CompOp
         Int.AKMCS.MaxAddedSamplesTotal == akopts.AKMCS.MaxAddedED
         Int.AKMCS.MaxAddedSamplesInBatch == akopts.AKMCS.MaxAddedED
         Int.AKMCS.IExpDesign.N == akopts.AKMCS.IExpDesign.N
         strcmp(akopts.AKMCS.IExpDesign.Sampling, Int.AKMCS.IExpDesign.Sampling)
         strcmp(Int.AKMCS.Convergence, akopts.AKMCS.Convergence)
         strcmp(AKAnalysis.Results.PCK.Internal.Kriging.Internal.Kriging.GP.Corr.Family, akopts.AKMCS.PCK.Kriging.Corr.Family)
         strcmp(AKAnalysis.Results.PCK.Internal.Kriging.Internal.Kriging.GP.Corr.Type, akopts.AKMCS.PCK.Kriging.Corr.Type)
         strcmp(AKAnalysis.Internal.AKMCS.PCK.Mode, akopts.AKMCS.PCK.Mode)
         
         %check some statistics of the response
         length(AKAnalysis.Results.PCK.ExpDesign.Y) == akopts.AKMCS.MaxAddedED + akopts.AKMCS.IExpDesign.N
         length(Histo.Pf) == akopts.AKMCS.MaxAddedED + 1
        ];
    
if ~sum(crit == 0) 
     success = 1;
     fprintf('\nTest uq_test_APCKMCS_inout finished successfully!\n');
else
    ErrStr = 'Error in uq_test_APCKMCS_inout while comparing the input and output structures';
    error(ErrStr);
end

