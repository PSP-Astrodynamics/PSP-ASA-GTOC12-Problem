function pass = uq_default_input_test_manycopulas(level)
%% Tests uq_createInput, uq_getSample, uq_GeneralIsopTransform for iOpts
% with several copulas

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |%s| uq_default_input_test_manycopulas...\n'], ...
    level);

pass = 1;


%% Sample realizations X from a 6D input with:
% * standard normal marginals (not really important)
% * a vine copula among [1 4 6]
% * a gaussian copula among [2 5]
% * an individual variable (3) independent of all others
iOpts = struct;
iOpts.Marginals = uq_StdNormalMarginals(6);
iOpts.Copula(1) = uq_VineCopula('CVine', 1:3, {'Clayton', 'Gumbel', 'Gaussian'}, ...
    {1.4, 2, 0.3}, [0 0 0]);
iOpts.Copula(1).Variables = [1 4 6];
iOpts = uq_add_copula(iOpts, uq_PairCopula('t', [.5 2], 0));
iOpts.Copula(2).Variables = [2 5];
myInput = uq_createInput(iOpts);

X = uq_getSample(myInput, 200);

%% Infer blindly
iOpts = struct;
iOpts.Inference.Data = X;
InputHat = uq_createInput(iOpts);
X = uq_getSample(myInput, 10);

pass = pass && (size(X, 2) == 6);

%% Enforce one copula
iOpts = struct;
iOpts.Inference.Data = X;
iOpts.Copula(1).Variables = 1:6;
InputHat = uq_createInput(iOpts);

pass = pass && (length(InputHat.Copula) == 1);
pass = pass && all(InputHat.Copula.Variables == 1:6);

%% Enforce three copulas (one implicit) between fixed variables
iOpts = struct;
iOpts.Inference.Data = X;
iOpts.Copula(1).Variables = [1 4 6];
iOpts.Copula(2).Variables = [2 5];
InputHat = uq_createInput(iOpts);

pass = pass && (length(InputHat.Copula) == 3);
pass = pass && all(InputHat.Copula(1).Variables == [1 4 6]);
pass = pass && all(InputHat.Copula(2).Variables == [2 5]);
pass = pass && all(InputHat.Copula(3).Variables == 3);

