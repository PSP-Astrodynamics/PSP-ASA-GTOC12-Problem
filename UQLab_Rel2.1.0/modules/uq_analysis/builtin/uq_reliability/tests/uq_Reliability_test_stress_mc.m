function success = uq_Reliability_test_stress_mc(level)
% SUCCESS = UQ_RELIABILITY_TEST_STRESS_MC(LEVEL):
%
%     Stress test Monte Carlo Simulation with the sin function, to see that 
%     results are consistent with various initial configurations.
%     List of the parameters to loop over:
%     1 - Simulation.Alpha
%     2 - Simulation.MaxSampleSize
%     3 - Simulation.TargetCoV
%     4 - Simulation.BatchSize
%
% See also UQ_SELFTEST_UQ_RELIABILITY

uqlab('-nosplash');

rng(100);
success = 1;

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);



% These are the input and model that we will use:
% Model
MOpts.mFile = 'uq_sin_counter';
myModel = uq_createModel(MOpts, '-private');

%% Input
IOpts.Marginals.Type = 'Uniform';
IOpts.Marginals.Parameters = [-1, 1];
myInput = uq_createInput(IOpts, '-private');

%% Constant analysis options:
CAOpts.Type = 'Reliability';
CAOpts.Method = 'MCS';
CAOpts.Display = 'quiet';
CAOpts.Model = myModel;
CAOpts.Input = myInput;

% These are the results we expect:
Expected.Pf = 0.5;


% We compare the results to be equal within a threshold TH:
TH = 1e-3;

% The configurations dependent on the test level
switch lower(level)
    case 'normal'
    	Alpha 		= {0.1, 0.05};
        MaxSampleSize 	= {1e3, 1e6};
		TargetCoV 	= {0.05, 1e-2};
		SampleSize 	= {1000};

    case 'slow'
		Alpha 		= {0.1, 0.05, 0.2};
        MaxSampleSize 	= {1e3, 2345, 1e4, Inf};
		TargetCoV 	= {0.1, 0.05, 1e-2};
		SampleSize 	= {Inf, 1000};    	
end

Combinations = uq_findAllCombinations(Alpha,MaxSampleSize, TargetCoV, SampleSize);
ScheRuns = size(Combinations, 1);

fprintf('\n%d Monte Carlo analysis will be performed.', ScheRuns);

%% Start testing the features:
for ii = 1:ScheRuns
	% Extract the current combination of parameters:
	CC = Combinations(ii, :);

	% Clear the previous settings, and set new analysis options, according to this order:
	% 1 - Simulation.Alpha
	% 2 - Simulation.MaxSampleSize
	% 3 - Simulation.TargetCoV
	% 4 - Simulation.BatchSize

	AOpts = CAOpts;

	% Simulation options:
	AOpts.Simulation.Alpha = Alpha{CC(1)};
	AOpts.Simulation.MaxSampleSize = MaxSampleSize{CC(2)};
	AOpts.Simulation.TargetCoV = TargetCoV{CC(3)};
	AOpts.Simulation.BatchSize = SampleSize{CC(4)};


	ithAnalysis = uq_createAnalysis(AOpts, '-private');
	ithResults = ithAnalysis.Results;

	% Before comparing, retrieve the model evaluations:
	Expected.ModelEvaluations = uq_sin_counter('count');
	% Set them to zero again:
	uq_sin_counter('reset');

	% Adapt the threshold depending on the model evaluations performed:
	TH = 1/sqrt(Expected.ModelEvaluations);
	[pass, ErrMsg] = uq_compareStructs(Expected, ithResults, TH);
	success = pass*success;

	if ~pass
		% Report the error:
		fprintf('\nError: in run %d.', ii);
		fprintf('\nWhile evaluating uq_test_stress_mc with the following options:')
		fprintf('\n\tSimulation.Alpha:\n\t%s', uq_sprintf_mat(AOpts.Simulation.Alpha));
		fprintf('\n\tSimulation.MaxSampleSize:\n\t%s', uq_sprintf_mat(AOpts.Simulation.MaxSampleSize));
		fprintf('\n\tSimulation.TargetCoV:\n\t%s', uq_sprintf_mat(AOpts.Simulation.TargetCoV));
		fprintf('\n\tSimulation.BatchSize:\n\t%s', uq_sprintf_mat(AOpts.Simulation.BatchSize));
		fprintf('\n\n%s.', ErrMsg);
		break;
	end

end
if ~success
	fprintf('\n');
	error('The test uq_test_stress_mc failed.');
end