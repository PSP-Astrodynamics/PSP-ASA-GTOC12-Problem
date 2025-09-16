function success = uq_Reliability_test_stress_formsorm(level)
% SUCCESS = UQ_RELIABILITY_TEST_STRESS_FORMSORM(LEVEL):
%
%     Stress test FORM and SORM with the sin function, to see that results are 
%     consistent with various initial configurations.
%     List of the parameters to loop over:
%     1 - FORM.Algorithm
%     2 - FORM.StartingPoint
%     3 - FORM.StopG
%     4 - FORM.StopU
%     5 - Gradient.Step
%     6 - Gradient.h 
%     7 - Gradient.Method
%
% See also UQ_SELFTEST_UQ_RELIABILITY

uqlab('-nosplash');

success = 1;

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);



%% These are the input and model that we will use:
% Model
MOpts.mFile = 'uq_sin_counter';
myModel = uq_createModel(MOpts);

% Input
IOpts.Marginals.Type = 'Uniform';
IOpts.Marginals.Parameters = [-1, 1];
myInput = uq_createInput(IOpts);

%% Constant analysis options:
CAOpts.Type = 'Reliability';
CAOpts.Method = 'SORM';
CAOpts.Display = 'quiet';

% These are the results we expect:
Expected.Pf = 0.5;
Expected.PfSORM = 0.5;
Expected.PfSORMBreitung = 0.5;
Expected.BetaHL = 0;
Expected.Ustar = 0;
Expected.Xstar = 0;
Expected.History.OriginValue = 0;


% We compare the results to be equal within a threshold TH:
TH = 1e-3;

%% The different configurations dependent on the analysis level
switch lower(level)
    case 'normal'
    	Algorithm = {'iHLRF'};
    	StartingPoint = {0.1, -0.2};
		StopU = {1e-4};	
		StopG = {1e-4};
    	GradientStep = {'standardized', 'fixed', 'relative'};
    	Gradienth = {1e-3, 1e-12};
    	GradientMethod = {'centred', 'forward'};		
		

    case 'slow'
    	Algorithm = {'iHLRF', 'HLRF'};
    	StartingPoint = {0.1, -0.2, -0.9, 0.9, 1e-4, -0.6, 0.5};
    	StopU = {1e-3, 1e-4, 1-6};	
		StopG = {1e-3, 1e-4, 1e-7};
		GradientStep = {'standardized', 'fixed', 'relative'};
    	Gradienth = {0.1, 1e-3, 1e-12};
    	GradientMethod = {'centred', 'forward', 'backward'};
    	
end

% We now find all the combinations with the previous features (the order is important here)
Combinations = uq_findAllCombinations(Algorithm, StartingPoint, StopG, StopU, GradientStep, Gradienth, GradientMethod);
ScheRuns = size(Combinations, 1);
fprintf('\n%d FORM+SORM analysis will be performed.', ScheRuns);
uq_sin_counter('reset');

%% Start testing the features:
for ii = 1:ScheRuns
	% Extract the current combination of parameters:
	CC = Combinations(ii, :);

	% Clear the previous settings, and set new analysis options, according to this order:
	% 1 - FORM.Algorithm
	% 2 - FORM.StartingPoint
	% 3 - FORM.StopG
	% 4 - FORM.StopU
	% 5 - Gradient.Step
	% 6 - Gradient.h 
	% 7 - Gradient.Method

	AOpts = CAOpts;

	% Form options:
	AOpts.FORM.Algorithm = Algorithm{CC(1)};
	AOpts.FORM.StartingPoint = StartingPoint{CC(2)};
	AOpts.FORM.StopG = StopG{CC(3)};
	AOpts.FORM.StopU = StopU{CC(4)};

	% Gradient options:
	AOpts.Gradient.Step = GradientStep{CC(5)};
	AOpts.Gradient.h = Gradienth{CC(6)};
	AOpts.Gradient.Method = GradientMethod{CC(7)};

	ithAnalysis = uq_createAnalysis(AOpts, '-private');
	ithResults = ithAnalysis.Results;

	% Before comparing, retrieve the model evaluations performed and set the counter to zero for the next round:
	Expected.ModelEvaluations = uq_sin_counter('count');
	uq_sin_counter('reset');

	[pass, ErrMsg] = uq_compareStructs(Expected, ithResults, TH);
	success = pass*success;

	if ~pass
		% Report the error:
		fprintf('\nError: in run %d.', ii);
		fprintf('\nWhile evaluating uq_test_stress_formsorm with the following options:')
		fprintf('\n\tFORM.Algorithm:\n\t%s', AOpts.FORM.Algorithm);
		fprintf('\n\tFORM.StartingPoint:\n\t%s', uq_sprintf_mat(AOpts.FORM.StartingPoint));
		fprintf('\n\tFORM.StopG:\n\t%s', uq_sprintf_mat(AOpts.FORM.StopG));
		fprintf('\n\tFORM.StopU:\n\t%s', uq_sprintf_mat(AOpts.FORM.StopU));
		fprintf('\n\tGradient.Step:\n\t%s', AOpts.Gradient.Step);
		fprintf('\n\tGradient.h :\n\t%s', uq_sprintf_mat(AOpts.Gradient.h));
		fprintf('\n\tGradient.Method:\n\t%s', AOpts.Gradient.Method);
		fprintf('\n\n%s.', ErrMsg);
		break;
	end

end
if ~success
	fprintf('\n');
	error('The test uq_test_stress_formsorm failed.');
end