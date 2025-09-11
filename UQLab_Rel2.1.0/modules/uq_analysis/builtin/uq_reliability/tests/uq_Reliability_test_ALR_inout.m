function success = uq_Reliability_test_ALR_inout(level)
% SUCCESS = UQ_RELIABILITY_TEST_ALR_INOUT(LEVEL):
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
M = 3;
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

%% set the options of ALR
alropts.Type = 'Reliability';
alropts.Method = 'ALR';

%related to the Kriging meta-model
alropts.ALR.MetaModel = 'Kriging';
alropts.ALR.Kriging.Trend.Type = 'linear';
alropts.ALR.Kriging.Corr.Family = 'Gaussian';
alropts.ALR.Kriging.Corr.Type = 'Separable';
alropts.ALR.Kriging.Optim.Method = 'CMAES' ;

% related to the reliability algorithm
alropts.ALR.Reliability = 'MC' ;
alropts.Simulation.BatchSize = 5e2;
alropts.Simulation.MaxSampleSize = 1e3;

%stopping criterion
alropts.ALR.Convergence = 'stopPfStab';
alropts.ALR.ConvThres = 1e-2 ;
alropts.ALR.ConvIter = 3 ;

%exerimental design
alropts.ALR.IExpDesign.N = 15;
alropts.ALR.IExpDesign.Sampling = 'LHS';
%related to ALR sample addition
alropts.ALR.MaxAddedED = 6;
alropts.ALR.NumOfPoints = 2 ;

%limit state function
alropts.LimitState.Threshold = 0;
alropts.LimitState.CompOp = '<';

%display options
alropts.Display = 'quiet';

%create the analysis
ALRAnalysis = uq_createAnalysis(alropts);
Int = ALRAnalysis.Internal;
Histo = ALRAnalysis.Results.History;


%% check the response structure

crit = [
         %check whether the correct options were passed
         strcmp(ALRAnalysis.Results.Metamodel.Internal.Kriging.GP.Corr.Family, alropts.ALR.Kriging.Corr.Family)
         strcmp(ALRAnalysis.Results.Metamodel.Internal.Kriging.GP.Corr.Type, alropts.ALR.Kriging.Corr.Type)
         strcmp(ALRAnalysis.Results.Metamodel.Internal.Kriging.Trend.Type, alropts.ALR.Kriging.Trend.Type)
         strcmp(ALRAnalysis.Results.Metamodel.Internal.Kriging.Optim.Method, alropts.ALR.Kriging.Optim.Method)
         strcmp(ALRAnalysis.Results.Metamodel.Internal.Kriging.Optim.Method, alropts.ALR.Kriging.Optim.Method)

         strcmpi(ALRAnalysis.Results.Reliability.Internal.Method, alropts.ALR.Reliability)
         ALRAnalysis.Results.Reliability.Internal.Simulation.BatchSize == alropts.Simulation.BatchSize
         ALRAnalysis.Results.Reliability.Internal.Simulation.MaxSampleSize == alropts.Simulation.MaxSampleSize
         
         Int.LimitState.Threshold == alropts.LimitState.Threshold
         Int.LimitState.CompOp == alropts.LimitState.CompOp
         
         Int.ALR.MaxAddedED == alropts.ALR.MaxAddedED
         Int.ALR.IExpDesign.N == alropts.ALR.IExpDesign.N
         strcmp(alropts.ALR.IExpDesign.Sampling, Int.ALR.IExpDesign.Sampling)
         strcmp(Int.ALR.Convergence{1}, alropts.ALR.Convergence)

         %check some statistics of the response
         length(ALRAnalysis.Results.Metamodel.ExpDesign.Y) == alropts.ALR.MaxAddedED + alropts.ALR.IExpDesign.N
         length(Histo.Pf) == ceil(alropts.ALR.MaxAddedED/alropts.ALR.NumOfPoints) + 1
        ];
    
if ~sum(crit == 0)
     success = 1;
     fprintf('\nTest uq_test_ALR_inout finished successfully!\n');
else
    ErrStr = 'Error in uq_test_ALR_inout while comparing the input and output structures';
    error(ErrStr);
end

