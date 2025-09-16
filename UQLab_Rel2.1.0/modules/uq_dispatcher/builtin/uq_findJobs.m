function [jobIdx,Job] = uq_findJobs(DispatcherObj,varargin)
%UQ_FINDJOB finds a Job(s) according to the values of its properties.
%
%   JOBIDX = uq_findJob(DISPATCHEROBJ) gets all indices JOBIDX of the Jobs
%   associated with a Dispatcher object DISPATCHEROBJ.
%
%   JOBIDX = uq_findJob(DISPATCHEROBJ, NAME, VALUE) finds the Jobs
%   associated with DISPATCHEROBJ whose properties matches the properties
%   specified as NAME/VALUE argument pairs and returns the indices JOBIDX.
%   The supported NAME/VALUE argument pairs are:
%
%       NAME                VALUE
%       'Name'              Name of the Jobs (if specified, regular
%                           expression matching is supported)
%                           Default: ''
%
%       'Status'            Status of the Jobs (if specified, must be exact
%                           to match)
%                           Default: ''
%
%       'JobID'             ID of the Jobs (if specified, must be exact to
%                           match)
%                           Default: ''
%
%       'Tag'               Tag of the Jobs (if specified, regular
%                           expression matching is supported)
%                           Default: ''
%
%       'ExecMode'          Execution mode of the dispatched computation
%                           ('sync' or 'async')
%                           Default: ''
%
%       'SubmitDateTime'    Date and time of the Jobs submitted (if
%                           specified, regular expression matching is
%                           supported)
%                           Default: ''
%
%       'StartDateTime'     Date and time of the Jobs started (if
%                           specified, regular expression matching is
%                           supported)
%                           Default: ''
%
%       'FinishDateTime'    Date and time of the Jobs finished (if
%                           specified, regular expression matching is 
%                           supported)
%                           Default: ''
%
%       'RunningDuration'   Running duration of the Jobs (if specified,
%                           regular expression matching is supported)
%                           Default: ''
%
%       'QueueDuration'     Queue duration of the Jobs (if specified,
%                           regular expression matching is supported)
%                           Default: ''
%
%   JOBIDX = uq_findJob(..., 'Operator', 'Or') finds Jobs that matches the
%   criteria specified by NAME/VALUE argument pairs combined with 'Or'
%   operator. By default, the criteria are matched by 'And' operator.
%
%   [JOBIDX,JOB] = uq_findJob(...) additionally returns the Job objects
%   that match the specified property criteria.

%% Parse and verify inputs

args = varargin;

% Find Job by Name
[jobName,args] = uq_parseNameVal(args, 'Name', '');
JobRef.Name = jobName;

% Find Job by Status (numeric ID)
[jobStatus,args] = uq_parseNameVal(args, 'Status', '');
if ~isempty(jobStatus) && ischar(jobStatus)
    jobStatus = uq_getStatusID(jobStatus);
end
JobRef.Status = jobStatus;

% Find Job by JobID
[jobID,args] = uq_parseNameVal(args, 'JobID', '');
JobRef.JobID = jobID;

% Find Job by Tag
[jobTag,args] = uq_parseNameVal(args, 'Tag', '');
JobRef.Tag = jobTag;

% Find Job by Asynchronous flag
[execMode,args] = uq_parseNameVal(args, 'ExecMode', '');
JobRef.ExecMode = execMode;

% SubmitDateTime
[submitDateTime,args] = uq_parseNameVal(args, 'SubmitDateTime', '');
JobRef.SubmitDateTime = submitDateTime;

% StartDateTime
[startDateTime,args] = uq_parseNameVal(args, 'StartDateTime', '');
JobRef.StartDateTime = startDateTime;

% FinishDateTime
[finishDateTime,args] = uq_parseNameVal(args, 'FinishDateTime', '');
JobRef.FinishDateTime = finishDateTime;

% RunningDuration
[runningDuration,args] = uq_parseNameVal(args, 'RunningDuration', '');
JobRef.RunningDuration = runningDuration;

% QueueDuration
[queueDuration,args] = uq_parseNameVal(args, 'QueueDuration', '');
JobRef.QueueDuration = queueDuration;

% Operator
[operator,args] = uq_parseNameVal(args, 'Operator', 'And');

% Throw warning if args is not exhausted
if ~isempty(args)
    warning('There is %s unsupported Job property.',num2str(numel(args)))
end

%% Switch to different types of Dispatcher

dispatcherType = lower(DispatcherObj.Type);

switch dispatcherType
    case 'uq_default_dispatcher'
        [jobIdx,Job] = uq_findJobs_uq_default_dispatcher(...
            DispatcherObj, JobRef, operator);
    otherwise
        error(...
            'Finding Job(s) for Dispatcher Type *%s* is not supported!',...
            dispatcherType)
end

end
