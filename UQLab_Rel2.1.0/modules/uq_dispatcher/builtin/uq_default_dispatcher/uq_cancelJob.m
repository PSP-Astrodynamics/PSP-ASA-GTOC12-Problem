function uq_cancelJob(DispatcherObj,jobIdx)
%UQ_CANCELJOB cancels a submitted or running Job of a Dispatcher object.
%
%   UQ_CANCELJOB(DISPATCHEROBJ,JOBIDX) cancels a Job in a Dispatcher object
%   DISPATCHEROBJ. The Job is selected by its index JOBIDX (a scalar) and
%   it must either be submitted or running. Only one Job can be canceled at
%   a time.

%% Parse and Verify Inputs

% Inputs are mandatory
if nargin == 0
    error('%s requires a Dispatcher unit and the Job index!',mfilename)
end

% jobIdx is mandatory
if nargin == 1
    error('%s requires the Job index!',mfilename)
end

% Jobs property must not be empty
if isempty(DispatcherObj.Jobs)
    error('%s has no Jobs to cancel in the Dispatcher unit!',mfilename)
end

displayOpt = DispatcherObj.Internal.Display;

%% Check the Status of Selected Job
% 'pending' and finished jobs ('completed', 'failed', 'cancelled') cannot
% be cancelled
[~,status] = uq_getStatus(DispatcherObj,jobIdx);
exemptJobStatus = [-1 0 1 4];
if any(status == exemptJobStatus)
    error('''%s'' Job cannot be cancelled!',uq_getStatusChar(status))
end

%% Set Local Variables
jobID = DispatcherObj.Jobs(jobIdx).JobID;
SchedulerVars = DispatcherObj.Internal.RemoteConfig.SchedulerVars;

%% Create an SSH Connection
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);
% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

%% Send the "Kill" Signal
cmdName = SchedulerVars.CancelCommand;
cmdArgs = {jobID};

try
    if displayOpt > 1
        msg = sprintf('[DISPATCHER] Cancel Job %d from Dispatcher *%s*',...
                jobIdx, DispatcherObj.Name);
        fprintf(uq_Dispatcher_util_dispMsg(msg))
    end
    uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    if displayOpt > 1
        fprintf('(OK)\n')
    end

catch
    uq_cancelJob(DispatcherObj,jobIdx);
end

%% Change the Job Structure and Return Results
status = 0;

Job = DispatcherObj.Jobs(jobIdx);
nowDateTime = uq_Dispatcher_util_getNowDateTime(sshConnect,maxNumTrials);
Job.FinishDateTime = nowDateTime;
Job.LastUpdateDateTime = nowDateTime;
if Job.Status == 2
    % Submitted Job is canceled
    Job.QueueDuration = uq_Dispatcher_util_computeDuration(...
        Job.SubmitDateTime,Job.FinishDateTime);
end
if Job.Status == 3
    % Running Job is canceled
    Job.RunningDuration = uq_Dispatcher_util_computeDuration(...
        Job.StartDateTime,Job.FinishDateTime);
end
Job.Status = status;
DispatcherObj.Jobs(jobIdx) = Job;

end
