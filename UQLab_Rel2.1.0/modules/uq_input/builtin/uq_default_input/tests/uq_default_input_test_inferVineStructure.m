function pass = uq_default_input_test_inferVineStructure(level)

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |%s| uq_default_input_test_inferVineStructure...\n'], ...
    level);

pass = 1;

% Generate a C-Vine with structure [3 1 2] (= D-Vine with structure [1 3 2])
iOpts.Marginals = uq_StdUniformMarginals(3);
iOpts.Copula.Type = 'CVine';
iOpts.Copula.Families = {'Gaussian', 't', 'Independence'};
iOpts.Copula.Parameters = {-.6, [-.5, 2], []};
iOpts.Copula.Structure = [3 1 2];
myInput = uq_createInput(iOpts);

% Sample from the C-Vine
rng(100)
U = uq_getSample(myInput, 1000);

%% Test that the vine structure is correct

% Test for CVine
CVine_Struct = uq_inferVineStructure(U, 'CVine');
pass = pass & (all(CVine_Struct == iOpts.Copula.Structure) || ...
               all(CVine_Struct == iOpts.Copula.Structure(end:-1:1)));
if pass
    fprintf('    CVine: OK\n')
else
    fprintf('    CVine: FAIL\n')
end

% Test for DVine
DVine_Struct = uq_inferVineStructure(U, 'DVine');
DVine_Struct_true = iOpts.Copula.Structure([2 1 3]);
pass = pass & (all(DVine_Struct == DVine_Struct_true) || ...
               all(DVine_Struct == DVine_Struct_true(end:-1:1)));
if pass
    fprintf('    DVine: OK\n')
else
    fprintf('    DVine: FAIL\n')
end

