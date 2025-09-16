function success = uq_test_cotter_hoi_constant(level)
% PASS = UQ_TEST_COTTER_HOI_CONSTANT(LEVEL): non-regression test for the 
%     cotter sensitivity method with a model that contains only fourth order
%     interactions in the presence of constant inputs.
%
% See also: UQ_TEST_COTTER_BASIC,UQ_COTTER_INDICES,UQ_SENSITIVITY

%% Initialize:
uqlab('-nosplash');
rng(pi);

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_cotter_hoi_constant...\n']);
success = 1;

% Allowed deviation from true results:
Th = 0.05;

%% Set up UQLab:
% INPUT
M = 10;
[Input.Marginals(1:M).Type] = deal('Uniform');
[Input.Marginals(1:M).Parameters] = deal([-10, 10]);
[Input.Marginals([5 7]).Type] = deal('Constant');
[Input.Marginals([5 7]).Parameters] = deal(5);
ihandle = uq_createInput(Input);

% MODEL
Modelopts.mHandle = @(X) uq_high_order_interactions(X(:,[1,2,3,4,6,8,9,10])) + X(:,5).*X(:,7);
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
nonConst = [1 2 3 4 6 8 9 10];
OK(1) = max(abs(res.CotterIndices(nonConst) - res.CotterIndices(1))) <= Th;

% Odd order are zero:
OK(2) = max(abs(res.OddOrder)) <= Th;

% All of the even order indices are the same:
OK(3) = max(abs(res.EvenOrder(nonConst) - res.EvenOrder(1))) <= Th;

% The cost is 2(M + 1)
OK(4) = (res.Cost == 2*M + 2);

if ~all(OK)
    error('uq_test_cotter_high_order_interactions failed.');
end
