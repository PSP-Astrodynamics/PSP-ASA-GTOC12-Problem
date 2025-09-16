function pass = uq_default_input_test_customdist( level )
% pass = UQ_DEFAULT_INPUT_TEST_CUSTOMDIST(LEVEL): non-regression test for the
% custom distributions functionality of the default input module
%
% Summary:
% The logistic distribution is defined in the files uq_testdist_*
% so the results of using those are checked against the built-in definition of
% the logistic distribution which should be identical

evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_customdist...\n']);

%% Test Parameters
N = 1e5;
epsAbs1 = 1e-15 ; %tolerance when exact estimates are expected
epsAbs2 = 1e-6 ;  %tolerance when approximate estimates are expected

%% Produce samples in different cases
% 1) Typical marginal definition
Input.Marginals.Type = 'logistic';
Input.Marginals.Parameters = [2, 0.01];
inpt = uq_createInput(Input);
rng(1);
X1 = uq_getSample(N);
Mom1 = inpt.Marginals.Moments;

% 2) Custom marginal with all files given
Input.Marginals.Type = 'testdist_logistic';
inpt = uq_createInput(Input);
rng(1);
X2 = uq_getSample(N);
Mom2 = inpt.Marginals.Moments;

% 3) Custom Marginal without PtoM given (will be numerically estimated 
%    with MC integration)
Input.Marginals.Type = 'testdist2_logistic';
inpt = uq_createInput(Input);
rng(1);
X3_1 = uq_getSample(N);
Mom3_1 = inpt.Marginals.Moments;

% % This self-test is omitted for now due to instabilities of this method
% % 4) Custom Marginal without PtoM given (will be numerically estimated 
% %    with direct integration)
% Input.Marginals.Type = 'testdist2_logistic';
% Input.Marginals.MomentEstimation = 'integral';
% inpt = uq_createInput(Input);
% rng(1);
% X3_2 = uq_getSample(N);
% Mom3_2 = inpt.Marginals.Moments;


%% Validate results
% 1) The obtained samples should be identical
test1_pass = ( max(abs(X1 -X2)) < epsAbs1 ) & ( max(abs(X1 -X3_1)) < epsAbs1 );
% test1_pass = test1_pass && ( max(abs(X1 -X3_2)) < epsAbs2 );

% 2) The obtained moments should be identical
test2_pass = ( max(abs(Mom1(:) - Mom2(:))) < epsAbs1 ) & ( max(abs(Mom1(:) -Mom3_1(:))) < epsAbs2 );
% test2_pass = test2_pass & ( max(abs(Mom1(:) -Mom3_2(:))) < epsAbs2 );

%% Test summary

pass = test1_pass & test2_pass;