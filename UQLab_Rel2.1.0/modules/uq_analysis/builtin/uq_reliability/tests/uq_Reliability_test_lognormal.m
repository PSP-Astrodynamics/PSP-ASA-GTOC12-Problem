function success = uq_Reliability_test_lognormal(level)
% SUCCESS = UQ_RELIABILITY_TEST_LOGNORMAL(LEVEL):
%     Testing reliability analysis with lognormal variables and analytical
%     failure probability
%
% See also UQ_SELFTEST_UQ_RELIABILITY

uqlab('-nosplash');
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% allowed error
eps = 1e-10;

%% Make the input:
% We have the Resistance and Stress with moments:
Rmean = 10;
Rstd = 1;
Smean = 4;
Sstd = 1;
RealPf = uq_gaussian_cdf(-(Rmean-Smean)/sqrt(Rstd^2 + Sstd^2),[0 1]);
Input.Marginals(1).Name = 'R';Input.Marginals(1).Type = 'Lognormal';Input.Marginals(1).Parameters = [Rmean Rstd];
Input.Marginals(2).Name = 'S';Input.Marginals(2).Type = 'Lognormal';Input.Marginals(2).Parameters = [Smean Sstd];
Input.Copula.Type = 'independent';
Input.Copula.Parameters = eye(2);
Input.Name = 'Input_test_lognormal';
uq_createInput(Input);

%% Create a model:
MOpts.mString = 'log(X(:, 1))-log(X(:, 2))';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% Create and run the analysis:
Form_Opts.Type = 'Reliability';
Form_Opts.Method = 'FORM';
Form_Opts.Display = 'nothing';
Form_Opts.FORM.MaxIterations = 100;
Form_Opts.Gradient.h = 1e-6;
Form_Opts.FORM.Algorithm = 'iHLRf';
Form_Opts.Gradient.Step = 'fixed';
StopEpsilon = 1e-6;
Form_Opts.FORM.StopU = StopEpsilon;
Form_Opts.FORM.StopG = StopEpsilon;
FORM_lognormal = uq_createAnalysis(Form_Opts);


%% Get the results
ResultsFORM = FORM_lognormal.Results(end);

if abs(RealPf - ResultsFORM.Pf) < eps
    success = 1;
    fprintf('Test uq_test_lognormal finished successfully!\n')
else
    success = 0;
    fprintf('\n');
    fprintf('uq_test_lognormal failed.\n')
    fprintf('Real probability : %e\n',RealPf);
    fprintf('Found probability: %e\n',ResultsFORM.Pf);
    fprintf('Absolute Error   : %e\n',abs(RealPf-ResultsFORM.Pf));
    fprintf('Relative Error   : %g%%\n',abs(RealPf-ResultsFORM.Pf)/RealPf*100);
end
