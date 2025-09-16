function success = uq_Reliability_test_linesampling_noRoot(level)
% SUCCESS = UQ_RELIABILITY_TEST_LINESAMPLING_NOROOT(LEVEL):
%     Test line sampline when no root is found.
%
% See also UQ_SELFTEST_UQ_RELIABILITY

%% Start test:
uqlab('-nosplash');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
seed = 42;
rng(seed)

%% create the input
IOpts.Marginals(1).Type = 'Gaussian';
IOpts.Marginals(1).Moments = [1.5 1];

IOpts.Marginals(2).Type = 'Gaussian';
IOpts.Marginals(2).Moments = [2.5 1];

% Create the input:
uq_createInput(IOpts);

%% create the computational model
MOpts.mString = 'sin(5.*X(:,1)/2) + 2 - (X(:,1).^2 + 4) .* (X(:,2) - 1)/20 ';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% line sampling with polynomial
lsopts.Type = 'reliability';
lsopts.Method = 'ls';
lsopts.LS.BatchSize = 50;
lsopts.LS.MaxLines = 50;

lsopts2 = lsopts;
lsopts2.LS.RootFinder.Type = 'spline';

lsopts3 = lsopts;
lsopts3.LS.RootFinder.Type = 'newton';

%% check the results
success = 0;
try
    uq_createAnalysis(lsopts);
    uq_createAnalysis(lsopts2);
    uq_createAnalysis(lsopts3);
    success = 1;
catch
    ErrStr = sprintf('\nError in uq_Reliability_test_linesampling_noRoot\n');
    error(ErrStr)
end

