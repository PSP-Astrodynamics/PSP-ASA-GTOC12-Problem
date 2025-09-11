function uq_print_uq_default_dispatcher(DispatcherObj,jobIdx)
%UQ_PRINT_UQ_DEFAULT_DISPATCHER pretty prints information on the Dispatcher object.
%   See also UQ_KRIGING_DISPLAY, UQ_PCE_PRINT, UQ_PRINT_UQ_METAMODEL.

%% Check inputs

if nargin < 2
    if isprop(DispatcherObj,'Jobs') && ~isempty(DispatcherObj.Jobs)
        jobIdx = numel(DispatcherObj.Jobs);
    else
        jobIdx = 0;
    end
end
 
fprintf('\n')
% Print the top delimiter
print_delim('Dispatcher object')

% Print Common
print_Common(DispatcherObj)

% Print Cluster Profile
print_Cluster(DispatcherObj)

% Print Job Details (if it's there)
% Exit function if no jobs are associated with the Dispatcher unit
print_JobDetails(DispatcherObj,jobIdx)

% Print the bottom delimiter
print_delim()

fprintf('\n')

end

%% ------------------------------------------------------------------------
function print_Common(DispatcherObj)
%PRINT_COMMON prints out the common information of a Dispatcher unit.

% Collect relevant variables
Common.Name.Label = 'Object Name';
Common.Name.Value = DispatcherObj.Name;
Common.NumProcs.Label = 'Number of Processes';
Common.NumProcs.Value = DispatcherObj.NumProcs;
Common.NoJobs.Label = 'Number of Jobs';
if isprop(DispatcherObj,'Jobs') && ~isempty(DispatcherObj.Jobs)
    noJobs = numel(DispatcherObj.Jobs);
else
    noJobs = 0;
end
Common.NoJobs.Value = noJobs;

% Print out the common information
fprintf_Report(Common)

end

%% ------------------------------------------------------------------------
function print_Cluster(DispatcherObj)
%PRINT_CLUSTER prints out the cluster information of a Dispatcher unit.

Cluster.Label = 'Remote Profile';
Cluster.Name.Label = 'Name';
Cluster.Name.Value = DispatcherObj.Profile;
isPuTTY = strcmpi(DispatcherObj.Internal.SSHClient.Name,'putty');
if isPuTTY && ~isempty(DispatcherObj.Internal.RemoteConfig.SavedSession)
    Cluster.SessionName.Label = 'Session Name';
    Cluster.SessionName.Value = ...
        DispatcherObj.Internal.RemoteConfig.SavedSession;
else
    Cluster.Hostname.Label = 'Hostname';
    Cluster.Hostname.Value = DispatcherObj.Internal.RemoteConfig.Hostname;
    Cluster.Username.Label = 'Username';
    Cluster.Username.Value = DispatcherObj.Internal.RemoteConfig.Username;
end
Cluster.RemoteFolder.Label = 'Remote location';
Cluster.RemoteFolder.Value = DispatcherObj.RemoteLocation;

% Print out the cluster information
fprintf('\n')
fprintf_Report(Cluster)

end

%% ------------------------------------------------------------------------
function print_JobDetails(DispatcherObj,jobIdx)
%
if jobIdx == 0
    return
end

Job = DispatcherObj.Jobs(jobIdx);

% Collect the job details information
JobDetails.Label = sprintf('Job Details (%s)',num2str(jobIdx));

JobDetails.Status.Label = 'Status';
JobDetails.Status.Value = uq_getStatusChar(Job.Status);

JobDetails.JobID.Label = 'JobID';
JobDetails.JobID.Value = Job.JobID;

JobDetails.ExecMode.Label = 'Execution mode';
isAsync = uq_Dispatcher_util_isAsync(Job.ExecMode);
if isAsync
    JobDetails.ExecMode.Value = 'Non-synchronized (''async'')';
else
    JobDetails.ExecMode.Value = 'Synchronized (''sync'')';
end

JobDetails.NumOfOutArgs.Label = 'Num. of out. args.';
JobDetails.NumOfOutArgs.Value = Job.Task.NumOfOutArgs;

JobDetails.RemoteFolder.Label = 'Remote folder';
JobDetails.RemoteFolder.Value = Job.RemoteFolder;

JobDetails.SubmitDateTime.Label = 'Submit';
if ~isempty(Job.SubmitDateTime)
    Job.SubmitDateTime = [Job.SubmitDateTime ' ' '(UTC)'];
end
JobDetails.SubmitDateTime.Value = Job.SubmitDateTime;

JobDetails.StartDateTime.Label = 'Start';
if ~isempty(Job.StartDateTime)
    Job.StartDateTime = [Job.StartDateTime ' ' '(UTC)'];
end
JobDetails.StartDateTime.Value = Job.StartDateTime;

JobDetails.FinishDateTime.Label = 'Finish';
if ~isempty(Job.FinishDateTime)
    Job.FinishDateTime = [Job.FinishDateTime ' ' '(UTC)'];
end
JobDetails.FinishDateTime.Value = Job.FinishDateTime;

JobDetails.LastUpdateDateTime.Label = 'Last Update';
if ~isempty(Job.LastUpdateDateTime)
    Job.LastUpdateDateTime = [Job.LastUpdateDateTime ' ' '(UTC)'];
end
JobDetails.LastUpdateDateTime.Value = Job.LastUpdateDateTime;

JobDetails.QueueDuration.Label = 'Queue duration';
JobDetails.QueueDuration.Value = Job.QueueDuration;

JobDetails.RunningDuration.Label = 'Running duration';
JobDetails.RunningDuration.Value = Job.RunningDuration;

% Print out the job details information
fprintf('\n')
fprintf_Report(JobDetails)

end


%% ------------------------------------------------------------------------
function fprintf_Report(ObjInfo)
%FPRINTF_REPORT prints selected information from an object.


LogicalString = {'false','true'};
nameValueSeparator = ':';
nameValueWidth = blanks(1);  % Distance between name and value fields

if ~isfield(ObjInfo,'Label')
    formatName = '%-23s';
    indentation = blanks(4);
else
    formatName = '%-20s';
    indentation = blanks(7);
end

if isfield(ObjInfo,'Label')
    formatString = [blanks(4) '%-23s'];
    fprintf(formatString,ObjInfo.Label)
    fprintf('\n')
    ObjInfo = rmfield(ObjInfo,'Label');
end

nameField = fieldnames(ObjInfo);

for i = 1:numel(nameField)
    labelField = [ObjInfo.(nameField{i}).Label nameValueSeparator];
    valueField = ObjInfo.(nameField{i}).Value;
    
    switch class(valueField)
        case 'function_handle'
            formatValue = '%-15s';
            valueField = 'Function handle';
        case 'char'
            formatValue = '%-13s';
        case 'logical'
            formatValue = '%-13s';
            valueField = LogicalString{valueField+1};
        case 'double'
            if mod(valueField,1) == 0
                formatValue = '%-13i';
            else
                formatValue = '%-13.5e';
            end
        otherwise
            valueField = class(valueField);
    end
    
    formatString = [...
        indentation, formatName, nameValueWidth, formatValue, '\n'];
    fprintf(formatString, labelField, valueField);
end

end

%% ------------------------------------------------------------------------

function print_delim(strTitle,totalWidth)
%PRINT_DELIM prints the top or bottom delimiter of the report.

if nargin < 1
    strTitle = '';
    totalWidth = 69;  % Default total width
elseif nargin < 2
    strTitle = [' ', strTitle, ' '];
    totalWidth = 69;
end

dashesWidth = (totalWidth - numel(strTitle) - 2)/2;
dashes = repmat('-',1,floor(dashesWidth));
if mod(dashesWidth,1) == 0
    delim = ['%%', dashes, strTitle, dashes, '%%\n']; 
else
    delim = ['%%', dashes, strTitle, dashes, '-', '%%\n']; 
end

fprintf(delim)

end
