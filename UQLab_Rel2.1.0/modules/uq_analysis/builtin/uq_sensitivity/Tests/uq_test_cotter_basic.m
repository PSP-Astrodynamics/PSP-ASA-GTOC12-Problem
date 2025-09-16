function success = uq_test_cotter_basic(level)
% PASS = UQ_TEST_COTTER_BASIC(LEVEL): Test the Cotter method with a
% simple example. 
%
% See also: UQ_COTTER_INDICES,UQ_SENSITIVITY,
%           UQ_TEST_COTTER_HIGH_ORDER_INTERACTIONS

uqlab('-nosplash');

success = 1;

% Allow some numerical error:
TH = 1e-10;

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |', level,...
    '| uq_test_cotter_basic...\n']);

%% INPUT
M = 3;
[Marginals(1:M).Type] = deal('uniform');
[Marginals(1:M).Parameters] = deal([0,10]) ;
IOpts.Marginals = Marginals;
myInput = uq_createInput(IOpts, '-private');

%% MODEL
MOpts.mString = 'X(:, 1) + X(:, 2)';
MOpts.isVectorized = true;
myModel = uq_createModel(MOpts, '-private');

%% ANALYSIS BASIC OPTIONS
AOpts.Type = 'Sensitivity';

% Use the previously created model and input:
AOpts.Model = myModel;
AOpts.Input = myInput;
AOpts.Method = 'cotter';
AOpts.Display = 'nothing';
[Factors(1:M).Boundaries] = deal([0, 10]);
AOpts.Factors = Factors;


%% TEST

myAnalysis = uq_createAnalysis(AOpts, '-private');
Co = myAnalysis.Results;

% We expect all the indices of X3 to be zero:
testfail = sprintf('\nTest uq_test_cotter_basic failed.\n');

if max([Co.CotterIndices(3), Co.OddOrder(3), Co.EvenOrder(3)]) > TH
    error('%sCotter Indices gave non-zero results for an unimportant variable (X3).\n', testfail);
end

% We expect indices for X1 and X2 to be equal:
if ~isequal([Co.CotterIndices(1), Co.OddOrder(1), Co.EvenOrder(1)], ...
        [Co.CotterIndices(2), Co.OddOrder(2), Co.EvenOrder(2)])
    error('%sCotter Indices are not consistent.\n', testfail);
end

% X1 should have only odd order effect:
if Co.EvenOrder(1) > TH
    error('%sCotter Indices are not correct (spotted even order effect for X1).\n', testfail);
end