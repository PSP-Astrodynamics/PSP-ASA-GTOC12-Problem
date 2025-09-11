function jobID = uq_getJobID(DispatcherObj,jobIdx)
%UQ_GETJOBID gets the Job ID of a Job.
%
%   If the attempt to get the ID failed,
%   the function returns an empty char.
%
%   JOBID = UQ_GETJOBID(DISPATCHEROBJ) gets the Job ID of the lastly
%   created Job in the Dispatcher unit DISPATCHEROBJ.
%
%   JOBID = UQ_GETJOBID(DISPATCHEROBJ,JOBIDX) gets the Job ID
%   of the Job at index JOBIDX.

%% Parse and Verify Inputs

% Verify the number of input arguments
narginchk(1,2)

% Verify the type of input argument
if ~isa(DispatcherObj,'uq_dispatcher')
    error('Input argument must be of *uq_dispatcher* type!')
end

% Verify the content of 'Jobs' property
if isempty(DispatcherObj.Jobs)
    error('There is no Job associated with the Dispatcher unit!')
end

% Assign default value for 'jobIdx'
if nargin < 2
    jobIdx = length(DispatcherObj.Jobs);
end
% Verify 'jobIdx' value
validateattributes(jobIdx, {'double'}, {'scalar', 'positive', 'integer'})

%% Create SSH Connect
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);
% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

%% Get the JobID
remoteSep = DispatcherObj.Internal.RemoteSep;
scheduler = DispatcherObj.Internal.RemoteConfig.Scheduler;
SchedulerVars = DispatcherObj.Internal.RemoteConfig.SchedulerVars;
jobIDPattern = SchedulerVars.SubmitOutputPattern;
remoteFolder = DispatcherObj.Jobs(jobIdx).RemoteFolder;

% Use 'head' command on the relevant files to fetch the Job ID
cmdName = {'cd','head'};
switch scheduler
    case 'none'
        % No scheduler, JobID is the PID of mpirun
        pidFile = DispatcherObj.Internal.RemoteFiles.MPIRunPID;
    otherwise
        % With a scheduler, JobID is issued by the scheduler
        pidFile = DispatcherObj.Internal.RemoteFiles.JobScriptStdOut;
end
% Safe guard against possible whitespaces in the 'remoteFolder'
remoteFolder = uq_Dispatcher_util_writePath(remoteFolder,'linux');
cmdArgs = {{remoteFolder}, {'-1', sprintf('.%s%s', remoteSep, pidFile)}};

try
    [~,jobID] = uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
    jobID = parse_jobID(jobID,jobIDPattern);
catch
    % If something goes wrong during fetching,
    % return an empty JobID
    jobID = '';
end

end


%% ------------------------------------------------------------------------
function parsedJobID = parse_jobID(jobID,jobIDPattern)
%PARSE_JOBID parses the output of the submission command using a scheduler.
%
%   The JobID is extracted using regular expression with pattern specified
%   in jobIDPattern which is specific to the scheduler (if not machine).

jobID = uq_strip(jobID);

parsedJobID = regexpi(jobID, jobIDPattern, 'match');
parsedJobID = parsedJobID{1};

end
