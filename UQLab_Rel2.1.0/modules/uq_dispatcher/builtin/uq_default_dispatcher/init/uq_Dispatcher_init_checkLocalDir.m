function pass = uq_Dispatcher_init_checkLocalDir(dirName,DispatcherObj)
%UQ_DISPATCHER_INIT_CHECKLOCALDIR checks if a directory exists on the local
%   machine.
%
%   PASS = UQ_DISPATCHER_INIT_CHECKLOCALDIR(DIRNAME,DISPATCHEROBJ) checks
%   if a directory DIRNAME exists on the local machine. If the directory
%   does not exist, it will be created. If the creation fails, an error is
%   thrown.

%% Get local variable
displayOpt = DispatcherObj.Internal.Display;

%% Check if directory exists
if displayOpt > 1
    msg = sprintf('[DISPATCHER] Check directory (local): "%s"',dirName);
    % Escape backslash
    msg = regexprep(msg, '\\', '\\\\');
    fprintf(uq_Dispatcher_util_dispMsg(msg))
end

if ~isempty(dirName)
    dirExists = isdir(dirName);
    if displayOpt > 1
        fprintf('(OK)\n')
    end
    if dirExists
        if displayOpt > 1
            fprintf('(ERROR)\n')
        end
    end
else
    dirExists = true;
    pass = true;
    if displayOpt > 1
        fprintf('(OK)\n')
    end
end

%% Create directory if it does not exist
if ~dirExists
   if displayOpt > 1
        msg = sprintf('[DISPATCHER] Create directory (local): "%s"',dirName);
        % Escape backslash
        msg = regexprep(msg, '\\', '\\\\');
        fprintf(uq_Dispatcher_util_dispMsg(msg))
   end
   
   try
       pass = uq_Dispatcher_util_mkDir(dirName);
       if displayOpt > 1
           fprintf('(OK)\n')
       end

   catch e
       if displayOpt > 1
        fprintf('(ERROR)\n')
       end
       rethrow(e)
   end
   
end

end
