function isFileEmpty = uq_Dispatcher_util_isFileEmpty(...
    filenames, sshConnect, maxNumTrials)
%UQ_DISPATCHER_UTIL_ISFILEEMPTY checks if a file (or files) is empty.
%
%   ISFILEEMPTY = UQ_DISPATCHER_UTIL_ISFILEEMPTY(FILENAMES) checks if a
%   file given in FILENAMES is an empty file. Multiple files can be
%   specified using cell array. The function returns a vector of logical 
%   values (true if file is empty, false otherwise).
%
%   ISFILEEMPTY = UQ_DISPATCHER_UTIL_ISFILEEMPTY(FILENAMES,SSHCONNECT)
%   checks if the files are empty for the files that are located in a 
%   remote machine with connection made via SSH specified in SSHCONNECT.

%   NOTE: Both local and remote machines are assumed to be running a Linux
%   or a Mac operating system.

%% Parse and Verify Inputs
if ~iscell(filenames)
    filenames = {filenames};
end

if nargin < 2
    sshConnect = '';
end

if nargin < 3
    maxNumTrials = 5;
end

%% Check Files
isFileEmpty = false(numel(filenames),1);

% Local checking in a PC
if ispc && isempty(sshConnect)
    % Safe guard against possible whitespaces in 'filenames'
    filenames = uq_map(@uq_Dispatcher_util_writePath, filenames,...
        'Parameters', 'pc');
    for i = 1:numel(filenames)
        [~,results] = uq_Dispatcher_util_getFileSize(filenames{i});
        if results > 0
            isFileEmpty(i) = false;
        end
    end
    return
end

% Safe guard against possible whitespaces in 'filenames'
filenames = uq_map(@uq_Dispatcher_util_writePath, filenames,...
    'Parameters', 'linux');

for i = 1:numel(filenames)
    cmdName = sprintf('if [ -s %s ]; then false; else true; fi',...
        filenames{i});
    try
        uq_Dispatcher_util_runCLICommand(...
            cmdName, {}, sshConnect, 'MaxNumTrials', maxNumTrials);
        isFileEmpty(i) = true;
    catch
        isFileEmpty(i) = false;
        continue
    end
end

end
