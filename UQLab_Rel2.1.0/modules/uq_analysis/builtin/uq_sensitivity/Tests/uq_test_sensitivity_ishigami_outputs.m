function success = uq_test_sensitivity_ishigami_outputs(level)
% SUCCESS = UQ_TEST_SENSITIVITY_ISHIGAMI_OUTPUTS(LEVEL): non-regression test
%     for the full sensitivity package in the presence of multiple outputs.
%
% See also: UQ_SENSITIVITY,UQ_ISHIGAMI

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_sensitivity_ishigami_outputs...\n']);

%% Start the framework and options:
% Threshold for numerical error (very low, for consistency checks)
TH = 1e-12; 

% Threshold on the approximation error (for correctness)
TH2 = 0.12;

% Common error message:
testfail = ...
    sprintf('\nThe test uq_test_sensitivity_ishigami_outputs failed.\n');

%% Input
M = 3;
[Input.Marginals(1:M).Type] = deal('Uniform');
[Input.Marginals(1:M).Parameters] = deal([-pi, pi]);
testInput = uq_createInput(Input, '-private');

%% Model with various outputs:
% (Ishigami on outputs 1 and 3 and 100*X1^3 on output 2)

modelopts.Name = 'Ishigami Example Model';
modelopts.mFile = 'uq_ishigami_various_outputs';
testModel = uq_createModel(modelopts, '-private');

%% Analysis -- Sobol
%  Create a Sobol' indices analysis:
Sensopts.Type = 'Sensitivity';
Sensopts.Model = testModel;
Sensopts.Input = testInput;
Sensopts.Method = 'Sobol';
Sensopts.Display = 'quiet';
Sensopts.Sobol.Estimator = 't';

% Test higher orders:
Sensopts.Sobol.Order = 3;

% Test also that bootstrap does not produce errors:
Sensopts.Bootstrap.Replications = 20;
Sensopts.Bootstrap.Alpha = 0.05;

% Sampling options:
Sensopts.Sobol.Sampling = 'lhs';
Sensopts.Sobol.SampleSize = 1e3;

% Create and run the analysis:
testAnalysis = uq_createAnalysis(Sensopts, '-private');
SoRes = testAnalysis.Results;

%% Consistency -- Sobol:
% Output 3 should be the same as output 1:

TotalO1 = SoRes.Total(:,1);
TotalO3 = SoRes.Total(:,3);
if max(abs(TotalO1 - TotalO3)) > TH
    error('%sTotal Sobol'' indices are not consistent for the two outputs.\n', testfail);
end

% Test the other orders:
for ii = 1:Sensopts.Sobol.Order    
    IndO1 = SoRes.AllOrders{ii}(:,1);
    IndO3 = SoRes.AllOrders{ii}(:,3);
    
    if max(abs(IndO1 - IndO3)) > TH
        error('%sSobol'' indices of order %d are not consistent for the two outputs.\n', testfail, ii);
    end
end
success = 1;

%% Correctness -- Sobol:
% Output 2 has only one important factor: X1, therefore, total and first
% order indices should be [1, 0, 0]', the rest should be 0.

% Expected result:
TotalAndFirst = [1, 0, 0]';

% Total indices:
TotalO2 = SoRes.Total(:,2);
if max(abs(TotalO2 - TotalAndFirst)) > TH2
    error('%sTotal Sobol'' indices are not corrrect on output 2.\n', testfail);
end

% Order 1:
IndO2 = SoRes.AllOrders{1}(:,2);
if max(abs(IndO2 - TotalAndFirst)) > TH2
    error('%sSobol'' indices of order 1 are not corrrect on output 2.\n', testfail);
end

% Higher orders:
for ii = 2:Sensopts.Sobol.Order
    IndO2 = SoRes.AllOrders{ii}(:,2);
    if max(abs(IndO2)) > TH2
        error('%sSobol'' indices of order %d are not corrrect on output 2.\n', testfail, ii);
    end
end

%% Analysis -- Morris
%  Create a Morris analysis:
clear Sensopts
Sensopts.Type = 'Sensitivity';
Sensopts.Model = testModel;
Sensopts.Input = testInput;
Sensopts.Method = 'Morris';
Sensopts.Display = 'quiet';
[Factors(1:M).Boundaries] = deal([-pi, pi]);
Sensopts.Factors = Factors;
Sensopts.Morris.FactorSamples = 100;
Sensopts.Morris.GridLevels = 6;
Sensopts.Morris.PerturbationSteps = 3;
testAnalysis = uq_createAnalysis(Sensopts, '-private');
MoRes = testAnalysis.Results;


%% Consistency -- Morris:
%  Mu, MuStar and Std should be the same for outputs 1 and 3:
switch 1
    case max(abs(MoRes.Mu(:,1) - MoRes.Mu(:,3))) > TH
        error('%sMorris measure Mu is not consistent across various outputs.\n', testfail);
    case max(abs(MoRes.MuStar(:,1) - MoRes.MuStar(:,3))) > TH
        error('%sMorris measure MuStar is not consistent across various outputs.\n', testfail);
    case max(abs(MoRes.Std(:,3) - MoRes.Std(:,3))) > TH
        error('%sMorris measure Std is not consistent across various outputs.\n', testfail);
end

%% Correctness -- Morris:
%  The output 2 MuStar X1 is expected to be much larger than the
%  other two, that should be close to 0 (both Mu and MuStar)
if max(abs([MoRes.Mu(2, 2), MoRes.Mu(3, 2)])) > TH2
    error('%sMorris measure MuStar on output 2 is not correct.\n', testfail);
end
if max(MoRes.MuStar(1,2) <= max([MoRes.MuStar(2, 2), MoRes.MuStar(3, 2)]))
    error('%sMorris measure MuStar on output 2 is not correct.\n', testfail);
end


%% Analysis -- Cotter
%  Create a Cotter analysis:
clear Sensopts
Sensopts.Type = 'Sensitivity';
Sensopts.Model = testModel;
Sensopts.Input = testInput;
Sensopts.Method = 'Cotter';
Sensopts.Display = 'quiet';
Sensopts.Factors = Factors; % Use the same as Morris
testAnalysis = uq_createAnalysis(Sensopts);
CoRes = testAnalysis.Results;


%% Consistency -- Cotter:
%  The sensitivity indices, and the even order and odd order indices should
%  be the same on outputs 1 and 3:
switch 1
    case max(abs(CoRes.CotterIndices(:,1) - CoRes.CotterIndices(:,3))) > TH
        error('%sCotter measure CotterIndices is not consistent across various outputs.\n', testfail);
    case max(abs(CoRes.EvenOrder(:,1) - CoRes.EvenOrder(:,3))) > TH
        error('%sCotter measure EvenOrder is not consistent across various outputs.\n', testfail);
    case max(abs(CoRes.OddOrder(:,1) - CoRes.OddOrder(:,3))) > TH
        error('%sCotter measure OddOrder is not consistent across various outputs.\n', testfail);
end


%% Correctness -- Cotter:
%  For output 2, all the values should be close to zero, except the index of
%  X1 and the even order effect of X1 that should be much larger:

SmallIndices = [CoRes.CotterIndices(2, 2), CoRes.CotterIndices(3, 2), ...
    CoRes.OddOrder(2, 2), CoRes.OddOrder(3, 2), ...
    CoRes.EvenOrder(1, 3), CoRes.EvenOrder(2, 2), CoRes.EvenOrder(3, 2)];

MaxSmallIdx = max(abs(SmallIndices));

if MaxSmallIdx > TH2
    error('%sCotter sensitivity indices on output 2 are not correct.\n', testfail);
end
if min(CoRes.CotterIndices(1,2),  CoRes.OddOrder(1,2)) <= MaxSmallIdx
    error('%sCotter sensitivity indices on output 2 are not correct.\n', testfail);
end



%% Analysis -- Perturbation:
%  Create a Perturbation Method:
clear Sensopts
Sensopts.Type = 'Sensitivity';
Sensopts.Model = testModel;
Sensopts.Input = testInput;
Sensopts.Method = 'perturbation';
Sensopts.Display = 'quiet';
Sensopts.Gradient.Method = 'centred';
Sensopts.Gradient.h = 1e-5;
testAnalysis = uq_createAnalysis(Sensopts);
PeRes =testAnalysis.Results;

AnalyticalVarEstimate = pi^2/3*[1, 0, 1]';
AnalyticalSensEstimates = [1, 0, 0; ...
    1, 0, 0; ...
    1, 0, 0];

%% Consistency -- Perturbation:
if ~(PeRes.Mu(1) == PeRes.Mu(3)) || ...
        ~(PeRes.Var(1) == PeRes.Var(3)) || ...
        ~isequal(PeRes.Sensitivity(:,1), PeRes.Sensitivity(:,3))
    error('%sPerturbation method results are not consistent.\n', testfail);
end

%% Correctness -- Perturbation:
%  We know the analytical values of the perturbation estimates (using the
%  analytical gradients of the function), so we can compare them with our
%  results:
if max(PeRes.Var - AnalyticalVarEstimate') > TH2
    error('%sPerturbation method variance estimate is not correct.\n', testfail);
end

if max(max(abs(PeRes.Sensitivity - AnalyticalSensEstimates'))) > TH2
    error('%sPerturbation method sensitivity estimates are not correct.\n', testfail);
end

