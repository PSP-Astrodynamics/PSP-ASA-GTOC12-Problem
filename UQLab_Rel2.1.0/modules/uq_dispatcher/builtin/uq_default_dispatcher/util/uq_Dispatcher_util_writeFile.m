function [success,message,messageID] = uq_Dispatcher_util_writeFile(filename, content, varargin)


%% Parse and Verify Inputs

% Encoding
paramName = 'Encoding';
encoding = 'ISO-8859-1';  % Latin 1 encoding
paramInVarargin = strcmpi(varargin,paramName);
if sum(paramInVarargin) > 1
    error('Multiple definition of ''%s''',paramName)
end
if any(paramInVarargin)
    encodingIdx = find(paramInVarargin);
    encoding = varargin{encodingIdx+1};
    varargin([encodingIdx encodingIdx+1]) = [];
end

% Permission
paramName  = 'Permission';
permission = 'w';  % as binary. NOTE: 'wt' will adjust '\n' according to OS
paramInVarargin = strcmpi(varargin,paramName);
if sum(paramInVarargin) > 1
    error('Multiple definition of ''%s''',paramName)
end
if any(paramInVarargin)
    permissionIdx = find(paramInVarargin);
    permission = varargin{permissionIdx+1};
    varargin([permissionIdx permissionIdx+1]) = [];
end
if ~any(strcmpi(permission,{'w','w+','wt','w+t','a','a+','at','a+t'}))
    error('Unsupported file permission!')
end

% MachineFormat
paramName  = 'MachineFormat';
machineFmt = 'n'; % native (Local machine format)
paramInVarargin = strcmpi(varargin,paramName);
if sum(paramInVarargin) > 1
    error('Multiple definition of ''%s''',paramName)
end
if any(paramInVarargin)
    machineFmtIdx = find(paramInVarargin);
    machineFmt = varargin{machineFmtIdx+1};
    varargin([machineFmtIdx machineFmtIdx+1]) = [];
end

%% Write the File

try
    % Open a file
    fid = fopen(filename, permission, machineFmt, encoding);
    % Write the file assuming content is a character array
    fprintf(fid, '%s', content);
    % Close the file
    fclose(fid);
catch e
    if nargout > 0
        success = false;
        message = e.message;
        messageID = e.identifier;
        return
    else
        rethrow(e)
    end
end

if nargout > 0
    success = true;
    message = '';
    messageID = '';
end

end

