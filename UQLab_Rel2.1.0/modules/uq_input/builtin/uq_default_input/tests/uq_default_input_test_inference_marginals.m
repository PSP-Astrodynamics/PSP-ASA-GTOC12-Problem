function pass = uq_default_input_test_inference_marginals(level)

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_inference_marginals...\n']);

pass = 1;
N=10;   % number of random samples in the tests below

%% Create sample X from a bivariate pdf 
% marginal 1: Gaussian pdf truncated in [1, inf]
% marginal 2: beta distribution
% copula: independence
rng(100);
iOpts.Marginals(1).Type = 'Gaussian';
iOpts.Marginals(1).Parameters = [0,1];
iOpts.Marginals(1).Bounds = [1,inf];
iOpts.Marginals(2).Type = 'Beta';
iOpts.Marginals(2).Parameters = [6,4];
myInput = uq_createInput(iOpts);
X = uq_getSample(myInput, N);

%% Case 1: Full inference
fprintf('    test fully automated inference: only data specified')
iOpts = struct;
iOpts.Inference.Data = X; 
iOpts.Copula.Variables = [1 2]; % force a single copula
InputHat = uq_createInput(iOpts);

pass = pass & isfield(InputHat.Marginals(1), 'GoF');
pass = pass & (length(InputHat.Marginals) == size(X, 2));
pass = pass & (uq_copula_dimension(InputHat.Copula) == size(X, 2));
pass = pass & all(InputHat.Copula.Variables == [1 2]);

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Case 2: Full inference, change selection criteria
fprintf('    test different inference criteria: ')
Criteria = {'KS', 'ML', 'AIC', 'BIC'};
Stats = {'KSstat','LL', 'AIC', 'BIC'};
Signs = {+1, -1, +1, +1};
for cc = 1:length(Criteria)
    iOpts.Inference.Criterion = Criteria{cc}; 
    fprintf('%s...', Criteria{cc});
    InputHat = uq_createInput(iOpts);
    for ii = 1:length(InputHat.Marginals)
        ChosenDistrib = InputHat.Marginals(ii).Type;
        RefStat = InputHat.Marginals(ii).GoF.(ChosenDistrib).(Stats{cc});
        FittedDistribs = fieldnames(InputHat.Marginals(ii).GoF);
        for ff = 1:length(FittedDistribs)
            Distrib = FittedDistribs{ff};
            Stat = InputHat.Marginals(ii).GoF.(Distrib).(Stats{cc});
            pass = pass & ( Signs{cc} * Stat >= Signs{cc} * RefStat );
        end
    end
end
pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)
            
%% Case 3: truncate the distribution by specifying bounds
fprintf('    inference of bounded distributions...')
iOpts.Marginals(1).Bounds = [1, inf];
InputHat = uq_createInput(iOpts);

pass = pass & (all(InputHat.Marginals(1).Bounds == ...
    iOpts.Marginals(1).Bounds));

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Case 4: Constrain set of families to choose from for marginal 1
fprintf('    inference from a selected set of families...')
iOpts.Marginals(1).Type = {'Gaussian', 'Exponential', 'Weibull'}; 
InputHat = uq_createInput(iOpts);

pass = pass & any(strcmpi(InputHat.Marginals(1).Type, ...
    iOpts.Marginals(1).Type));
pass = pass & all(strcmpi(unique(fields(InputHat.Marginals(1).GoF))', ...
    unique(iOpts.Marginals(1).Type)));

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Case 5: Fix family of marginal 1, and only do parameter fitting
fprintf('    parameter fitting only...')
iOpts.Marginals(1).Type = 'Gaussian';
InputHat = uq_createInput(iOpts);

pass = pass & any(strcmpi(InputHat.Marginals(1).Type, ...
    iOpts.Marginals(1).Type));
pass = pass & all(strcmpi(unique(fields(InputHat.Marginals(1).GoF))', ...
    iOpts.Marginals(1).Type));

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Case 6: Fix marginal 1 (family and parameters), only infer marginal 2
fprintf('    fix one marginal, infer the other...')
iOpts.Marginals(1).Type = 'Gaussian';
iOpts.Marginals(1).Parameters = [0 1];
InputHat = uq_createInput(iOpts);

pass = pass & strcmpi(InputHat.Marginals(1).Type, ...
    iOpts.Marginals(1).Type);
pass = pass & isempty(InputHat.Marginals(1).GoF); %check no inference done

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Case 7: infer marginal 2 by kernel smoothing
fprintf('    inference by kernel smoothing...')
iOpts.Marginals(2).Type = 'ks';
InputHat = uq_createInput(iOpts);

pass = pass & strcmpi(InputHat.Marginals(1).Type, ...
    iOpts.Marginals(1).Type);

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Case 8: Check that the options specified in iOpts.Marginals.Inference 
%  overwrite those under iOpts.Inference correctly
fprintf('    use inference options specific to one marginal only...')

iOpts.Inference.Criterion = 'AIC';
iOpts.Inference.Data = X;
iOpts.Marginals(1).Inference.Criterion = 'BIC';
iOpts.Marginals(1).Inference.Data = X(1:floor(N/2),1);
iOpts.Copula.Type = 'Independent';
InputHat = uq_createInput(iOpts);

pass = pass & strcmpi(InputHat.Marginals(1).Inference.Criterion, ...
    iOpts.Marginals(1).Inference.Criterion);
pass = pass & strcmpi(InputHat.Marginals(2).Inference.Criterion, ...
    iOpts.Inference.Criterion);
pass = pass & all(InputHat.Marginals(1).Inference.Data == ...
    iOpts.Marginals(1).Inference.Data);
pass = pass & all(InputHat.Marginals(2).Inference.Data == ...
    iOpts.Inference.Data(:,2));

clear iOpts
iOpts.Marginals(1).Type = 'auto';
iOpts.Marginals(1).Inference.Data = X(:,1);
iOpts.Marginals(1).Bounds = [1 Inf];
iOpts.Marginals(2).Type = 'Beta';
iOpts.Marginals(2).Inference.Data = X(:,2);
InputHat = uq_createInput(iOpts);

for ii = 1:2
    pass = pass & all(InputHat.Marginals(ii).Inference.Data == ...
        iOpts.Marginals(ii).Inference.Data);
end

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Case 9: check that names are assigned correctly
fprintf('    assign names to marginals to be inferred...')

iOpts.Marginals(1).Name = 'VarA';
iOpts.Marginals(2).Name = 'VarB';
InputHat = uq_createInput(iOpts);

pass = pass & strcmpi(InputHat.Marginals(1).Name, iOpts.Marginals(1).Name);
pass = pass & strcmpi(InputHat.Marginals(2).Name, iOpts.Marginals(2).Name);

pass_str='PASS'; if ~pass, pass_str='FAIL'; end
fprintf(' : %s\n', pass_str)

%% Case 11: Fit custom distribution
% clear iOpts
% myCustom = 'ExampleCustomDistribution';
% iOpts.Inference.Data = X;
% iOpts.Marginals(1).Type = myCustom;
% iOpts.Marginals(1).Bounds = [1 Inf];
% iOpts.Marginals(2).Type = 'Beta';
% iOpts.Inference.ParamBounds.(myCustom) = [-Inf Inf; 0 Inf];
% iOpts.Inference.ParamGuess.(myCustom) = {@mean; @std};
% myInput10 = uq_createInput(iOpts);
% 
% clear iOpts
% myCustom = 'ExampleCustomDistribution';
% iOpts.Inference.Data = X;
% iOpts.Marginals(1).Type = myCustom;
% iOpts.Marginals(1).Bounds = [1 Inf];
% iOpts.Marginals(2).Type = 'Beta';
% iOpts.Marginals(1).Inference.ParamBounds.(myCustom) = [-Inf Inf; 0 Inf];
% iOpts.Marginals(1).Inference.ParamGuess.(myCustom) = {@mean; @std};
% myInput10b = uq_createInput(iOpts);
