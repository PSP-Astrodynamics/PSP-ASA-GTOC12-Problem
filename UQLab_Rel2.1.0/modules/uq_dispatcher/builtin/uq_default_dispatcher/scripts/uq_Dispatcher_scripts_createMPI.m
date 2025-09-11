function scriptMPI = uq_Dispatcher_scripts_createMPI(JobObj,DispatcherObj)
%UQ_DISPATCHER_SCRIPTS_CREATEMPI creates the content of MPI remote file.
%
%   SCRIPTMPI = UQ_DISPATCHER_SCRIPTS_CREATEMPI(DISPATCHEROBJ,JOBIDX)
%   creates the content of MPI remote file as character array according 
%   to a DISPATCHER object DISPATCHEROBJ for the Job index JOBIDX.
%
%   See also UQ_CREATEJOB, UQ_DISPATCHER_SCRIPTS_CREATEMATLAB,
%   UQ_DISPATCHER_SCRIPTS_CREATESCHEDULER.

%% Define Local Variables

% Remote folder specific to a Job
remoteFolder = JobObj.RemoteFolder;

% Folder separator in the remote system
remoteSep = DispatcherObj.Internal.RemoteSep;

% Get RemoteConfig variables
RemoteConfig = DispatcherObj.Internal.RemoteConfig;

%% Get Scheduler-specific Information
SchedulerVars = DispatcherObj.Internal.RemoteConfig.SchedulerVars;
workingDirectory = SchedulerVars.WorkingDirectory;
if isempty(workingDirectory)
    workingDirectory = remoteFolder;
end

%% Create the Content of the File
scriptMPI = {};

scriptMPI{end+1} = DispatcherObj.Internal.RemoteConfig.Shebang;
scriptMPI{end+1} = '';
% Safe guard against possible whitespaces in 'workingDirectory'
% Because workingDirectory might be an environment variable of the
% scheduler that will be expanded, double quotations marks are used
scriptMPI{end+1} = sprintf('cd "%s"',workingDirectory);

%%
if JobObj.Task.MATLAB
    % MATLAB script filename to run as an MPI job
    matlabFile = DispatcherObj.Internal.RemoteFiles.MATLAB;
    matlabCommand = RemoteConfig.MATLABCommand;
    matlabOptions = RemoteConfig.MATLABOptions;
    % Create MATLAB script fullname
    matlabScriptFullname = [remoteFolder remoteSep matlabFile];
    % Use single thread MATLAB if required
    if RemoteConfig.MATLABSingleThread
        matlabOptions = ['-singleCompThread' ' ' uq_strip(matlabOptions)];
    end
    scriptMPI{end+1} = sprintf('%s %s "run(''%s'')"',...
        matlabCommand, matlabOptions, matlabScriptFullname);
else
    bashFile = DispatcherObj.Internal.RemoteFiles.Bash;
    scriptMPI{end+1} = sprintf('./%s',bashFile);
end
    

scriptMPI = [sprintf('%s\n',scriptMPI{1:end-1}),scriptMPI{end}];

end
