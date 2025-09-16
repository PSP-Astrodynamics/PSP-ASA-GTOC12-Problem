function [status,results] = uq_Dispatcher_util_getFileSize(file,sshConnect,maxNumTrials)
%UQ_DISPATCHER_UTIL_GETFILESIZE gets the size of a file in bytes.

%% Parse and verify inputs

if nargin < 2
    sshConnect = '';
end

if nargin < 3
    maxNumTrials = 1;
end

%% Create command
cmdArgs = {};
if ispc && isempty(sshConnect)
    % Safe guard against possible whitespaces in 'file'
    filename = uq_Dispatcher_util_writePath(file,'pc');
    cmdName = sprintf('dir %s',filename);
    [status,results] = uq_Dispatcher_util_runCLICommand(cmdName,cmdArgs);
    
    % Typical 'dir' results on a file (below, 'file.txt'):
    %   Volume in drive C has no label.',...
    %   Volume Serial Number is XXXX-YYYY',...
    %
    %   Directory of C:\Users\user
    %
    %   01/09/2019  01:38 PM           193,458 file.txt
    %                 1 File(s)        193,458 bytes'
    %                 0 Dir(s)  65,242,374,144 bytes free)

    if status == 0
        results = strsplit(uq_strip(results),'\n');
        results = strsplit(results{end-1});
        results = str2double(results{end-1});
    else
        results = NaN;
    end

else
    % Safe guard against possible whitespaces in 'file'
    filename = uq_Dispatcher_util_writePath(file,'linux');    
    cmdName = sprintf('du %s | cut -f1',filename);
    [status,results] = uq_Dispatcher_util_runCLICommand(...
        cmdName, cmdArgs, sshConnect, 'MaxNumTrials', maxNumTrials);

    results = str2double(results);

end

end
