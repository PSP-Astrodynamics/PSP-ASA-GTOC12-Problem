% Define a 4-D CVine and DVine
function pass = uq_default_input_test_ManualVine(level)

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_ManualVine...\n']);

pass = 1;

%% Create CVine
iOpts.Marginals = uq_StdUniformMarginals(4);

iOpts.Copula(1).Type = 'CVine';
iOpts.Copula(1).Families = {'Gumbel', 'Gumbel', 'Gumbel', 'Gumbel', 'Gumbel', 'Gumbel'};
iOpts.Copula(1).Parameters = {1.5, 1.5, 1.5, 1.5, 1.5, 1.5};
iOpts.Copula(1).Variables = [1 2 3 4];
iOpts.Copula(1).Structure = [3 2 1 4];

% .Rotations should be created automatically, and default to a vector of 0s

try
    uq_createInput(iOpts, '-private');
    pass_c = 1;
catch 
    pass_c = 0;
end

%% Truncate CVine
iOpts.Copula(1).Truncation = 1; % only 3 pairs

try
    uq_createInput(iOpts, '-private');
    pass_c_trunc = 1;
catch 
    pass_c_trunc = 0;
end


%% Create DVine
clear iOpts 
iOpts.Marginals = uq_StdUniformMarginals(4);

iOpts.Copula(1).Type = 'DVine';
iOpts.Copula(1).Families = {'Gumbel', 'Gumbel', 'Gumbel', 'Gumbel', 'Gumbel', 'Gumbel'};
iOpts.Copula(1).Parameters = {1.5, 1.5, 1.5, 1.5, 1.5, 1.5};
iOpts.Copula(1).Variables = [1 2 3 4];
iOpts.Copula(1).Structure = [3 2 1 4];

% .Rotations should be created automatically, and default to a vector of 0s

try
    uq_createInput(iOpts, '-private');
    pass_d = 1;
catch 
    pass_d = 0;
end

%% Truncate DVine
iOpts.Copula(1).Truncation = 1; % only 3 pairs

try
    uq_createInput(iOpts, '-private');
    pass_d_trunc = 1;
catch 
    pass_d_trunc = 0;
end



%% Check that all tests passed

passes = [pass_c pass_c_trunc pass_d pass_d_trunc];
pass = all(passes);
pass_str='    PASS'; if ~pass, pass_str='    FAIL'; end
fprintf('%s\n', pass_str);
