function pass = uq_Dispatcher_tests_uq_mapBash(level)
%
%
%   Summary:
%   

%% Initialize test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...\n', level, mfilename)

pass = false;

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
for i = 1:numel(testFunctions)
    feval(testFunctions{i})
    pass = true;
end

end

%% ------------------------------------------------------------------------
% Test if a map job can be created

% Test if a map job can be submitted

% Test if a map Job status can be updated

% Test if a map Job status can be queried

% Test if a map Job can be cleaned

% Test if a map Job can be resubmitted after being cleaned

% Test if a map Job can be deleted

% Test calling uq_map with various inputs and options