function pass = uq_Dispatcher_init_checkLocalUtil(cmdName,DispatcherObj)
%UQ_DISPATCHER_INIT_CHECKLOCALUTIL checks if a utility exists on the local
%   machine.
%
%   PASS = UQ_DISPATCHER_INIT_CHECKLOCALUTIL(CMDNAME,DISPATCHEROBJ) checks
%   if a utility CMDNAME exists on the local machine. If the utility does
%   not exist, an error is thrown.

%% Get local variables
displayOpt = DispatcherObj.Internal.Display;

%% Check if a utility is available in the local machine
if displayOpt > 1
    msg = sprintf('[DISPATCHER] Check required (local) tool: *%s*',cmdName);
    % Escape backslash
    msg = regexprep(msg, '\\', '\\\\');
    fprintf(uq_Dispatcher_util_dispMsg(msg))
end

pass = uq_Dispatcher_util_checkCommand(cmdName);
if ~pass
    if displayOpt > 1
        fprintf('(ERROR)\n')
    end
    error('*%s* can''t be found. Make sure it is in the correct path.',...
        cmdName)
end
if displayOpt > 1
    fprintf('(OK)\n')
end

end
