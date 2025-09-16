function uq_recreateJob(DispatcherObj, jobIdx, varargin)
%UQ_RECREATEJOB recreates a Job from previously created Job.
%
%   UQ_RECREATEJOB(DISPATCHEROBJ) recreates the lastly created Job in a
%   Dispatcher object DISPATCHEROBJ as a new Job appended to last entry
%   of the Jobs array.
%
%   UQ_RECREATEJOB(DISPATCHEROBJ,JOBIDX) recreates a Job in DISPATCHEROBJ
%   selected by its index JOBIDX.
%
%   UQ_RECREATEJOB(..., NAME, VALUE) recreates a Job in DISPATCHEROBJ and
%   overrides some of the previous properties of the Job specified using
%   NAME/VALUE argument pairs. The supported NAME/VALUE argument pairs are:
%
%       JobObj = DispatcherObj.Jobs(jobIdx)
%
%       NAME                VALUE
%       'Name'              Name of the Job
%                           Default: JobObj.Name
%
%       'RemoteFolder'      Directory in the remote machine to store
%                           Job-specific files
%                           Default: JobObj.RemoteFolder
%
%       'ExecMode'          Execution mode of the dispatched computation
%                           ('sync' or 'async')
%                           Default: JobObj.ExecMode
%
%       'AttachedFiles'     List of attached files and folders to send to 
%                           the remote machine
%                           Default: JobObj.AttachedFiles
%
%       'AddToPath'         List of directories in the remote machine to
%                           add to the PATH of the remote environment
%                           Default: JobObj.AddToPath
%
%       'AddTreeToPath'     List of directories (including, their subdi-
%                           rectories) to add to the PATH of the remote
%                           environment
%                           Default: JobObj.AddTreeToPath
%
%       'Tag'               Descriptive text for the Job
%                           Default: JobObj.Tag
%
%       'Fetch'             List of files to fetch from the remote machine
%                           Default: JobObj.Fetch
%
%       'Merge'             Function handle to merge fetched results
%                           Default: JobObj.Merge
%
%       'Parse'             Function handle to parse fetched files
%                           Default: JobObj.Parse
%
%       'Data'              Data (inputs, parameters, etc.) associated with
%                           the Job
%                           Default: JobObj.Data
%
%       'Task'              Task specific to the Job
%                           Default: JobObj.Task
%
%       'WallTime'          Wall time for the remote scheduler (in minutes)
%                           Default: JobObj.WallTime
%
%       'FetchStreams'      Flag to automatically fetch the output streams
%                           of the remote execution
%                           Default: JobObj.FetchStreams
%

%% Parse and verify inputs
if nargin < 2
    jobIdx = numel(DispatcherObj.Jobs);
end

%% Switch to different types of Dispatcher
switch lower(DispatcherObj.Type)
    case 'uq_default_dispatcher'
        uq_recreateJob_uq_default_dispatcher(DispatcherObj, jobIdx, varargin{:})
    otherwise
        error('Job submission for Dispatcher type *%s* is not supported!',...
            DispatcherObj.Type)
end

end