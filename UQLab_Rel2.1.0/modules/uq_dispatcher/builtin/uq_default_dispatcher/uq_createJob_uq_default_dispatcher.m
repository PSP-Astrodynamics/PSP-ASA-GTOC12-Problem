function jobIdx = uq_createJob_uq_default_dispatcher(JobDef,DispatcherObj)
%UQ_CREATEJOB_UQ_DEFAULT_DISPATCHER creates a Job for default dispatcher.

%% Verify CPUs and Nodes specification
% These Internal values may be changed on-the-fly,
% make sure they are still consistent.
numCPUs = DispatcherObj.Internal.NumCPUs;
numNodes = DispatcherObj.Internal.NumNodes;
cpusPerNode = DispatcherObj.Internal.CPUsPerNode;
if ~isequal(numCPUs,numNodes*cpusPerNode)
    error(['The total number of CPUs (%d) is inconsistent ',...
        'with the number of nodes (%d) and CPUs per node (%d)'],...
        numCPUs, numNodes, cpusPerNode)
end

%% Create a Job object
JobObj = uq_job(JobDef);

% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

% Get the Display option
displayOpt = DispatcherObj.Internal.Display;

%%
try
    %% Create Local Job directory and populate with remote files
    
    % Create a local Job directory in the LocalStagingLocation
    if isempty(DispatcherObj.LocalStagingLocation)
        localStagingLocation = pwd;
    else
        localStagingLocation = DispatcherObj.LocalStagingLocation;
    end
    localStagingDir = fullfile(localStagingLocation,JobObj.Name); 
    mkdir(localStagingDir)
    
    % Update the Status of the Job
    JobObj.Status = 1;
        
    % Write the current Job object
    save(fullfile(localStagingDir,'JobObj.mat'), 'JobObj', '-v7.3')

    % Write the data to the local staging folder
    uq_Dispatcher_files_createData(localStagingDir,JobObj)
    
    % Flip 'isExecuting' flag of the Dispatcher object (optional)
    % NOTE: This is important for 'uq_evalModel', as the flag is used to 
    % make the function in the remote aware that it is being executed in
    % the remote.
    if strcmpi(JobObj.Task.Type,'uq_evalModel')
        DispatcherObj.isExecuting = true;
    end
    
    % Save UQLab session (optional)
    if JobObj.Task.SaveUQLabSession
        sessionFilename = DispatcherObj.Internal.RemoteFiles.UQLabSession;
        uq_saveSession(fullfile(localStagingDir,sessionFilename));
    end
    
    % Create main script
    uq_Dispatcher_files_createMainScript(...
        localStagingDir, JobObj, DispatcherObj)
    
    % Create MPI script
    uq_Dispatcher_files_createMPI(localStagingDir, JobObj, DispatcherObj)
    
    % Create scheduler remote script (Job script)
    uq_Dispatcher_files_createScheduler(...
        localStagingDir, JobObj, DispatcherObj)
    
    % Create additional files (TODO: wrap into a function that hide the
    % differences between MATLAB and Non-MATLAB task)
    if ~JobObj.Task.MATLAB
        % Set PATH is in a separate script
        uq_Dispatcher_files_createSetPATH(...
            localStagingDir, JobObj, DispatcherObj);
    end

    %% Create Remote Job directory structure

    % Create SSH Connect
    sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

    % Check if remote folder exists, if not create it
    remoteLocation = DispatcherObj.Internal.RemoteConfig.RemoteFolder;
    if ~uq_Dispatcher_util_checkDir(remoteLocation, sshConnect, maxNumTrials)
        if displayOpt > 1
            msg = '[DISPATCHER] Create remote directory';
            fprintf(uq_Dispatcher_util_dispMsg(msg))
        end
        uq_Dispatcher_util_mkDir(remoteLocation,...
            'SSHConnect', sshConnect,...
            'MaxNumTrials', maxNumTrials);
        if displayOpt > 1
            fprintf('(OK)\n')
        end
    end

    % Move attached files to folder name
    for i = 1:numel(JobObj.AttachedFiles)
        if ~isempty(JobObj.AttachedFiles{i})
            if isdir(JobObj.AttachedFiles{i})
                % Get only the directory name
                attachedDir = JobObj.AttachedFiles{i}; 
                if strcmp(attachedDir(end),filesep)
                    attachedDir = attachedDir(1:end-1);
                end
                [~,attachedDir] = fileparts(attachedDir);
                copyfile(JobObj.AttachedFiles{i},...
                    fullfile(localStagingDir,attachedDir))
            else
                copyfile(JobObj.AttachedFiles{i},localStagingDir)
            end
        end
    end

    % Get Session Name
    sessionName = uq_Dispatcher_helper_getSessionName(DispatcherObj);

    % Send the files to the remote machine
    remoteLocation = DispatcherObj.RemoteLocation;
    copyProgram  = DispatcherObj.Internal.SSHClient.SecureCopy;
    sshClientLocation = DispatcherObj.Internal.SSHClient.Location;
    if ~isempty(sshClientLocation)
        copyProgram = fullfile(sshClientLocation,copyProgram);
    end
    
    copyArgs = DispatcherObj.Internal.SSHClient.SecureCopyArgs;
    privateKey = DispatcherObj.Internal.RemoteConfig.PrivateKey;

    % Display diagnostic message
    if displayOpt > 1
        msg = '[DISPATCHER] Send the dispatch package';
        fprintf(uq_Dispatcher_util_dispMsg(msg))
    end

    uq_Dispatcher_util_copy(...
        localStagingDir, remoteLocation,...
        'Mode', 'Local2Remote',...
        'SessionName', sessionName,...
        'RemoteSep', DispatcherObj.Internal.RemoteSep,...
        'CopyProgram', copyProgram,...
        'Recursive', true,...
        'AdditionalArguments', copyArgs,...
        'PrivateKey', privateKey,...
        'MaxNumTrials', maxNumTrials);

    % Display diagnostic message
    if displayOpt > 1
        fprintf('(OK)\n')
    end

    % Update execution right for the remote scripts
    remoteSep = DispatcherObj.Internal.RemoteSep;
    remoteFolder = JobObj.RemoteFolder;
    % MPI File
    mpiFile = DispatcherObj.Internal.RemoteFiles.MPI;
    mpiFullfile = sprintf('%s%s%s', remoteFolder, remoteSep, mpiFile);
    if displayOpt > 1
        msg = sprintf('[DISPATCHER] Give permission to execute: *%s*',mpiFile);
        fprintf(uq_Dispatcher_util_dispMsg(msg))
    end
    uq_Dispatcher_util_chmod(mpiFullfile, '+x',...
        'SSHConnect', sshConnect,...
        'MaxNumTrials', maxNumTrials);
    if displayOpt > 1
        fprintf('(OK)\n')
    end
    % Job script
    jobScript = DispatcherObj.Internal.RemoteFiles.JobScript;
    jobScriptFullfile = sprintf('%s%s%s',remoteFolder,remoteSep,jobScript);
    if displayOpt > 1
        msg = sprintf('[DISPATCHER] Give permission to execute: *%s*',jobScript);
        fprintf(uq_Dispatcher_util_dispMsg(msg))
    end
    uq_Dispatcher_util_chmod(jobScriptFullfile, '+x',...
        'SSHConnect', sshConnect,...
        'MaxNumTrials', maxNumTrials);
    if displayOpt > 1
        fprintf('(OK)\n')
    end

    % BASH script (only in the case of Bash mapping task)
    if ~JobObj.Task.MATLAB
        taskScript = DispatcherObj.Internal.RemoteFiles.Bash;
        taskScriptFullfile = sprintf(...
            '%s%s%s', remoteFolder, remoteSep, taskScript);
        if displayOpt > 1
            msg = sprintf('[DISPATCHER] Give permission to execute: *%s*',taskScript);
            fprintf(uq_Dispatcher_util_dispMsg(msg))
        end
        uq_Dispatcher_util_chmod(taskScriptFullfile, '+x',...
            'SSHConnect', sshConnect,...
            'MaxNumTrials', maxNumTrials);
        if displayOpt > 1
            fprintf('(OK)\n')
        end
    end

    % Update the Dispatcher Object
    if isempty(DispatcherObj.Jobs)
        jobIdx = 1;
        DispatcherObj.Jobs = JobObj;
    else
        jobIdx = numel(DispatcherObj.Jobs) + 1;
        DispatcherObj.Jobs(end+1) = JobObj;
    end

    %% Clean up

    % Rollback the State of Dispatcher object
    DispatcherObj.isExecuting = false;

    % Clean up Local Staging Folder
    rmdir(localStagingDir,'s')

catch ME

    %% Rollback any changes

    % Close all files that might still be open
    % after program flow interruption
    fclose('all');

    % Rollback the State of Dispatcher object
    DispatcherObj.isExecuting = false;

    % Clean up remote folders
    remoteFolder = JobObj.RemoteFolder;
    % Safe guard against possible whitespaces in 'remoteFolder'
    remoteFolder = uq_Dispatcher_util_writePath(remoteFolder,'linux');

    cmdName = 'rm';
    cmdArgs = {'-rf',remoteFolder};

    % Get Session Name
    sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

    % Display diagnostic message
    if displayOpt > 1
        msg = sprintf('\n[DISPATCHER] Something went wrong. Rolling back changes.');
        fprintf(uq_Dispatcher_util_dispMsg(msg))
    end

    % Clean up remote folder
    uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);

    % Clean up local staging directories
    rmdir(localStagingDir,'s')

    % Display diagnostic message
    if displayOpt > 1
        fprintf('(OK)\n')
    end

    % Rethrow error
    rethrow(ME)

end

end
