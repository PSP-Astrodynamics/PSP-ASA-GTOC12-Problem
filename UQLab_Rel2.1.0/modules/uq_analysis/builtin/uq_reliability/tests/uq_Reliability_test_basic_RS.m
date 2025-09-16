function success = uq_Reliability_test_basic_RS(level)
% SUCCESS = UQ_RELIABILITY_TEST_BASIC_RS(LEVEL)
%     Testing a basic structural reliability analysis (SORM) 
%
% See also: UQ_SELFTEST_UQ_RELIABILITY

uqlab('-nosplash');
if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% error threshold
eps = 1e-10;

%% Make the input:
% We have the Resistance and Stress with moments:
Rmean = 10;
Rstd = 1;
Smean = 4;
Sstd = 1;

%reference failure probability
RealPf = uq_gaussian_cdf(-(Rmean-Smean)/sqrt(Rstd^2 + Sstd^2),[0 1]);

%input marginals
IOpts.Marginals(1).Name = 'R';
IOpts.Marginals(1).Type = 'Gaussian';
IOpts.Marginals(1).Moments = [Rmean Rstd];

IOpts.Marginals(2).Name = 'S';
IOpts.Marginals(2).Type = 'Gaussian';
IOpts.Marginals(2).Moments = [Smean Sstd];

%input copula
IOpts.Copula.Type = 'Independent';
IOpts.Copula.Parameters = eye(2);

IOpts.Name = 'Input_test_RS';

uq_createInput(IOpts);

%% Create a Model:
MOpts.mString = 'X(:, 1) - X(:, 2)';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% Create and run the analysis (HLRF):
Form_Opts.Type = 'Reliability';
Form_Opts.Method = 'SORM';
Form_Opts.FORM.MaxIterations = 100;
Form_Opts.Display = 'quiet';
Form_Opts.Gradient.h = 0.0001;
Form_Opts.FORM.Algorithm = 'HLRf';
Form_Opts.FORM.StopG = 1e-6;
Form_Opts.FORM.StopU = 1e-6;
FORM_simple = uq_createAnalysis(Form_Opts);
ResultsFORM = FORM_simple.Results;
FoundProb = ResultsFORM.Pf;

%% Compare iHLRF too
if strcmpi(level,'slow') 
    Form_Opts.FORM.Algorithm = 'iHLRf';
    FORM_iHLRF = uq_createAnalysis(Form_Opts);
    ResultsFORM_iHLRF = FORM_iHLRF.Results(end);
    iFoundProb = ResultsFORM_iHLRF.Pf;
    
    % Use the worst result for the test
    if abs(iFoundProb - RealPf) > abs(FoundProb - RealPf) 
        FoundProb = iFoundProb;
    end
end
assignin('base','TestResults',ResultsFORM);

%% Test the results

if abs(RealPf - FoundProb) < eps
    success = 1;
    fprintf('Test uq_test_basic_RS finished successfully!\n');
else
    success = 0;
    fprintf('\n');
    fprintf('uq_test_basic_RS failed.\n')
    fprintf('Real probability : %e\n',RealPf);
    fprintf('Found probability: %e\n',FoundProb);
    fprintf('Absolute Error   : %e\n',abs(RealPf-FoundProb));
    fprintf('Relative Error   : %g%%\n',abs(RealPf-FoundProb)/RealPf*100);
    assignin('base','TestResults',ResultsFORM);
end

if isfield(ResultsFORM,'PfSORM') && abs(RealPf - ResultsFORM.PfSORM) > eps
    success = success - 1;
end