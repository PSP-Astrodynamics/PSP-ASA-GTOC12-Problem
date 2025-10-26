function success = uq_Reliability_test_cubic_RS_constant(level)
% SUCCESS = UQ_RELIABILITY_TEST_CUBIC_RS(LEVEL):
%     Testing SORM on a cubic limit-state function with a linear limit-state
%     surface in the presence of constants
%
% See also: UQ_SELFTEST_UQ_RELIABILITY

uqlab('-nosplash');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% error threshold
eps = 1e-9;

%% Make the input:
% We have the Resistance and Stress with moments:
Rmean = 10;
Rstd = 1;
Smean = 4;
Sstd = 1;

%reference value for the failure probability
RealPf = uq_gaussian_cdf(-(Rmean-Smean)/sqrt(Rstd^2 + Sstd^2),[0 1]);

%input marginals
IOpts.Marginals(1).Name = 'R';
IOpts.Marginals(1).Type = 'Gaussian';
IOpts.Marginals(1).Moments = [Rmean Rstd];

IOpts.Marginals(2).Name = 'irrelevant';
IOpts.Marginals(2).Type= 'constant'; 
IOpts.Marginals(2).Parameters = 1;

IOpts.Marginals(3).Name = 'S';
IOpts.Marginals(3).Type = 'Gaussian';
IOpts.Marginals(3).Moments = [Smean Sstd];

IOpts.Marginals(4).Name = 'irrelevant';
IOpts.Marginals(4).Type= 'Constant'; 
IOpts.Marginals(4).Parameters = 0;

IOpts.Copula.Type = 'Independent';
IOpts.Copula.Parameters = eye(2);

IOpts.Name = 'Input_test_RS_cubic_constant';

myInput = uq_createInput(IOpts, '-private');

%% Create a model:
MOpts.mString = '(X(:, 1).^3 - X(:, 3).^3).*X(:,2).^4 + X(:,4)';
MOpts.isVectorized = true;
myModel = uq_createModel(MOpts, '-private');

%% Create and run the analysis:
Form_Opts.Type = 'Reliability';
Form_Opts.Model = myModel;
Form_Opts.Input = myInput;

% Options for the FORM analysis:
Form_Opts.Method = 'SORM';
Form_Opts.FORM.MaxIterations = 100;
Form_Opts.Display = 'Quiet';
Form_Opts.FORM.Algorithm = 'iHLRF';
Form_Opts.Gradient.Method = 'forward';
Form_Opts.Gradient.Step = 'relative';
Form_Opts.Gradient.h = 0.0001;
StopEpsilon = 1e-6;
Form_Opts.FORM.StopU = StopEpsilon;
Form_Opts.FORM.StopG = StopEpsilon;

FORM_simple = uq_createAnalysis(Form_Opts, '-private');

% Run the analysis:
ResultsFORMSORM = FORM_simple.Results;

AllProbsFound = [ResultsFORMSORM.PfSORM, ResultsFORMSORM.Pf];

%% Compare iHLRF too
if strcmpi(level,'slow') 
    Form_Opts.FORM.Algorithm = 'iHLRf';
    FORM_iHLRF = uq_createAnalysis(Form_Opts, '-private');

    % Run the analysis:
    ResultsFORM_iHLRF = FORM_iHLRF.Results;
    AllProbsFound = [AllProbsFound ResultsFORM_iHLRF.Pf, ResultsFORM_iHLRF.PfSORM];
end

%% Results comparison
% From all the found probabilities, choose the worst:
[DummyError, Pos] = max(abs(AllProbsFound - RealPf));
FoundProb = AllProbsFound(Pos);

% They should approximate the real probability and, for this example, all
% of them should be the same
if abs(RealPf - FoundProb) < eps && sum(abs(AllProbsFound-mean(AllProbsFound))) < eps
    success = 1;
    fprintf('Test uq_test_cubic_RS finished successfully!\n');
else
    success = 0;
    fprintf('\n');
    fprintf('Test Cubic_RS failed.\n')
    fprintf('Real probability : %e\n',RealPf);
    fprintf('Found probability: %e\n',FoundProb);
    fprintf('Absolute Error   : %e\n',abs(RealPf-FoundProb));
    fprintf('Relative Error   : %g%%\n',abs(RealPf-FoundProb)/RealPf*100);
    assignin('base','TestResults',ResultsFORMSORM);
end