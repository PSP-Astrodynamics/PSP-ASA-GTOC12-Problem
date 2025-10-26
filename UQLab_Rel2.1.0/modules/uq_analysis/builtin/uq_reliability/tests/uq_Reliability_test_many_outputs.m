function success = uq_Reliability_test_many_outputs(level)
% SUCCESS = UQ_RELIABILITY_TEST_MANY_OUTPUTS(LEVEL):
%     Testing the functionality of reliability methods when the limit-state 
%     function has more than a single output variable
%
% See also UQ_SELFTEST_UQ_RELIABILITY

%% Start the framework for testing:
uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);

%% set the seed
rng(4);

%% Create the model, input and basic analysis options:
% Model
MOpts.mFile = 'uq_sin_outputs_counter';
MOpts.isVectorized = true;
testModel = uq_createModel(MOpts, '-private');

% Input
IOpts.Marginals.Type = 'Uniform';
IOpts.Marginals.Parameters = [-1, 1];
testInput = uq_createInput(IOpts, '-private');

% Constant analysis options:
CAOpts.Type = 'Reliability';
CAOpts.Model = testModel;
CAOpts.Input = testInput;
CAOpts.Method = 'SORM';
CAOpts.Display = 'quiet';

% Expected common results:
CommonExpected.Pf = [0.5, 0.25, 0.5];

% These are the methods to be tested (FORM is included in SORM):
TestMethods = {'mc', 'SORM'};


%% conduct the analyses
for ii = 1:length(TestMethods)
	Method = TestMethods{ii};

	% Restart the options:
	AOpts = CAOpts;

	switch Method
		case {'mc'} 
			% Choose among simulation options.
			AvMethods = {'mc', 'is'};
	    	Alpha 		= {0.1, 0.05};
            MaxSampleSize 	= {1e4, Inf};
			TargetCoV 	= {1e-2, 5e-3};
			SampleSize 	= {1e4};
			Combinations = uq_findAllCombinations(AvMethods, Alpha, MaxSampleSize, TargetCoV, SampleSize);

			% Prepare the expected results:
			Expected = CommonExpected;

	    otherwise 
	    	% FORM options:
	    	Algorithm = {'iHLRF', 'HLRF'};
	    	StartingPoint = {0.1, -0.2, 0};
			StopG = {1e-4};
			StopU = {1e-4, 1e-12};	
	    	GradientStep = {'standardized', 'fixed', 'relative'};
	    	Gradienth = {1e-3};
	    	if strcmpi(level, 'slow')
		    	GradientMethod = {'backward', 'centred'};
		    else
		    	GradientMethod = {'backward'};
	    	end
	    	Combinations = uq_findAllCombinations(Algorithm, StartingPoint, StopG, StopU, GradientStep, Gradienth, GradientMethod);

	    	% Prepare the expected results:
			Expected = CommonExpected;
			
			% Add the SORM probabilities:
			Expected.PfSORM = Expected.Pf;
			Expected.PfSORMBreitung = Expected.Pf;

	end

	ScheRuns = size(Combinations, 1);
	if  strcmp('mc', Method)
		CurrentTest = 'analysis using simulation methods';
	else
		CurrentTest = 'FORM + SORM analysis';
	end
	fprintf('\n%d %s will be performed.', ScheRuns, CurrentTest);
    
	%% Start testing the features:
	for ii = 1:ScheRuns
		% Extract the current combination of parameters:
		CC = Combinations(ii, :);
		switch Method

			case 'mc'

				% Set the options:

				% Order on the Simulation Methods:
				% 1 - Method 	 			= 	AvMethods
		    	% 2 - Simulation.Alpha 		= 	Alpha
				% 3 - Simulation.MaxSampleSize 	= .MaxSampleSize
				% 4 - Simulation.TargetCoV 	= 	TargetCoV
				% 5 - Simulation.BatchSize = 	SampleSize

				AOpts.Method 				= 	AvMethods{CC(1)};
				AOpts.Simulation.Alpha 		= 	Alpha{CC(2)};
				AOpts.Simulation.MaxSampleSize 	= MaxSampleSize{CC(3)};
				AOpts.Simulation.TargetCoV 	= 	TargetCoV{CC(4)};
				AOpts.Simulation.BatchSize = 	SampleSize{CC(5)};

				% Threshold using to compare them with the expected results:
				if isinf(MaxSampleSize{CC(3)})
					TH = 2e-2;
				else
					TH = 2/sqrt(MaxSampleSize{CC(3)});
				end

			otherwise	

				% Set the options:

				% 1 - FORM.Algorithm = Algorithm
				% 2 - FORM.StartingPoint = StartingPoint
				% 3 - FORM.StopU = StopU
				% 4 - FORM.StopG = StopG
				% 5 - Gradient.Step = GradientStep
				% 6 - Gradient.h = Gradienth
				% 7 - Gradient.Method = GradientMethod

				AOpts.FORM.Algorithm 		= 	Algorithm{CC(1)};
	    		AOpts.FORM.StartingPoint 	= 	StartingPoint{CC(2)};
				AOpts.FORM.StopG 			= 	StopG{CC(3)};
				AOpts.FORM.StopU 			= 	StopU{CC(4)};
	    		AOpts.Gradient.Step 		= 	GradientStep{CC(5)};
	    		AOpts.Gradient.h 			= 	Gradienth{CC(6)};
	    		AOpts.Gradient.Method 		= 	GradientMethod{CC(7)};

	    		% Threshold using to compare them with the expected results:
	    		TH = 1e-5;

		end

		ithAnalysis = uq_createAnalysis(AOpts, '-private');
		ithResults = ithAnalysis.Results;
		[success, ErrMsg] = uq_compareStructs(Expected, ithResults, TH);
		if ~success
			% Report the error:
			fprintf('\nThere was an error while evaluating the %s.', CurrentTest);
			fprintf('\nRun %d failed, with the following options:', ii);

			if strcmp('sorm', AOpts.Method)
				fprintf('\n\tFORM.Algorithm:\n\t%s', AOpts.FORM.Algorithm);
				fprintf('\n\tFORM.StartingPoint:\n\t%s', uq_sprintf_mat(AOpts.FORM.StartingPoint));
				fprintf('\n\tFORM.StopG:\n\t%s', uq_sprintf_mat(AOpts.FORM.StopG));
				fprintf('\n\tFORM.StopU:\n\t%s', uq_sprintf_mat(AOpts.FORM.StopU));
				fprintf('\n\tGradient.Step:\n\t%s', AOpts.Gradient.Step);
				fprintf('\n\tGradient.h :\n\t%s', uq_sprintf_mat(AOpts.Gradient.h));
				fprintf('\n\tGradient.Method:\n\t%s', AOpts.Gradient.Method);

            else
                fprintf('\n\tMethod:\n\t%s', AOpts.Method);
				fprintf('\n\tSimulation.Alpha:\n\t%s', uq_sprintf_mat(AOpts.Simulation.Alpha));
				fprintf('\n\tSimulation.MaxSampleSize:\n\t%s', uq_sprintf_mat(AOpts.Simulation.MaxSampleSize, '%i'));
				fprintf('\n\tSimulation.TargetCoV:\n\t%s', uq_sprintf_mat(AOpts.Simulation.TargetCoV));
				fprintf('\n\tSimulation.BatchSize:\n\t%s', uq_sprintf_mat(AOpts.Simulation.BatchSize, '%i'));
				
		end
			fprintf('\n\n%s.', ErrMsg);
			fprintf('\n');
			error('There was an error during uq_test_reliability_many_outputs.')
		end

	end

end
fprintf('\n');