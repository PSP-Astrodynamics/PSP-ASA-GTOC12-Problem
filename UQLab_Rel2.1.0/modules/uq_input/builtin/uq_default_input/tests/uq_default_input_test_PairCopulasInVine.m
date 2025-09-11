% Define a 4-D CVine and DVine
function pass = uq_default_input_test_PairCopulasInVine(level)

% Initialize
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_default_input_test_PairCopulaCCDF...\n']);

pass = 1;

%% Create CVine and DVine
fams = {'Clayton', 'Gaussian', 'Gumbel', 't', 'Frank', 'Independence'};
pars = {.7, .2, 1.4, [-.2, 2], 0.7, []};
M=4;
Nr_Pairs = length(fams);
VineStruct = [4 2 3 1];

myCVine = uq_VineCopula('CVine', VineStruct, fams, pars);
myDVine = uq_VineCopula('DVine', VineStruct, fams, pars);

%% Check that Indices and CondVars are right

% Check for CVine
fprintf('    CVine: ')
Vars = [4 2; 4 3; 4 1; 2 3; 2 1; 3 1];
[PairCopulas, Indices, Pairs, CondVars] = uq_PairCopulasInVine(...
    myCVine, Vars);
pass1 = all(Indices == 1:Nr_Pairs);
pass2 = isempty([CondVars{1:M-1}]);
pass3 = all([CondVars{M:2*M-3}] == VineStruct(1));
passes = [pass1 pass2 pass3];
thispass = all(passes);
pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
fprintf('%s\n', pass_str);
pass = pass & thispass;

% Check for DVine
fprintf('    DVine: ')
Vars = [4 2; 2 3; 3 1; 4 3; 2 1; 4 1];
[PairCopulas, Indices, Pairs, CondVars] = uq_PairCopulasInVine(...
    myDVine, Vars);
pass1 = all(Indices == 1:Nr_Pairs);
pass2 = isempty([CondVars{1:M-1}]);
pass3 = all([CondVars{M:2*M-3}] == VineStruct(2:M-1));
passes = [pass1 pass2 pass3];
thispass = all(passes);
pass_str='PASS'; if ~thispass, pass_str='FAIL'; end
fprintf('%s\n', pass_str);
pass = pass & thispass;




