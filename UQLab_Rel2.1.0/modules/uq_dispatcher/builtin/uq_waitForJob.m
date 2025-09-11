function waitStatus = uq_waitForJob(DispatcherObj,varargin)
%UQ_WAITFORJOB waits for a Job to finish.
%
%   uq_waitForJob(DISPATCHEROBJ) waits for the lastly created Job
%   associated with the Dispatcher object DISPATCHEROBJ to finish.
%
%   uq_waitForJob(DISPATCHEROBJ,JOBIDX) waits for a Job associated with
%   DISPATCHEROBJ selected by its index JOBIDX (a scalar) to finish. Only
%   one Job can be waited for at time.
%
%   uq_waitForJob(..., NAME, VALUE) waits for a Job with additional
%   (optional) NAME/Value argument pairs.
%
%       Name            Value
%       'JobStatus'     Status of the Job to reach.
%                       Default: 4 (i.e., complete)
%       'WaitTimeout'   Maximum time to wait (in seconds).
%                       Default: DispatcherObj.Internal.Timeout
%       'CheckInterval' Time interval to check the Job status in the remote
%                       machine (in seconds).
%                       Default: DispatcherObj.Internal.CheckInterval
%
%   WAITSTATUS = uq_waitForJob(...) returns if the specified Job status
%   has actually actually been reached at the end the wait.
%
%   See also uq_getStatus, uq_updateStatus.

%% Parse and verify inputs

args = varargin;

% Get the number of Jobs in the DISPATCHER unit
numJobs = numel(DispatcherObj.Jobs);

% Check if there's a Job at all to wait for
if numJobs == 0
    error('No Job is associated with DISPATCHER unit **%s**.',...
        DispatcherObj.Name)
end

% If no particular Job is specified, use the lastly created Job
if nargin == 1
    jobIdx = numJobs;
end

% If two or odd arguments are given, the second one is the job index
if nargin == 2 || mod((nargin-1),2) == 1
    jobIdx = varargin{1};
    args = args(2:end);
end

if mod(nargin-1,2) == 0
    jobIdx = numJobs;
end

% Wait until Status reached (Default: wait until complete)
[jobStatus,args] = uq_parseNameVal(args, 'JobStatus', 4);

currentJobStatus = DispatcherObj.Jobs(jobIdx).Status;
switch currentJobStatus

    case -1
        % Job status is error, return immediately
        return

    case 0
        % Job status is canceled, return immediately
        return

    case 1
        % Job status is pending, return immediately
        return

    case 2
        % Job status is submitted
        if any(jobStatus == [0 1])
            error('%s Job can''t be wait for until %s.',...
                uq_getStatusChar(currentJobStatus),...
                uq_getStatusChar(jobStatus))
        end
        
        if jobStatus == 2
            % Already submitted; return immediately
            return
        end

    case 3
        % Job status is running
        if any(jobStatus == [0 1 2])
            error('%s Job can''t be wait for until %s.',...
                uq_getStatusChar(currentJobStatus),...
                uq_getStatusChar(jobStatus))
        end
        
        if jobStatus == 3
            % Already running; return immediately
            return
        end

    case 4
        % Job status is complete, return immediately
        return
end

% Wait until timeout etime(clock,startTime) < WaitTimeout
waitTimeoutDefault = 600;  % 10 minutes
[waitTimeout,args] = uq_parseNameVal(...
    args, 'WaitTimeout', waitTimeoutDefault);

% Do status update only at certain interval
[checkInterval,args] = uq_parseNameVal(...
    args, 'CheckInterval', DispatcherObj.Internal.CheckInterval);

% Check interval can't be larger than timeout

% Throw warning if args is not exhausted
if ~isempty(args)
    warning('There is unsupported NAME/VALUE argument pairs.')
end

%% Switch to different types of Dispatcher

dispatcherType = lower(DispatcherObj.Type);

switch dispatcherType
    case 'uq_default_dispatcher'
        waitStatusTemp = uq_waitForJob_uq_default_dispatcher(...
            DispatcherObj, jobIdx, jobStatus, waitTimeout, checkInterval);
        if nargout
            waitStatus = waitStatusTemp;
        end
    otherwise
        error(...
            'Waiting for Job(s) for Dispatcher Type *%s* is not supported!',...
            dispatcherType)
end

end
