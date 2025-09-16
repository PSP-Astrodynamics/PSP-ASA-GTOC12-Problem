function success = uq_test_inverseFORM(level)
% SUCCESS = UQ_TEST_BASIC_RS(LEVEL)
%     Testing a basic structural reliability analysis (SORM) 
%
% See also: UQ_SELFTEST_UQ_RELIABILITY

uqlab('-nosplash');
if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| uq_test_basic_RS...\n']);

%% error threshold
eps = 1e-2;

%% Make the input:
% We have the Resistance and Stress with moments:

%reference failure probability
RealXstar = [8.317 6.625];

%input marginals
IOpts.Marginals(1).Name = 'X1';
IOpts.Marginals(1).Type = 'Gaussian';
IOpts.Marginals(1).Moments = [6 0.8];

IOpts.Marginals(2).Name = 'X2';
IOpts.Marginals(2).Type = 'Gaussian';
IOpts.Marginals(2).Moments = [6 0.8];

uq_createInput(IOpts);

%% Create a Model:
MOpts.mString = '-exp(X(:, 1) - 7) - X(:, 2) + 10';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% Create and run the analysis (HLRF):
iForm_Opts.Type = 'Reliability';
iForm_Opts.Method = 'inverseform';
iForm_Opts.invFORM.TargetBetaHL = 3;
iForm_Opts.invFORM.Algorithms = 'AMV';

iForm_Opts.Display = 'quiet';

iFORM_simple = uq_createAnalysis(iForm_Opts);
ResultsiFORM = iFORM_simple.Results;
FoundXstar = ResultsiFORM.Xstar;

%% Compare iHLRF too
if strcmpi(level,'slow') 
    % CMV
    iForm_Opts.invFORM.Algorithm = 'CMV';
    iFORM_CMV= uq_createAnalysis(iForm_Opts);
    ResultsiFORM_CMV = iFORM_CMV.Results(end);
    FoundXstar_CMV = ResultsiFORM_CMV.Xstar;
    if norm(FoundXstar_CMV - RealXstar) > abs(FoundXstar - RealXstar) 
        FoundXstar= FoundXstar_CMV;
    end
    
    % HMV
    iForm_Opts.invFORM.Algorithm = 'HMV';
    iFORM_HMV= uq_createAnalysis(iForm_Opts);
    ResultsiFORM_HMV = iFORM_HMV.Results(end);
    FoundXstar_HMV = ResultsiFORM_HMV.Xstar;
    % Use the worst result for the test
    if norm(FoundXstar_HMV - RealXstar) > abs(FoundXstar - RealXstar)
        FoundXstar= FoundXstar_HMV;
    end
end
assignin('base','TestResults', ResultsiFORM);

%% Test the results

if norm(RealXstar - FoundXstar) < eps
    success = 1;
    fprintf('Test uq_test_basic_RS finished successfully!\n');
else
    success = 0;
    fprintf('\n');
    fprintf('uq_test_inverseFORM.\n')
    fprintf('Real Xstar : %e\n',RealXstar);
    fprintf('Found Xstar: %e\n',FoundXstar);
    fprintf('Absolute Error   : %e\n',abs(RealXstar-FoundXstar));
    assignin('base','TestResults',ResultsiFORM);
end
