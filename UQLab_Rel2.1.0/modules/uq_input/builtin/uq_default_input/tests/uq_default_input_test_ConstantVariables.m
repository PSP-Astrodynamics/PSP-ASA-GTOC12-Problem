function pass = uq_default_input_test_ConstantVariables(level)
%% Test for constant variables

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_ConstantVariables...\n']);

pass = 1;

n = 100;
M = 4;
MaxErr = 1e-10;

% X: variables 1 and 3 are Gaussian, 2 and 4 are constant 1; all independent 
X_Margs = struct;
X_C = 1;
for ii = [1 3]
    X_Margs(ii).Type = 'Gaussian';
    X_Margs(ii).Parameters = [0 1];
    X_Margs(ii+1).Type = 'constant';
    X_Margs(ii+1).Parameters = X_C;
end
X_Copula = uq_IndepCopula(M);

X_Opts.Marginals = X_Margs;
X_Opts.Copula = X_Copula;
X_Input = uq_createInput(X_Opts);

% Y: variables 1 and 3 are LogNormal with t copula, 2 and 4 are constant 0 and
% independent 
Y_Margs = struct;
Y_C = 0;
for ii = [1 3]
    Y_Margs(ii).Type = 'LogNormal';
    Y_Margs(ii).Parameters = [0 1];
    Y_Margs(ii+1).Type = 'constant';
    Y_Margs(ii+1).Parameters = Y_C;
end
Y_Copula(1) = uq_PairCopula('t', [0.4, 2]);
Y_Copula(1).Variables = [1 3];
Y_Copula(2).Type = 'Independent';
Y_Copula(2).Parameters = eye(2);
Y_Copula(2).Variables = [2 4];

Y_Opts.Marginals = Y_Margs;
Y_Opts.Copula = Y_Copula;
Y_Input = uq_createInput(Y_Opts);

% Generate samples from inputs X and Y
X = uq_getSample(X_Input, n);
Y = uq_getSample(Y_Input, n);

% Individual tests on X and Y 
pass1 = all(~isinf(X(:)));
pass2 = all(~isnan(X(:)));
pass3 = all(size(X) == [n, M]);
pass4 = all(X(:, 4) == X_C);
pass5 = all(~isinf(Y(:)));
pass6 = all(~isnan(Y(:)));
pass7 = all(size(Y) == [n, M]);
pass8 = all(Y(:, 4) == Y_C);

% Individual tests on XX and YY, which should be almost identical to X and Y 
XX = uq_GeneralIsopTransform(X, X_Input.Marginals, X_Input.Copula, ...
    X_Input.Marginals, X_Input.Copula);
YY = uq_GeneralIsopTransform(Y, Y_Input.Marginals, Y_Input.Copula, ...
    Y_Input.Marginals, Y_Input.Copula);
pass9 = max(max(abs(XX-X))) < MaxErr;
pass10 = max(max(abs(YY-Y))) < MaxErr;

% Tests for XtoY and YtoX, obtained transforming X (resp Y) into samples
% with joint pdf of Y (resp. X)
XtoY = uq_GeneralIsopTransform(X, X_Input.Marginals, X_Input.Copula, ...
    Y_Input.Marginals, Y_Input.Copula);
YtoX = uq_GeneralIsopTransform(Y, Y_Input.Marginals, Y_Input.Copula, ...
    Y_Input.Marginals, Y_Input.Copula);
pass11 = all(YY(:, 4) == Y_C);
pass12 = all(XX(:, 4) == X_C);

% Check all tests
passes = [pass1 pass2 pass3 pass4 pass5 pass6 pass7 pass8 ...
    pass9 pass10 pass11 pass12];
allpass = all(passes);
pass_str='PASS'; if ~allpass, pass_str='FAIL'; end
pass = pass & allpass;

fprintf('%s! \n', pass_str)
if ~pass
    fprintf('Failed tests: %s. \n', mat2str(find(~passes)))
end


