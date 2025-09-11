function writeAccess = uq_Dispatcher_util_checkWriteAccess(...
    dirName, sshConnect, maxNumTrials)
%UQ_DISPATCHER_UTIL_CHECKWRITEACCESS checks write access of a directory.
%
%   WRITEACCESS = UQ_DISPATCHER_UTIL_CHECKWRITEACCESS(DIRNAME) checks if
%   the user has a write access to a local directory DIRNAME.
%
%   WRITEACCESS = UQ_DISPATCHER_UTIL_CHECKWRITEACCESS(DIRNAME,SSHCONNECT)
%   checks if the user has a write access to a remote directory DIRNAME
%   with an SSH connection made by SSHCONNECT. If SSHCONNECT is an empty
%   char, then the directory is a local directory.
%
%   WRITEACCESS = ...
%   UQ_DISPATCHER_UTIL_CHECKWRITEACCESS(DIRNAME, SSHCONNECT, MAXNUMTRIALS)
%   checks if the users has a write access to a remote directory. The SSH
%   connection is made MAXNUMTRIALS times if a connection timed out error
%   occurs.

%% Parse and verify inputs

if nargin < 2
    sshConnect = '';
end

if nargin < 3
    maxNumTrials = 1;
end

%% Create command
if ispc && isempty(sshConnect)
    fileName = fullfile(dirName,uq_createUniqueID);
    [fid,errmsg] = fopen(fileName,'w');
    if ~isempty(errmsg) && strcmp(errmsg,'Permission denied') 
        writeAccess = false;
    else
        writeAccess = true;
        fclose(fid);
        delete(fileName);
    end
    return
else
    dirName = uq_Dispatcher_util_writePath(dirName,'linux');
    cmdName = sprintf('if [ -w %s ]; then true; else false; fi',dirName);
end
    
%% Submit command
try
    uq_Dispatcher_util_runCLICommand(cmdName, {}, sshConnect,...
        'MaxNumTrials', maxNumTrials);
    writeAccess = true;
catch
    writeAccess = false;
end
        
end
