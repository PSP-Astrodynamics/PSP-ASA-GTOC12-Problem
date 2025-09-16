function pass = uq_default_input_test_inference_copula(level)

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_inference_copula...\n']);

pass = 1;
N=10;   % number of random samples in the tests below

%% Create sample X from a trivariate pdf 
% marginal 1: Gaussian pdf truncated in [1, inf]
% marginal 2: Beta distribution
% marginal 3: Exponential distribution
% copula: independence
clear iOptsTrue
rng(42);

iOptsTrue.Marginals(1).Type = 'Gaussian';
iOptsTrue.Marginals(1).Parameters = [-1,1];
iOptsTrue.Marginals(2).Type = 'Exponential';
iOptsTrue.Marginals(2).Parameters = 1;
iOptsTrue.Marginals(3).Type = 'Uniform';
iOptsTrue.Marginals(3).Parameters = [-1 3];
iOptsTrue.Marginals(4).Type = 'Uniform';
iOptsTrue.Marginals(4).Parameters = [-1 3];
iOptsTrue.Marginals(5).Type = 'Uniform';
iOptsTrue.Marginals(5).Parameters = [-1 3];
iOptsTrue.Copula.Type = 'CVine';   
iOptsTrue.Copula.Structure = [3 1 2 5 4]; 
iOptsTrue.Copula.Truncation = 2;
iOptsTrue.Copula.Families = {...
    'Gaussian', 'Gumbel', 't', 'Frank', ... % 1st tree (4 cop)
    't', 'Independent', 'Gumbel'};         % 2nd tree  (3 cop)
iOptsTrue.Copula.Rotations = [0 90 0 270 0 0 0];
iOptsTrue.Copula.Parameters = {...
    .4, 2, [-.2, 2], .3, ... % 1st tree
    [.2, 3], [], 1.5};       % 2nd tree
myInput5D = uq_createInput(iOptsTrue);

X = uq_getSample(myInput5D, N, 'Sobol');
U = uq_all_cdf(X, myInput5D.Marginals);

%% Test 1: 2D inference. No copula type specified
clear iOpts
fprintf('    test fully automated inference: only data specified')

iOpts.Inference.Data = X(:,1:2);

% make sure no independence test is run: the copula is inferred
iOpts.Inference.PairIndepTest.Alpha = 1;
iOpts.Inference.PairIndepTest.Type = 'Kendall';
iOpts.Inference.PairIndepTest.Correction = 'none';

InputHat = uq_createInput(iOpts);

pass = pass & isfield(InputHat.Copula, 'GoF');
pass = pass & (length(InputHat.Marginals) == 2);
pass = pass & (uq_copula_dimension(InputHat.Copula) == 2);

%% Test 2: equivalent to case 1, Copula.Type set explicitly to 'auto'
iOpts.Copula.Type = 'auto'; 
InputHat = uq_createInput(iOpts);

pass = pass & isfield(InputHat.Copula.GoF, 'PairIndependent');
pass = pass & isfield(InputHat.Copula.GoF, 'PairGaussian');

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Test 3: Use different selection criteria for marginals and for copula
fprintf('    specify inference criterion: ')

iOpts.Copula.Inference.Criterion = 'BIC'; % overwrites iOpts.Inference.Criterion
InputHat = uq_createInput(iOpts);
pass = pass & strcmpi(InputHat.Copula.Inference.Criterion, 'BIC');

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Test 4: Fit a Gaussian copula to 2D data instead
iOpts.Copula.Type = 'Gaussian';
fprintf('    set copula to a specific type (%s): ', iOpts.Copula.Type)

InputHat = uq_createInput(iOpts);

pass = pass & strcmpi(InputHat.Copula.Type, 'Gaussian');
pass = pass & all(strcmpi(unique(fields(InputHat.Copula.GoF)), 'Gaussian'));

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Test 5: (5D) Do not infer the copula parameters, use specified ones
iOpts = struct;
iOpts.Inference.Data = X;
iOpts.Copula.Type = 'Gaussian';
iOpts.Copula.RankCorr = corr(X, 'Type', 'Spearman');
iOpts.Display = 0;
fprintf('    fully specify the %s copula (no copula inference): ', ...
    iOpts.Copula.Type)

InputHat = uq_createInput(iOpts);

pass = pass & strcmpi(InputHat.Copula.Type, 'Gaussian');
pass = pass & all(InputHat.Copula.RankCorr(:) == iOpts.Copula.RankCorr(:));
pass = pass & ~isfield(InputHat.Copula, 'Inference');

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Test 6: Fix the marginals, infer the copula as a Dvine
fprintf('    fix the marginals, infer the copula + structure: ')

rng(101); 
clear iOpts
iOpts.Marginals = iOptsTrue.Marginals; % Assign true marginals, infer copula
iOpts.Copula.Type = 'DVine';
iOpts.Inference.Data = X;
iOpts.Display = 0;
InputHat6 = uq_createInput(iOpts);

pass = pass & strcmpi(InputHat6.Copula.Type, iOpts.Copula.Type);
pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Test 6b: further fix the vine's structure and truncation level
fprintf('    fix the marginals, infer the copula (structure given): ')

clear iOpts
rng(101)
iOpts.Marginals = iOptsTrue.Marginals; % Assign true marginals, infer copula
iOpts.Copula.Type = 'CVine';
iOpts.Copula.Structure = iOptsTrue.Copula.Structure;
iOpts.Copula.Truncation = 3;
iOpts.Inference.Data = X;
iOpts.Display = 0;
InputHat6b = uq_createInput(iOpts);

pass = pass & strcmpi(InputHat6b.Copula.Type, iOpts.Copula.Type);
pass = pass & all(InputHat6b.Copula.Structure == myInput5D.Copula.Structure);
pass = pass & all(InputHat6b.Copula.Truncation == iOpts.Copula.Truncation);

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)


%% Test 7: Infer the copula on different data 
fprintf('    infer the copula on different data than the marginals: ')
rng(101)
iOpts.Copula.Inference.Data = X;
InputHat7 = uq_createInput(iOpts);

pass = pass & all([InputHat7.Copula.Parameters{:}] == ...
                  [InputHat6b.Copula.Parameters{:}]);
              
pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Test 8: Infer the copula on pseudo-obs in the unit hypercube
fprintf('    infer the copula on pseudo-observations in [0,1]^M: ')

clear iOpts
rng(101)
iOpts.Marginals = iOptsTrue.Marginals;
iOpts.Copula.Inference.DataU =  U;
iOpts.Copula.Type = 'DVine';
iOpts.Display = 0;
InputHat8 = uq_createInput(iOpts);

pass = pass & all([InputHat8.Copula.Parameters{:}] == ...
                  [InputHat6.Copula.Parameters{:}]);

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)


