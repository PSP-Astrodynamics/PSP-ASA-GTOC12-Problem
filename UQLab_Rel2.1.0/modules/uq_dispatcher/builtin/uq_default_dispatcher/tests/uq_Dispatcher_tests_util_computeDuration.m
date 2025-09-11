function pass = uq_Dispatcher_tests_util_computeDuration(level)
%UQ_Dispatcher_tests_util_computeDuration tests the function to compute
%   the duration between two dates.

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
end

%% Return the results
fprintf('PASS\n')

pass = true;

end


%% ------------------------------------------------------------------------
function testComputeDurationZero()
% Test if the duration is correctly created
datetime1 = '06/03/20 10:29:29 AM';
datetime2 = '06/03/20 10:29:29 AM';

durationRef = '00 hrs 00 mins 00 secs';

duration = uq_Dispatcher_util_computeDuration(datetime1,datetime2);

assert(strcmp(durationRef,duration),...
    'Expect: %s\n,   Get: %s', durationRef, duration)

end

%% ------------------------------------------------------------------------
function testComputeDurationSecs()
% Test if the duration is correctly created
datetime1 = '06/03/20 10:29:29 AM';
datetime2 = '06/03/20 10:29:51 AM';

durationRef = '00 hrs 00 mins 22 secs';

duration = uq_Dispatcher_util_computeDuration(datetime1,datetime2);

assert(strcmp(durationRef,duration),...
    'Expect: %s\n   Get: %s', durationRef, duration)

end

%% ------------------------------------------------------------------------
function testComputeDurationMinutes()
% Test if the duration is correctly created
datetime1 = '06/03/20 10:29:59 PM';
datetime2 = '06/03/20 10:57:19 PM';

durationRef = '00 hrs 27 mins 20 secs';

duration = uq_Dispatcher_util_computeDuration(datetime1,datetime2);

assert(strcmp(durationRef,duration),...
    'Expect: %s\n   Get: %s', durationRef, duration)

end

%% ------------------------------------------------------------------------
function testComputeDurationHours()
% Test if the duration is correctly created
datetime1 = '06/03/20 10:29:59 AM';
datetime2 = '06/03/20 01:55:09 PM';

durationRef = '03 hrs 25 mins 10 secs';

duration = uq_Dispatcher_util_computeDuration(datetime1,datetime2);

assert(strcmp(durationRef,duration),...
    'Expect: %s\n   Get: %s', durationRef, duration)

end

%% ------------------------------------------------------------------------
function testComputeDurationDays()
% Test if the duration is correctly created
datetime1 = '06/03/20 10:29:59 AM';
datetime2 = '13/03/20 11:29:59 PM';

durationRef = '7 days 13 hrs 00 mins 00 secs';

duration = uq_Dispatcher_util_computeDuration(datetime1,datetime2);

assert(strcmp(durationRef,duration),...
    'Expect: %s\n   Get: %s', durationRef, duration)

end

%% ------------------------------------------------------------------------
function testComputeDurationDaysMonthChanged()
% Test if the duration 390 days 13 hrs 05 mins 09 secsis correctly created
datetime1 = '01/01/20 10:29:59 AM';
datetime2 = '06/04/20 11:29:59 PM';

durationRef = '96 days 13 hrs 00 mins 00 secs';

duration = uq_Dispatcher_util_computeDuration(datetime1,datetime2);

assert(strcmp(durationRef,duration),...
    'Expect: %s\n   Get: %s', durationRef, duration)

end

%% ------------------------------------------------------------------------
function testComputeDurationDaysYearChanged()
% Test if the duration is correctly created
datetime1 = '13/01/20 10:24:50 AM';
datetime2 = '06/02/21 11:29:59 PM';

durationRef = '390 days 13 hrs 05 mins 09 secs';

duration = uq_Dispatcher_util_computeDuration(datetime1,datetime2);

assert(strcmp(durationRef,duration),...
    'Expect: %s\n   Get: %s', durationRef, duration)

end

%% ------------------------------------------------------------------------
function testComputeNegativeDuration()
% Test a negative duration
datetime1 = '13/03/21 10:29:59 AM';
datetime2 = '06/02/20 11:29:59 PM';

durationRef = '00 hrs 00 mins 00 secs';

duration = uq_Dispatcher_util_computeDuration(datetime1,datetime2);

assert(strcmp(durationRef,duration),...
    'Expect: %s\n   Get: %s', durationRef, duration)

end


