function success = uq_test_cotter_high_order_interactions(level)
% PASS = UQ_TEST_COTTER_HIGH_ORDER_INTERACTIONS(LEVEL) non-regression
%     test for the Cotter sensitivity method on a model that contains only 
%     fourth order interactions.
%
% See also: UQ_TEST_COTTER_BASIC,UQ_COTTER_INDICES,UQ_SENSITIVITY

%% Initialize:
uqlab('-nosplash');
rng(pi);

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_cotter_high_order_interactions...\n']);
success = 1;

% Allowed deviation from true results:
Th = 0.05;

%% Set up UQLab:
% INPUT
M = 8;
[Input.Marginals(1:M).Type] = deal('Uniform');
[Input.Marginals(1:M).Parameters] = deal([-10, 10]);
ihandle = uq_createInput(Input);

% MODEL
Modelopts.mFile = 'uq_high_order_interactions';
mhandle = uq_createModel(Modelopts);

% ANALYSIS
Sensopts.Type = 'Sensitivity';
Sensopts.Method = 'Cotter';
Sensopts.Display = 'nothing';
[Sensopts.Factors(1:M).Boundaries] = deal([-10, 10]);
anhandle = uq_createAnalysis(Sensopts);
res = anhandle.Results(end);

%% Validate the results:
OK = false(1, 4);
% All of the indices are the same:
OK(1) = max(abs(res.CotterIndices - res.CotterIndices(1))) <= Th;

% Odd order are zero:
OK(2) = max(abs(res.OddOrder)) <= Th;

% All of the even order indices are the same:
OK(3) = max(abs(res.EvenOrder - res.EvenOrder(1))) <= Th;

% The cost is 2(M + 1)
OK(4) = (res.Cost == 2*M + 2);

if ~all(OK)
    error('uq_test_cotter_high_order_interactions failed.');
end
    
    

