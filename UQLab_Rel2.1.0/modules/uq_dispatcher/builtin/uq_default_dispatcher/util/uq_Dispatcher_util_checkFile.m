function fileExists = uq_Dispatcher_util_checkFile(...
    filenames, sshConnect, maxNumTrials)
%UQ_DISPATCHER_UTIL_CHECKFILE checks whether specified files exist.

%% Parse and verify inputs
cmdName = 'test';
if ~iscell(filenames)
    filenames = {filenames};
end

if nargin < 2
    sshConnect = '';
end

if nargin < 3
    maxNumTrials = 1;
end

%% Check whether file exists
fileExists = false(numel(filenames),1);

% Local checking
if isempty(sshConnect)
    fileExists = uq_map(@exist, filenames, 'Parameters', 'file');
    fileExists = uq_map(@logical, fileExists);
    fileExists = [fileExists{:}];
    if isrow(fileExists)
        fileExists = transpose(fileExists);
    end
    return
end

% Remote checking

% Safe guard against possible whitespaces in 'filenames'
filenames = uq_map(@uq_Dispatcher_util_writePath, filenames,...
    'Parameters', 'linux');

for i = 1:numel(filenames)
    cmdArgs = {'-f', filenames{i}};
    try
        uq_Dispatcher_util_runCLICommand(...
            cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);
        fileExists(i) = true;
    catch
        fileExists(i) = false;
        continue
    end
end

end
