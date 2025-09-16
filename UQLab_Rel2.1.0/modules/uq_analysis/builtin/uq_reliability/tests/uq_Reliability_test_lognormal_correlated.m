function success = uq_Reliability_test_lognormal_correlated(level)
% SUCCESS = UQ_RELIABILITY_TEST_LOGNORMAL_CORRELATED(LEVEL):
%     Testing reliability analysis with correlated lognormal variables on a
%     simple R-S problem setup
%
% See also UQ_SELFTEST_UQ_RELIABILITY

uqlab('-nosplash');

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% Allowed error
AllowedError = 1e-2;

%% Make the input:
% We have the Resistance and Stress with moments:
Rmean = 7;
Rstd = 0.5;
Smean = 1;
Sstd = 0.5;
rho = 0.52523; % Normal copula parameter.

% A reference value for the failure probability
RealPf = uq_gaussian_cdf(-4.68,[0 1]); 

% Definition of the input marginals and copula
IOpts.Marginals(1).Name = 'R';IOpts.Marginals(1).Type = 'Lognormal';
IOpts.Marginals(1).Moments = [Rmean Rstd];

IOpts.Marginals(2).Name = 'S';IOpts.Marginals(2).Type = 'Lognormal';
IOpts.Marginals(2).Moments = [Smean Sstd];

IOpts.Copula.Type = 'Gaussian';
IOpts.Copula.Parameters = [1, rho; rho, 1];

IOpts.Name = 'Input_test_lognormal_correlated';

myInput = uq_createInput(IOpts);

%% Create a model:
MOpts.mString = 'X(:, 1) - X(:, 2)';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% Create and run the analysis:
AOpts.Type = 'Reliability';
AOpts.Method = 'FORM';
AOpts.FORM.MaxIterations = 20;
AOpts.Display = 'all';
AOpts.FORM.Algorithm = 'iHLRf';
AOpts.Gradient.Step = 'fixed';
AOpts.Gradient.Method = 'centred';
AOpts.Gradient.h = 1e-6;
StopEpsilon = 1e-4;
AOpts.FORM.StopU = StopEpsilon;
AOpts.FORM.StopG = StopEpsilon;

FORM_lognormal_correlated = uq_createAnalysis(AOpts);

ResultsFORM = FORM_lognormal_correlated.Results;

if abs(RealPf - ResultsFORM.Pf) < AllowedError*RealPf
    success = 1;
    fprintf('Test uq_test_lognormal_correlated finished successfully!\n');
else
    success = 0;
    fprintf('\n');
    fprintf('Test uq_test_lognormal_correlated failed.\n')
    fprintf('Real probability : %e\n',RealPf);
    fprintf('Found probability: %e\n',ResultsFORM.Pf);
    fprintf('Absolute Error   : %e\n',abs(RealPf - ResultsFORM.Pf));
    fprintf('Relative Error   : %g%%\n',abs(RealPf - ResultsFORM.Pf)/RealPf*100);
end