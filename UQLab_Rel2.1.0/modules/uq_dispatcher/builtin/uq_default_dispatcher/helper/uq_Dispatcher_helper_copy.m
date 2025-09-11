function [status,outputs] = uq_Dispatcher_helper_copy(DispatcherObj, src, dest)
%UQ_DISPATCHER_HELPER_COPY wraps the copy to remote utility function to use
%   relevant information associated with a particular Dispatcher object.

%% Get the relevant options to copy

sessionName = uq_Dispatcher_helper_getSessionName(DispatcherObj);

copyProgram  = DispatcherObj.Internal.SSHClient.SecureCopy;

sshClientLocation = DispatcherObj.Internal.SSHClient.Location;
if ~isempty(sshClientLocation)
    copyProgram = fullfile(sshClientLocation,copyProgram);
end

copyArgs = DispatcherObj.Internal.SSHClient.SecureCopyArgs;
privateKey = DispatcherObj.Internal.RemoteConfig.PrivateKey;

remoteSep = DispatcherObj.Internal.RemoteSep;

%% Copy src to dest
[status,outputs] = uq_Dispatcher_util_copy(...
    src, dest,...
    'Mode', 'Local2Remote',...
    'SessionName', sessionName,...
    'RemoteSep', remoteSep,...
    'CopyProgram', copyProgram,...
    'AdditionalArguments', copyArgs,...
    'PrivateKey', privateKey);
    
end
