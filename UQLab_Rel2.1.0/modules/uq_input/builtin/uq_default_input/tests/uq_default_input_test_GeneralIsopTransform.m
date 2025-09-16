function pass = uq_default_input_test_GeneralIsopTransform(level)
%% Test for general isoprobabilistic transform. 
% The current function tests the efficient implementation of
% Gaussian-Gaussian and Gamma-Gamma transform

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_GeneralIsopTransform...\n']);

pass = 1;

n = 100;
M = 5;
MaxErr = 1e-10;
% X: variables 1 and 3 are Gaussian, 2 and 4 are constant Gamma, 5 is
% constant, the first two variables are coupled by a Gaussian copula
X_Margs = struct;
for ii = [1,3]
    X_Margs(ii).Type = 'Gaussian';
    X_Margs(ii).Parameters = [2 3];
    X_Margs(ii+1).Type = 'Gamma';
    X_Margs(ii+1).Parameters = [4 5];
end
SigmaX = [1,0.5;0.5,1];
X_Copula = uq_GaussianCopula(SigmaX);
X_Copula.Variables = [1,3];
X_Opts.Copula = X_Copula;
X_Opts.Marginals = X_Margs;
X1_input = uq_createInput(X_Opts);

X_Margs(5).Type = 'Constant';
X_Margs(5).Parameters = 2;
X_Opts.Marginals = X_Margs;
X_Opts.Copula = X_Copula;
X_Input = uq_createInput(X_Opts);

rng(1);
X = uq_getSample(X_Input, n);

% Y: variables 1 and 3 are Gaussian, 2 and 4 are constant Gamma, 5 is
% constant, independent copula
Y_Margs = struct;
for ii = [1,3]
    Y_Margs(ii).Type = 'Gaussian';
    Y_Margs(ii).Parameters = [0 1];
    Y_Margs(ii+1).Type = 'Gamma';
    Y_Margs(ii+1).Parameters = [2 5];
end
SigmaY = [1,-0.2;-0.2,1];
Y_Copula = uq_GaussianCopula(SigmaY);
Y_Copula.Variables = [1,3];
Y_Opts.Copula(1) = Y_Copula;
Y_Opts.Copula(2).Type = 'Independent';
Y_Opts.Copula(2).Variables = [4,2];
Y_Opts.Marginals = Y_Margs;
Y1_input = uq_createInput(Y_Opts);

Y_Margs(5).Type = 'Constant';
Y_Margs(5).Parameters = 1;
Y_Opts.Marginals = Y_Margs;
Y_Input = uq_createInput(Y_Opts);

U = uq_RosenblattTransform(X(:,1:4), X1_input.Marginals, X1_input.Copula);
Y1 = uq_invRosenblattTransform(U, Y1_input.Marginals, Y1_input.Copula);
Y2 = uq_GeneralIsopTransform(X, X_Input.Marginals, X_Input.Copula, Y_Input.Marginals, Y_Input.Copula);

% check whether the program uses the efficient algorithm
cond = Y2(:,1:4)~=Y1;
pass1 = any(cond(:));

% check whether the efficent algorithm works correctly
absDiff = abs(Y2(:,1:4)-Y1);
cond = max(absDiff(:));
pass2 = cond < MaxErr;

% double check
X2 = uq_GeneralIsopTransform(Y2, Y_Input.Marginals, Y_Input.Copula, X_Input.Marginals, X_Input.Copula);
absDiff = abs(X2-X);
cond = max(absDiff(:));
pass3 = cond < MaxErr;

% Check all tests
passes = [pass1 pass2 pass3];
allpass = all(passes);
pass_str='PASS'; if ~allpass, pass_str='FAIL'; end
pass = pass & allpass;

fprintf('%s! \n', pass_str)
if ~pass
    fprintf('Failed tests: %s. \n', mat2str(find(~passes)))
end


