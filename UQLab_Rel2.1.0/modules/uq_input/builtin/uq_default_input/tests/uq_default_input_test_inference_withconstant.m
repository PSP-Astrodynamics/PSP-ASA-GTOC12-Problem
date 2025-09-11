function pass = uq_default_input_test_inference_withconstant(level)
%% Test for constant variables

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_inference_withconstant...\n']);

rng(101);
pass = 1;
n = 10;

%% Input X: X_[1,3,5] are Gaussian with Gaussian copula, X_[2,4] are constant
clear X_Opts
X_C = sqrt(2);
X_Opts.Marginals([1 3 5]) = uq_StdNormalMarginals(3);
X_Opts.Marginals([2 4]) = uq_ConstantMarginals([X_C X_C]);
X_Opts.Copula(1) = uq_GaussianCopula([1 .2 .4; .2 1 .5; .4 .5 1]);
X_Opts.Copula(1).Variables = [1 3 5];

X_Input = uq_createInput(X_Opts);
X = uq_getSample(X_Input, n);

M = size(X, 2);
idNonConst = uq_find_nonconstant_marginals(X_Input.Marginals);
idConst = uq_find_constant_marginals(X_Input.Marginals);

%% Inference from data X, no additional info known
fprintf('    blind inference (only data available): ')
clear OptsHat
OptsHat.Inference.Data = X;
InputHat = uq_createInput(OptsHat);

% Check that the inferred input has the right constant variables
pass1 = true;
for ii = idConst
    pass1 = pass1 && strcmpi(InputHat.Marginals(idConst(1)).Type, 'constant');
    pass1 = pass1 && (InputHat.Marginals(idConst(1)).Parameters == X_C);
end

% Check that the inferred input has a last independent copula among the
% constant variables
pass2 = all(InputHat.Copula(end).Variables == idConst) && ...
        uq_isIndependenceCopula(InputHat.Copula(end));

passes = [pass1 pass2];
allpass = all(passes);
pass_str='PASS'; if ~allpass, pass_str='FAIL'; end
pass = pass & allpass;

fprintf('%s! \n', pass_str)
if ~pass
    fprintf('Failed tests: %s. \n', mat2str(find(~passes)))
end

%% Inference from data X, rightly specify one marginal as constant
fprintf('    rightly specify one marginal as constant, but no parameter given: ')
clear OptsHat
OptsHat.Marginals(idConst(1)).Type = 'Constant';
OptsHat.Inference.Data = X;
InputHat = uq_createInput(OptsHat);

% Check that the inferred input has the right constant variables
pass1 = true;
for ii = idConst
    pass1 = pass1 && strcmpi(InputHat.Marginals(idConst(1)).Type, 'constant');
    pass1 = pass1 && (InputHat.Marginals(idConst(1)).Parameters == X_C);
end

% Check that the inferred input has a last independent copula among the
% constant variables
pass2 = all(InputHat.Copula(end).Variables == idConst) && ...
        uq_isIndependenceCopula(InputHat.Copula(end));

passes = [pass1 pass2];
allpass = all(passes);
pass_str='PASS'; if ~allpass, pass_str='FAIL'; end
pass = pass & allpass;

fprintf('%s! \n', pass_str)
if ~pass
    fprintf('    -> failed tests: %s. \n', mat2str(find(~passes)))
end

%% Inference from data X, rightly specify one marginal as constant with param
fprintf('    rightly specify one marginal as constant, correct parameter given: ')
clear OptsHat
OptsHat.Marginals(idConst(1)).Type = 'Constant';
OptsHat.Marginals(idConst(1)).Parameters = X_C;
OptsHat.Inference.Data = X;
InputHat = uq_createInput(OptsHat);

% Check that the inferred input has the right constant variables
pass1 = true;
for ii = idConst
    pass1 = pass1 && strcmpi(InputHat.Marginals(idConst(1)).Type, 'constant');
    pass1 = pass1 && (InputHat.Marginals(idConst(1)).Parameters == X_C);
end

% Check that the inferred input has a last independent copula among the
% constant variables
pass2 = all(InputHat.Copula(end).Variables == idConst) && ...
        uq_isIndependenceCopula(InputHat.Copula(end));

passes = [pass1 pass2];
allpass = all(passes);
pass_str='PASS'; if ~allpass, pass_str='FAIL'; end
pass = pass & allpass;

fprintf('%s! \n', pass_str)
if ~pass
    fprintf('    -> failed tests: %s. \n', mat2str(find(~passes)))
end

%% Inference from data X, rightly specify one marginal as constant with param
fprintf('    force non-constant variables to be coupled together by first copula: ')
clear OptsHat
OptsHat.Copula(1).Variables = idNonConst;
OptsHat.Inference.Data = X;
InputHat = uq_createInput(OptsHat);

% Check that the inferred input has the right constant variables
pass1 = true;
for ii = idConst
    pass1 = pass1 && strcmpi(InputHat.Marginals(idConst(1)).Type, 'constant');
    pass1 = pass1 && (InputHat.Marginals(idConst(1)).Parameters == X_C);
end

% Check that the inferred input has a last independent copula among the
% constant variables
pass2 = all(InputHat.Copula(end).Variables == idConst) && ...
        uq_isIndependenceCopula(InputHat.Copula(end));

passes = [pass1 pass2];
allpass = all(passes);
pass_str='PASS'; if ~allpass, pass_str='FAIL'; end
pass = pass & allpass;

fprintf('%s! \n', pass_str)
if ~pass
    fprintf('    -> failed tests: %s. \n', mat2str(find(~passes)))
end

%% Concatenate two samples of X_Input horizontally and perform inference
fprintf('    generate data in dimension 10 by concatenating [X X], and force \n')
fprintf('        non-constant variables to be coupled together by copula 1 and 2: ')
X2 = [X uq_getSample(X_Input, n)];
clear OptsHat
OptsHat.Copula(1).Variables = idNonConst;
OptsHat.Copula(2).Variables = idNonConst+M;
OptsHat.Inference.Data = X2;
InputHat = uq_createInput(OptsHat);
idConst_all = [idConst idConst+M];

% Check that the inferred input has the right constant variables
pass1 = true;
for ii = idConst_all
    pass1 = pass1 && strcmpi(InputHat.Marginals(ii).Type, 'constant');
    pass1 = pass1 && (InputHat.Marginals(ii).Parameters == X_C);
end

% Check that the inferred input has a last independent copula among the
% constant variables
pass2 = all(InputHat.Copula(end).Variables == idConst_all) && ...
        uq_isIndependenceCopula(InputHat.Copula(end));

% Check that the first two copulas of the inferred input couple the correct
% non-constant variables
pass3 = all(InputHat.Copula(1).Variables == idNonConst) && ...
        all(InputHat.Copula(2).Variables == idNonConst+M);

passes = [pass1 pass2 pass3];
allpass = all(passes);
pass_str='PASS'; if ~allpass, pass_str='FAIL'; end
pass = pass & allpass;

fprintf('%s! \n', pass_str)
if ~pass
    fprintf('    -> failed tests: %s. \n', mat2str(find(~passes)))
end


