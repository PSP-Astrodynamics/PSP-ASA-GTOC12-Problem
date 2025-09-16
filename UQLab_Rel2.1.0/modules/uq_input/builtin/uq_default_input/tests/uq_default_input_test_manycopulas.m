function pass = uq_default_input_test_manycopulas(level)
%% Tests uq_createInput, uq_getSample, uq_GeneralIsopTransform for iOpts
% with several copulas

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |%s| uq_default_input_test_manycopulas...\n'], ...
    level);

pass = 1;


%% Check that everything works with one copula for all variables
iOpts = struct;
iOpts.Marginals = uq_StdNormalMarginals(3);
iOpts.Copula = uq_VineCopula('CVine', 1:3, {'Clayton', 'Gumbel', 'Gaussian'}, ...
    {1.4, 2, 0.3}, [0 0 0]);
myInput = uq_createInput(iOpts);
X = uq_getSample(myInput, 10);
pass1 = (size(X,2) == 3);
pass2 = all(myInput.Copula.Variables == 1:3);
passes = [pass1 pass2];
pass = pass && all(passes);

pass_str='PASS'; if ~all(passes), pass_str='FAIL'; end
fprintf('    one copula for all variables : %s\n', pass_str)

%% Make two variables not explicitely coupled.
% check that a second copula (independence) is created among them
iOpts = struct;
iOpts.Marginals = uq_StdUniformMarginals(5);
iOpts.Copula = uq_VineCopula('CVine', 1:3, {'Clayton', 'Gumbel', 'Gaussian'}, ...
    {5, 2, 0.6}, [0 0 0]);
iOpts.Copula.Variables = [1 3 4];
myInput = uq_createInput(iOpts);
X = uq_getSample(myInput, 10);
pass1 = (size(X,2) == 5);
pass2 = uq_isIndependenceCopula(myInput.Copula(2));
pass3 = all(myInput.Copula(2).Variables == [2 5]);
passes = [pass1 pass2 pass3];
pass = pass && all(passes);

pass_str='PASS'; if ~all(passes), pass_str='FAIL'; end
fprintf('    one copula, two variables not assigned: %s\n', pass_str)

%% Check for an input with two copula explicitely encompassing all variables
iOpts = struct;
iOpts.Marginals = uq_StdNormalMarginals(5);
iOpts.Copula(1) = uq_VineCopula('CVine', 1:3, {'Clayton', 'Gumbel', 'Gaussian'}, ...
    {1.4, 2, 0.3}, [0 0 0]);
iOpts.Copula(1).Variables = [1 4 5];
iOpts.Copula(2) = uq_GaussianCopula([1 -.5; -.5 1]);
iOpts.Copula(2).Variables = [2 3];
myInput = uq_createInput(iOpts);
X = uq_getSample(myInput, 10);
pass1 = all(size(X) == [10,5]);
pass2 = all(myInput.Copula(1).Variables == iOpts.Copula(1).Variables);
pass3 = all(myInput.Copula(2).Variables == iOpts.Copula(2).Variables);
passes = [pass1 pass2 pass3];
pass = pass && all(passes);

pass_str='PASS'; if ~all(passes), pass_str='FAIL'; end
fprintf('    two copulas among all variables: %s\n', pass_str)

%% Define 3 copulas; variable 5 is not covered, check that it is assigned
% a separate independent copula
iOpts = struct;
iOpts.Marginals = uq_StdNormalMarginals(8);
iOpts.Copula(1) = uq_VineCopula('CVine', 1:3, {'Clayton', 'Gumbel', 'Gaussian'}, ...
    {1.4, 2, 0.3}, [0 0 0]);
iOpts.Copula(1).Variables = [1 4 6];
iOpts.Copula(2) = uq_GaussianCopula([1 -.5; -.5 1]);
iOpts.Copula(2).Variables = [3 7];
iOpts.Copula(3) = uq_PairCopula('t', [.5 2], 0);
iOpts.Copula(3).Variables = [2 8];
myInput = uq_createInput(iOpts);

X = uq_getSample(myInput, 10);
pass1 = all(size(X) == [10, 8]);

pass2 = length(myInput.Copula) == 4;
pass3 = all(myInput.Copula(1).Variables == iOpts.Copula(1).Variables);
pass4 = all(myInput.Copula(3).Variables == iOpts.Copula(3).Variables);
pass5 = strcmpi(myInput.Copula(1).Type, iOpts.Copula(1).Type);
pass6 = uq_isIndependenceCopula(myInput.Copula(4));
pass7 = myInput.Copula(4).Variables == 5;

passes = [pass1 pass2 pass3 pass4 pass5 pass6 pass7];
pass = pass && all(passes);

pass_str='PASS'; if ~all(passes), pass_str='FAIL'; end
fprintf('    three copulas among all variables, two vars not assigned : %s\n', pass_str)

%% Check various isoprobabilistic transforms
U = uq_GeneralIsopTransform(X, myInput.Marginals, myInput.Copula, ...
    myInput.Marginals, myInput.Copula);
pass = pass & max(abs(U(:)-X(:)))<1e-9;

