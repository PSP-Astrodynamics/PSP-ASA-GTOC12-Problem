function uq_retrieveJobs(DispatcherObj,varargin)
%UQ_RETRIEVEJOBS retrieves Jobs from the remote location.
%
%   UQ_RETRIEVEJOBS(DISPATCHEROBJ) retrieves Jobs from a remote location
%   specified in a Dispatcher object DISPATCHEROBJ and adds it to the 
%   Dispatcher object. If an identical Job is already in DISPATCHEROBJ,
%   it will not be added. The Job status will not be automatically updated
%   before it is added to DISPATCHEROBJ. The Dispatcher object will be
%   modified in-place.
%
%   UQ_RETRIEVEJOBS(..., 'DirNames', DIRNAMES) retrieves Jobs from a remote
%   location specified in a Dispatcher object DISPATCHEROBJ with the
%   Job-specific directory names given in a cell array DIRNAMES.
%
%   UQ_RETRIEVEJOBS(..., 'UpdateStatus', true) retrieves Jobs from a
%   remote location. The Job status will be updated. The default value
%   of 'UpdateStatus' is false.
%
%   NOTE:
%   Depending on the verbosity level of the Dispatcher object, additional
%   information may be displayed on the MATLAB Command Window during
%   retrieval process.

%% Parse and verify inputs

% DirNames
[dirNames,varargin] = uq_parseNameVal(varargin, 'DirNames', '');

% UpdateStatus
[updateStatus,varargin] = uq_parseNameVal(varargin, 'UpdateStatus', false);

% Throw warning if varargin is not exhausted
if ~isempty(varargin)
    warning('There is %s Name/Value argument pairs.',num2str(numel(varargin)))
end

%% Set local variables
displayOpt = DispatcherObj.Internal.Display;

%% Get a list of directory from the remote location

remoteDir = DispatcherObj.Internal.RemoteConfig.RemoteFolder;
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;
remoteSep = DispatcherObj.Internal.RemoteSep;

jobObjFile = DispatcherObj.Internal.RemoteFiles.JobObject;

% Get Session Name
sessionName = uq_Dispatcher_helper_getSessionName(DispatcherObj);
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);

copyProgram  = DispatcherObj.Internal.SSHClient.SecureCopy;
copyArgs = DispatcherObj.Internal.SSHClient.SecureCopyArgs;
privateKey = DispatcherObj.Internal.RemoteConfig.PrivateKey;

if isempty(dirNames)
    [~,dirNames] = uq_Dispatcher_util_getDirNames(...
        uq_Dispatcher_util_writePath(remoteDir,'linux'),...
        sshConnect, maxNumTrials);
    % Convert folder names to date
    dateDirNames = uq_Dispatcher_util_str2date(dirNames);
    % Sort by dates in ascending order (recent comes last)
    dirNames = [dirNames{sort(dateDirNames)}]';
else
    if ~iscell(dirNames)
        dirNames = {dirNames};
    end
end

%% Immediately return if 'dirNames' is empty
if isempty(dirNames)
    if displayOpt > 1
        fprintf('[DISPATCHER] Remote folder is empty.\n')
    end
end

%% Create a local staging directory
localStagingLocation = DispatcherObj.LocalStagingLocation;
localStagingDir = fullfile(localStagingLocation,uq_createUniqueID); 
mkdir(localStagingDir)

%% Copy previous Jobs array for back up
JobObjs = DispatcherObj.Jobs;

%% Search for, copy, and append Job object in the remote
try
    for i = 1:numel(dirNames)
        
        if displayOpt > 1
            msg = '[DISPATCHER] Checking remote directory #%d of %d.\n';
            msg = sprintf(msg, i, numel(dirNames));
            fprintf(msg)
        end
        
        %% Look for JobObj file
        jobObjLocation = sprintf('%s%s%s',...
            remoteDir, remoteSep, dirNames{i});
        jobObjFileRemote = sprintf('%s%s%s',...
            jobObjLocation, remoteSep, jobObjFile);

        if displayOpt > 1
            msg = sprintf('[DISPATCHER] Check remote directory for Job: %s',...
                jobObjLocation);
            fprintf(uq_Dispatcher_util_dispMsg(msg))
        end

        fileExists = uq_Dispatcher_util_checkFile(...
            jobObjFileRemote, sshConnect, maxNumTrials);

        %% If found, get the Job object
        if fileExists

            if displayOpt > 1
                fprintf('(FOUND)\n')
            end

            uq_Dispatcher_util_copy(...
                jobObjFileRemote, localStagingDir,...
                'Mode', 'Remote2Local',...
                'SessionName', sessionName,...
                'RemoteSep', remoteSep,...
                'CopyProgram', copyProgram,...
                'AdditionalArguments', copyArgs,...
                'PrivateKey', privateKey,...
                'MaxNumTrials', maxNumTrials);
            jobObj = matfile(fullfile(localStagingDir, jobObjFile));
            jobObj = jobObj.JobObj;
        else
            if displayOpt > 1
                fprintf('(NOT FOUND)\n')
            end
            continue
        end

        %% Check if Job object already in the array
        if ~any(arrayfun(@(obj) strcmpi(obj.Name, jobObj.Name),JobObjs))            

            if displayOpt > 1
                msg = '[DISPATCHER] Add Job to the Dispatcher Object';
                fprintf(uq_Dispatcher_util_dispMsg(msg))
            end

            %% Append the retrieved Job array
            if isempty(DispatcherObj.Jobs)
                DispatcherObj.Jobs = jobObj;
            else
                DispatcherObj.Jobs(end+1) = jobObj;
            end

            if displayOpt > 1
                fprintf('(OK)\n')
            end

            %% Update the Status of the Jobs
            if updateStatus
                if displayOpt > 1
                    msg = '[DISPATCHER] Update Job Status';
                    fprintf(uq_Dispatcher_util_dispMsg(msg))
                end

                uq_updateStatus(DispatcherObj);

                if displayOpt > 1
                    fprintf('(OK)\n')
                end
            end

            %% Clean up
            delete(fullfile(localStagingDir, jobObjFile));
        else
            if displayOpt > 1
                msg = '[DISPATCHER] Identical Job is already in the current Dispatcher object';
                fprintf(uq_Dispatcher_util_dispMsg(msg))
                fprintf('(SKIP)\n')
            end
        end
    end

catch ME

    fclose('all');
    % Rollback any changes to the Jobs property
    DispatcherObj.Jobs = JobObjs;
    % Clean up local staging directories
    rmdir(localStagingDir,'s')
    % Rethrow error
    rethrow(ME)

end

% Clean up Local Staging Folder
rmdir(localStagingDir,'s')
    
end
