function pass = uq_Dispatcher_tests_uq_getStatusChar(level)
%UQ_DISPATCHER_TESTS_UQ_GETSTATUSCHAR tests the char ID of jobStatusID.
%
%   Summary:
%   The Job status is stored as an integer ID, the function
%   uq_getStatusChar is used to convert the numerical ID to char ID for
%   easier interpretation. This function tests if the conversion works as
%   expected. 
%

%% Initialize test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...', level, mfilename)

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
for i = 1:numel(testFunctions)
    feval(testFunctions{i})
    pass = true;
end

%% Return the results
fprintf('PASS\n')

pass = true;

end


%% ------------------------------------------------------------------------
function testJobStatusPending()
% Test if jobStatusID == 1, it returns the char ID correctly.
jobStatusCharRef = 'pending';
jobStatusID = 1;
jobStatusChar = uq_getStatusChar(jobStatusID);

assert(strcmp(jobStatusCharRef,jobStatusChar))

end


%% ------------------------------------------------------------------------
function testJobStatusSubmitted()
% Test if jobStatusID == 2 job, it returns the char ID correctly.
jobStatusCharRef = 'submitted';
jobStatusID = 2;
jobStatusChar = uq_getStatusChar(jobStatusID);

assert(strcmp(jobStatusCharRef,jobStatusChar))

end


%% ------------------------------------------------------------------------
function testJobStatusRunning()
% Test if jobStatusID == 3, it returns the char ID correctly. 
jobStatusCharRef = 'running';
jobStatusID = 3;
jobStatusChar = uq_getStatusChar(jobStatusID);

assert(strcmp(jobStatusCharRef,jobStatusChar))

end


%% ------------------------------------------------------------------------
function testJobStatusCompleted()
% Test if jobStatusID == 4, it returns the char ID correctly.
jobStatusCharRef = 'complete';
jobStatusID = 4;
jobStatusChar = uq_getStatusChar(jobStatusID);

assert(strcmp(jobStatusCharRef,jobStatusChar))

end


%% ------------------------------------------------------------------------
function testJobStatusCanceled()
% Test if jobStatusID == 0, it returns the char ID correctly.
jobStatusCharRef = 'canceled';
jobStatusID = 0;
jobStatusChar = uq_getStatusChar(jobStatusID);

assert(strcmp(jobStatusCharRef,jobStatusChar))

end


%% ------------------------------------------------------------------------
function testJobStatusError()
% Test if jobStatusID == -1, it returns the char ID correctly. 
jobStatusCharRef = 'failed';
jobStatusID = -1;
jobStatusChar = uq_getStatusChar(jobStatusID);

assert(strcmp(jobStatusCharRef,jobStatusChar))

end
