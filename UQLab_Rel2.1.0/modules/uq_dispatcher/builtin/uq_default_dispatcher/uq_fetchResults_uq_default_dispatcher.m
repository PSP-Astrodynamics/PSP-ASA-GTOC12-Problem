function varargout = uq_fetchResults_uq_default_dispatcher(DispatcherObj,jobIdx,varargin)
%UQ_FETCHRESULTS_UQ_DEFAULT_DISPATCHER fetches the results of the default
%   Dispatcher type.

%% Parse and verify inputs
args = varargin;

% Force fetch
[forceFetch,args] = uq_parseNameVal(args, 'ForceFetch', false);

% Keep files flag
[keepFiles,args] = uq_parseNameVal(args, 'KeepFiles', false);

% New destination folder
[destDir,args] = uq_parseNameVal(args, 'DestDir', '');

% New source folder
[srcDir,args] = uq_parseNameVal(args, 'SrcDir', '');

% Throw warning if args is not exhausted
if ~isempty(args)
    numArgs = floor(numel(args)/2);
    warning('There is %s unparsed Name/Value argument pairs.',...
        num2str(numArgs))
    for i = 1:2:numel(args)
        fprintf('%s\n',args{i})
    end
end

% Always return at least one output argument
numOfOutArgs = max(nargout,1);

% Maximum number of trials for attempting an SSH connection
maxNumTrials = DispatcherObj.Internal.SSHClient.MaxNumTrials;

%% Set local variables
CurrentJob = DispatcherObj.Jobs(jobIdx);
remoteSep = DispatcherObj.Internal.RemoteSep;

%% Check the Job status
if CurrentJob.Status ~= 4
    
    % Check and update the Job status
    uq_updateStatus(DispatcherObj,jobIdx)
    CurrentJob = DispatcherObj.Jobs(jobIdx);
    
    % Fetching the results of a 'submitted' and 'running' job
    if any(CurrentJob.Status == [1 2])
        jobStatus = uq_getStatusChar(CurrentJob.Status);
        warning('Can''t fetch results; Job is %s!',jobStatus)
        [varargout{1:numOfOutArgs}] = deal([]);
        return
    end
    
    % fetching the results of a 'canceled' or 'failed' job
    if any(CurrentJob.Status == [-1 0])
        jobStatus = uq_getStatusChar(CurrentJob.Status);
        if ~forceFetch
            error('Can''t fetch results; Job is %s!',jobStatus)
        end
    end
    
end

%% Check if the remote directory is still intact
remoteFolder = CurrentJob.RemoteFolder;
sshConnect = uq_Dispatcher_helper_createSSHConnect(DispatcherObj);
if ~uq_Dispatcher_util_checkDir(remoteFolder, sshConnect, maxNumTrials)
    error('Remote folder associated with the Job does not exist any more.')
end

%% Fetch: Copy result files from remote machine to local machine

% Check if fetch is specified
if isempty(CurrentJob.Fetch)
    warning('Files to fetch not specified. Return empty results.')
    [varargout{1:numOfOutArgs}] = deal([]);
    return
end

filesToFetch = strcat(...
    CurrentJob.RemoteFolder, remoteSep,...
    uq_Dispatcher_util_flattenCell(CurrentJob.Fetch));

if isempty(srcDir)

    % Create a local staging folder
    if isempty(destDir)
        destDir = fullfile(DispatcherObj.LocalStagingLocation,CurrentJob.Name);
    end
    mkdir(destDir)

    % Get Session Name
    sessionName = uq_Dispatcher_helper_getSessionName(DispatcherObj);

    % Copy the files
    copyProgram  = DispatcherObj.Internal.SSHClient.SecureCopy;
    sshClientLocation = DispatcherObj.Internal.SSHClient.Location;
    if ~isempty(sshClientLocation)
        copyProgram = fullfile(sshClientLocation,copyProgram);
    end
    copyArgs = DispatcherObj.Internal.SSHClient.SecureCopyArgs;
    % Get the private key
    privateKey = DispatcherObj.Internal.RemoteConfig.PrivateKey;

    % With PSCP, multiple files can be fetched with '-scp' and '-unsafe' flags
    isPuTTY = strcmpi(DispatcherObj.Internal.SSHClient.Name,'putty');
    if isPuTTY
        copyArgs = strjoin({copyArgs, '-scp -unsafe'});
    end

    if forceFetch
        % If fetch is forced then try to copy each files
        for i = 1:numel(filesToFetch)
            try
                uq_Dispatcher_util_copy(...
                    filesToFetch{i}, destDir,...
                    'Mode', 'Remote2Local',...
                    'SessionName', sessionName,...
                    'RemoteSep', remoteSep,...
                    'CopyProgram', copyProgram,...
                    'AdditionalArguments', copyArgs,...
                    'PrivateKey', privateKey,...
                    'MaxNumTrials', maxNumTrials);
            catch
            end
        end
    else
        % If 'filesToFetch' contains large number of files, the shell
        % might have a limit on the number of characters it can parse.
        %   - Windows (2047 characters) -> 1500 characters w/ margin
        %   - Linux (1e5 characters) -> 5e4 characters w/ margin
        charSize = length(sprintf('%s ', filesToFetch{:}));
        doChunkCopy = (ispc && charSize >= 1500) || (isunix && charSize > 5e4);
        if doChunkCopy
            batchSize = 5;
            numBatch = ceil(numel(filesToFetch)/batchSize);
            idx = 0;
            for b = 1:numBatch
                if b == numBatch
                    filesChunk = filesToFetch(idx+1:end);
                else
                    filesChunk = filesToFetch(idx+1:idx+batchSize);
                end
                uq_Dispatcher_util_copy(...
                    filesChunk, destDir,...
                    'Mode', 'Remote2Local',...
                    'SessionName', sessionName,...
                    'RemoteSep', remoteSep,...
                    'CopyProgram', copyProgram,...
                    'AdditionalArguments', copyArgs,...
                    'PrivateKey', privateKey,...
                    'MaxNumTrials', maxNumTrials);
                idx = idx + batchSize;
            end
        else
            uq_Dispatcher_util_copy(...
                filesToFetch, destDir,...
                'Mode', 'Remote2Local',...
                'SessionName', sessionName,...
                'RemoteSep', remoteSep,...
                'CopyProgram', copyProgram,...
                'AdditionalArguments', copyArgs,...
                'PrivateKey', privateKey,...
                'MaxNumTrials', maxNumTrials);
        end
    end
end

%% Parse: Parse fetched files and create a cell array for each file

% Check if read is specified
if isempty(CurrentJob.Parse)
    warning('Parse function not specified.')
    [varargout{1:numOfOutArgs}] = deal([]);
    return
end

% Change back the files path to the local folder (running directory)
fetchedFiles = cell(numel(filesToFetch),1);
if isempty(srcDir)
    for i = 1:numel(filesToFetch)
        [~,filename,ext] = fileparts(filesToFetch{i});
        fetchedFiles{i} = fullfile(destDir,[filename ext]);
    end
else
    % Fetch from the specified source directory
    for i = 1:numel(filesToFetch)
        [~,filename,ext] = fileparts(filesToFetch{i});
        fetchedFiles{i} = fullfile(srcDir,[filename ext]);
    end
end

% Get the read function specific to the current task
parseFun = CurrentJob.Parse;

% Parse the fetched files
if forceFetch
    results = cell(numel(fetchedFiles));
    for i = 1:numel(fetchedFiles)
        try
            results{i} = parseFun(fetchedFiles(i));
        catch
            results{i} = NaN;
        end
    end
else
    results = parseFun(fetchedFiles);
end

%% Clean up
if ~keepFiles && isempty(srcDir)
    rmdir(destDir,'s')
end

%% Merge

% Check if merge is specified
if isempty(CurrentJob.Merge)
    if DispatcherObj.Internal.Display > 1
        warning('Merge function not specified.')
    end
    [varargout{1:numOfOutArgs}] = results;
    return
end

% Get the merge function specific to the current task
mergeFun = CurrentJob.Merge;
mergeParams = CurrentJob.MergeParams;
if ~forceFetch
    % Do not merge if the fetching is forced
    [varargout{1:numOfOutArgs}] =  mergeFun(results,mergeParams);
end

end
