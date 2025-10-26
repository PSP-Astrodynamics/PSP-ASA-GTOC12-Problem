function pass = uq_Dispatcher_init_checkLocalWriteAccess(dirName,DispatcherObj)
%UQ_DISPATCHER_INIT_CHECKLOCALWRITEACCESS checks if the user has a write
%   access to a local directory.
%
%   PASS = UQ_DISPATCHER_INIT_CHECKLOCALWRITEACCESS(DIRNAME,DISPATCHEROBJ)
%   checks if the user has a write access to a directory DIRNAME on the
%   local machine. If the user does not have a write access, an error is
%   thrown.

%% Get local variables
displayOpt = DispatcherObj.Internal.Display;

%% Check write access to the remore directory
if displayOpt > 1
    msg = sprintf('[DISPATCHER] Check write access (local): "%s"',dirName);
    % Escape backslash
    msg = regexprep(msg, '\\', '\\\\');
    fprintf(uq_Dispatcher_util_dispMsg(msg))
end

pass = uq_Dispatcher_util_checkWriteAccess(dirName);

if ~pass
    if displayOpt > 1
        fprintf('(ERROR)\n')
    end
    error('User has no write access to *%s*.',dirName)
end
if displayOpt > 1
    fprintf('(OK)\n')
end

end
