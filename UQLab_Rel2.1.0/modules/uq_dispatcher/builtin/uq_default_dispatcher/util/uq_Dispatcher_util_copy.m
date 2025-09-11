function [status,outputs] = uq_Dispatcher_util_copy(source, dest, varargin)
%UQ_DISPATCHER_UTIL_COPY copies file to a target directory.
%
%   UQ_DISPATCHER_UTIL_COPY(SOURCE,DEST) copy SOURCE file to DEST folder
%   locally.
%
%   UQ_DISPATCHER_UTIL_COPY(..., NAME, VALUE) copy SOURCE to DEST folder
%   with additional options specified as NAME/VALUE arguments.
%   
%      Name               VALUE
%      'Mode'             Mode of copying
%                         - 'Local2Local'  : From local to local (default)
%                         - 'Local2Remote' : From local to remote
%                         - 'Remote2Local' : From remote to local
%                         - 'Remote2Remote': From remote to remote using
%                                            local machine as a route
%
%      'SessionName'      Session name of the remote machine in
%                         'Local2Remote' and 'Remote2Local' copying
%                         default: ''
%
%      'SessionNameSrc'   Session name of the source machine in
%                         'Remote2Remote' copying
%                         default: ''
%
%      'SessionNameDest'  Session name of the destination machine in
%                         'Remote2Remote' copying
%                         default: ''
%
%      'RemoteSep'        The directory separator of the remote machine
%                         default: '/' (i.e., remote is assumed to be
%                         Linux)
%
%      'CopyProgram'      Program to do the copy
%                         default: 'cp' (i.e., local copy)
%
%      'Recursive'        Flag to copy recursively (i.e., directory copy)
%                         default: false
%
%      'MaxNumTrials'      
%   
%      'PrivateKey'       Private key to create a passwordless SSH
%                         connection
%                         default: '' (empty)
%
%      'AdditionalArgs'   Additional arguments to the 'Program'
%                         default: '' (empty)
%
%   [status,results] = UQ_DISPATCHER_UTIL_COPY(...) returns the exit STATUS
%   of the command and the terminal OUTPUTS.
% 

%% Parse Inputs

% Destination folder
if any(strcmpi(dest(end),{'\','/'}))
    dest = dest(1:end-1);
end

% SessionName (Session Name of the Source/Destination Machine)
% for either 'Local2Remote' or 'Remote2Local' operation
sessionNameDefault = '';
[sessionName,varargin] = uq_parseNameVal(varargin,'SessionName',...
    sessionNameDefault, @(x) ischar(x));

% SessionNameSrc (Session Name of the Source Machine)
sessionNameSrcDefault = '';
[sessionNameSrc,varargin] = uq_parseNameVal(varargin,'SessionNameSrc',...
    sessionNameSrcDefault, @(x) ischar(x));

% SessionNameDest (Session Name of the Destination Machine)
sessionNameDestDefault = '';
[sessionNameDest,varargin] = uq_parseNameVal(varargin,'SessionNameDest',...
    sessionNameDestDefault, @(x) ischar(x));

% Remote separator
remoteSepDefault = '/';  % Linux folder separator (default)
[remoteSep,varargin] = uq_parseNameVal(varargin, 'RemoteSep',...
    remoteSepDefault, @(x) ischar(x) && any(strcmp(x,{'/','\'})));

% Mode
copyModes = {'local2local', 'local2remote', 'remote2local', 'remote2remote'};
copyModeDefault = 'local2local';

[copyMode,varargin] = uq_parseNameVal(varargin, 'Mode',...
    copyModeDefault, @(x) ischar(x) && any(strcmpi(x,copyModes)));
copyMode = lower(copyMode);
    
% If 'Remote2Remote' then 'SessionNameSrc' and 'SessionNameDest' must exist
if strcmp(copyMode,'remote2remote') && ...
        isempty(sessionNameSrc) && isempty(sessionNameDest)
    error('''Remote2Remote'' operation requires two session names!')
end

% Program
copyProgramDefault = 'cp';
[copyProgram,varargin] = uq_parseNameVal(varargin, 'CopyProgram',...
    copyProgramDefault, @(x) ischar(x));
if strcmp(copyMode,'local2local')
    copyProgram = copyProgramDefault;
end
% Guard against whitespaces
if ispc
    copyProgram = uq_Dispatcher_util_writePath(copyProgram,'pc');
else
    copyProgram = uq_Dispatcher_util_writePath(copyProgram,'linux');
end

% Recursive
isRecursiveDefault = false;
[isRecursive,varargin] = uq_parseNameVal(varargin, 'Recursive',...
    isRecursiveDefault, @(x) islogical(x));

% PrivateKey
privateKeyDefault = '';
[privateKey,varargin] = uq_parseNameVal(varargin, 'PrivateKey',...
    privateKeyDefault, @(x) ischar(x));
if ~isempty(privateKey)
    % Safe guard againts possible whitespaces in 'privateKey'
    if ispc
        privateKey = uq_Dispatcher_util_writePath(privateKey,'pc');
    else
        privateKey = uq_Dispatcher_util_writePath(privateKey,'linux');
    end
end

% MaxNumTrials
maxNumTrialsDefault = 5;
[maxNumTrials,varargin] = uq_parseNameVal(varargin, 'MaxNumTrials',...
    maxNumTrialsDefault, @(x) isscalar(x));

% Additional arguments
additionalArgsDefault = '';
[additionalArgs,varargin] = uq_parseNameVal(varargin,...
    'AdditionalArguments',...
    additionalArgsDefault, @(x) ischar(x) || iscell(x));
if iscell(additionalArgs)
    additionalArgs = sprintf('%s',additionalArgs{:});
end

%% Add private key to the optional arguments
if ~isempty(privateKey)
    additionalArgs = sprintf('%s -i %s', additionalArgs, privateKey);
end

%% Make the source as a cell array
if ~iscell(source)
    source = {source};
end

%% Copy File

% Set copy utility
cmdName = copyProgram;

% Set recursive flag
if isRecursive
    if strcmp(copyMode,'local2local')
        recursiveFlag = '-R';
    else
        recursiveFlag = '-r';
    end
else
    recursiveFlag = '';
end

switch copyMode
    case 'local2local'
        % <sourceFile> <destFolder>
        source = preprocessSource(source);
        dest = preprocessDest(dest);
        cmdArgs = {sprintf('%s %s %s', recursiveFlag, source, dest)};

    case 'local2remote'
        % <sourceFile> <sessionName>:"<destFolder>"
        source = preprocessSource(source);
        if ~ispc
            % With PSCP on Windows, it is enough to enclose the remote 
            % destination with double quotation marks even if
            % the destination contains spaces.
            % With SCP (both on Windows or Linux/Mac),
            % the whitespaces must be escaped.
            dest = preprocessDest(dest,'linux');
        end
        cmdArgs = {sprintf('%s %s %s %s:"%s"',...
            additionalArgs, recursiveFlag, source, sessionName, dest)};

    case 'remote2local'
        % <sessionName>:"<sourceFile>" <destFolder>
        source = preprocessSource(source,'linux');
        dest = preprocessDest(dest);
        cmdArgs = {sprintf('%s %s %s:"%s" %s',...
            additionalArgs, recursiveFlag, sessionName, source, dest)};

    case 'remote2remote'
        % <sessionName>:"<sourceFile>" <sessionName>:"<destFolder>"
        % '-3' option is to use the local machine as a route
        source = preprocessSource(source,'linux');
        dest = preprocessDest(dest,'linux');
        cmdArgs = {sprintf('-3 %s %s %s:"%s" %s:"%s"',...
           additionalArgs, recursiveFlag, sessionNameSrc, source,...
           sessionNameDest, dest)};
end

    [status,outputs] = ...
        uq_Dispatcher_util_runCLICommand(...
            cmdName, cmdArgs, '', 'MaxNumTrials', maxNumTrials);

end


%% ------------------------------------------------------------------------
function processedSource = preprocessSource(source,varargin)
% Preprocess the source files to safe guard against whitespaces.

% Verify inputs
if nargin < 2
    if ispc
        os = 'pc';
    else
        os = 'linux';
    end
else
    os = varargin{1};
end

% Multiple files are copied and passed as cell array
if iscell(source)
    if numel(source) == 1
        % Don't use curly braces
        processedSource = uq_Dispatcher_util_writePath(source{1},os);
    else
        % Safe guard against possible whitespaces in the filename
        processedSource = uq_map(@uq_Dispatcher_util_writePath,...
            source, 'Parameters', os);
        switch os

            case 'pc'
                % On PC, simply separate multiple files with a space
                processedSource = [sprintf('%s ',...
                    processedSource{1:end-1}),...
                    processedSource{end}];

            case 'linux'
                % On Linux, add curly braces and separate by comma 
                % (bash is assumed)
                processedSource = [sprintf('%s,',...
                    processedSource{1:end-1}),...
                    processedSource{end}];
                processedSource = ['{' processedSource '}'];
        end
    end
end

end


%% ------------------------------------------------------------------------
function processedDest = preprocessDest(dest,varargin)
% Preprocess the destination to safe guard against whitespaces.

if nargin < 2
    if ispc
        os = 'pc';
    else
        os = 'linux';
    end
else
    os = varargin{1};
end

processedDest = uq_Dispatcher_util_writePath(dest,os);
    
end
