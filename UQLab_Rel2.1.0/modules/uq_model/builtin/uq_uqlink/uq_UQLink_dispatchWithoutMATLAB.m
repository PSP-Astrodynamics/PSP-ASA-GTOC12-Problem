function varargout = uq_UQLink_dispatchWithoutMATLAB(...
    X, InternalProp, DispatcherObj, varargin)
%UQ_UQLINK_DISPATCHWITHOUTMATLAB dispatches UQLink model evaluation to a
%   remote computing resources without MATLAB/UQLab installed.

%% Parse and verify inputs
if nargin > 5
    action = varargin{1};
    recoverySource = varargin{2};
    selectedRunIndices = varargin{3};
elseif nargin > 4
    action = varargin{1};           % 'recover' or 'resume'
    recoverySource = varargin{2};   % if 'recover' can be a numeric array
    selectedRunIndices = [];
elseif nargin > 3
    action = varargin{1};
    recoverySource = '';
    selectedRunIndices = [];
else
    action = '';
    recoverySource = '';
    selectedRunIndices = [];
end

%% Use 'default' for the name of empty action
if isempty(action)
    action = 'default';
end

%% Parse recoverySource argument to get the recovery source file
if any(strcmpi(action,{'recover','resume'}))
    
    if isempty(recoverySource)
        % Empty recoverySource use the default, but only if not ThreadSafe.
        if  InternalProp.ThreadSafe
            error(['With thread-safe evaluation ''recoverySource'' file ',...
                'must be specified for ''recovery'' or ''resume''.'])
        else
            recoverySourceFile = InternalProp.Runtime.Processed;
        end
        
    else
    
        if ischar(recoverySource)
            if ~exist(recoverySource,'file')
                error('The given recovery source cannot be found!')
            end
        end
    
        if isnumeric(recoverySource) && InternalProp.ThreadSafe
            error(['With thread-safe evaluation ''recoverySource'' file ',...
                'must be specified for ''recovery'' with selected run indices.'])
        end
    
        if isnumeric(recoverySource)
            selectedRunIndices = recoverySource;
            recoverySourceFile = InternalProp.Runtime.Processed;
        else
            recoverySourceFile = recoverySource;
        end

    end
    
else
    recoverySourceFile = '';
end

%% Set local variables
numOfOutArgs = max(nargout,1);  % Number of output arguments
digitFormat = InternalProp.Runtime.DigitFormat;
executionPath = InternalProp.ExecutionPath;
templatePath = InternalProp.TemplatePath;

%% Initialized processed data (X,Y) and the size of each outputs Y
% Get the processed data from recoverySource if requested
[processedX,processedY,~,outputSizes] = uq_UQLink_helper_initProcessedXY(...
        X, action, numOfOutArgs, recoverySourceFile);

%% Verify the processed X
uq_UQLink_helper_verifyProcessedX(action, X, processedX)

%% Use current working directory if execution/template path is left empty
if isempty(executionPath)
    executionPath = pwd;
end

if isempty(templatePath)
    templatePath = pwd;
end

%% Create local run directories
% For thread-safety, create a directory with a unique name
% below the execution path unless if it is already dispatched.
currentDate = datestr(now);
uniqueID = uq_createUniqueID(InternalProp.ThreadSafeID);
runDirName = sprintf('%s_%s',InternalProp.Runtime.FolderName,uniqueID);
runDir = fullfile(executionPath,runDirName);
mkdir(runDir)
% TODO: use runDirName as the JobName

%% Define/Initialize Runtime variables
InternalProp.Runtime.Action = action;
InternalProp.Runtime.ChangeName = false(numel(InternalProp.Output.FileName));
InternalProp.Runtime.FirstValidRunIdx = -1;
InternalProp.Runtime.NumOfOutArgs = numOfOutArgs;
InternalProp.Runtime.OutputNotFound = true;
InternalProp.Runtime.OutputSizes = outputSizes;
InternalProp.Runtime.ReshapeMat = true;
InternalProp.Runtime.RunDir = runDir;
InternalProp.Runtime.TemplatePath = templatePath;
InternalProp.Runtime.TrueSizeIsNotKnown = true;

InternalProp.Runtime.X = X;
InternalProp.Runtime.ProcessedX = processedX;
InternalProp.Runtime.ProcessedY = processedY;
InternalProp.Runtime.SelectedRunIndices = selectedRunIndices;

%% Get the list of run indices (indices of cases to run)
runIndices = uq_UQLink_helper_getRunIndices(InternalProp);

%% Create input files
for ii = 1:numel(runIndices)
    
    runIdx = runIndices(ii);
    
    %% If ThreadSafe then create an isolated run directory per run index
    if InternalProp.ThreadSafe
        runDirIdx = fullfile(runDir,...
            sprintf('run%s',num2str(runIdx,digitFormat))); 
        mkdir(runDirIdx)
    else
        % Otherwise use the current running directory
        runDirIdx = runDir;
    end
    InternalProp.Runtime.RunIdx = runIdx;
    InternalProp.Runtime.RunDirIdx = runDirIdx;

    %% Write input files
    uq_UQLink_helper_writeInputs(X(ii,:),InternalProp)
end

%% Create the command to execute 3rd-party code
% Get the execution command
splitCmd = strsplit(InternalProp.Command);
exeCmd = splitCmd{1};
inpChar = strjoin(splitCmd(2:end));

% Add the executable path if it is given (otherwise, it's assumed in PATH)
if ~isempty(InternalProp.ExecutablePath)
    remoteSep = DispatcherObj.Internal.RemoteSep;
    exeCmd = sprintf('%s%s%s',InternalProp.ExecutablePath,remoteSep,exeCmd);
end
% Add double quotes around directory names with spaces
exeCmd = uq_UQLink_util_addQuotesOnPath(exeCmd,filesep);
% Append a 'cd'-to-the-running-directory to the command
% NOTE: remote machine is always running Linux.
exeCmd = uq_UQLink_util_addCD(...
    exeCmd, [runDirName '/run`printf %06d {1}`'], 'unix');
% There may be multiple command line arguments
% Make sure input files are a column array
inpFiles = strcat(InternalProp.Runtime.InputFileName, '.',...
    InternalProp.Runtime.InputExtension);
if isrow(inpFiles)
    inpFiles = transpose(inpFiles);
end
% Make sure input files are a column array
outFiles = strcat(InternalProp.Runtime.OutputFileName, '.',...
    InternalProp.Runtime.OutputExtension);
if isrow(outFiles)
    outFiles = transpose(outFiles);
end
% Combine input and output files
ioFiles = [inpFiles; outFiles];
numFiles = numel(ioFiles);
% Create command-line positional argument templates (i.e., {2}, {3}, {4})
argTpl = uq_map(@(x) sprintf('{%d}',x), transpose(2:numFiles+1));
% Create the command with the template
exeCmd = [exeCmd ' ' inpChar];
% Check if output file is written in the command line
outFileInExeCmd = any(cellfun(@(c) ~isempty(c),regexp(inpChar,outFiles,'once')));

exeCmd = uq_UQLink_util_replaceFilenames(exeCmd, ioFiles, argTpl);

%% Create Inputs Array
inputs = cell(numel(runIndices),1);

% Check if OUTPUTFILENAME appears in the execution command

for ii = 1:numel(runIndices)
    runIdx = runIndices(ii);
    
    inpChar = sprintf('%s ',inpFiles{:});
    % Modify the input file name in the command line
    inputBasenamesIndexed = strcat(...
        InternalProp.Runtime.InputFileName,...
        num2str(runIdx,InternalProp.Runtime.DigitFormat));
    inputs{ii} = uq_UQLink_util_replaceFilenames(...
        inpChar, InternalProp.Runtime.InputFileName, inputBasenamesIndexed);

    % Modify the output file name in the command line
    if outFileInExeCmd
        outChar = sprintf('%s ', outFiles{:});
        inpChar = sprintf('%s %s', inputs{ii}, outChar);
        outputBasenamesIndexed = strcat(InternalProp.Runtime.OutputFileName,...
            num2str(runIdx,InternalProp.Runtime.DigitFormat));
        inputs{ii} = uq_UQLink_util_replaceFilenames(...
            inpChar,...
            InternalProp.Runtime.OutputFileName,...
            outputBasenamesIndexed,...
            InternalProp.Runtime.OutputExtension);
    end
    
    inputs{ii} = [runIdx, strsplit(uq_strip(inputs{ii}))];

end

%% Define Fetch-Read-Merge

% Output files to fetch
outputFullnames = cell(numel(runIndices),1);
for i = 1:numel(runIndices)
    runIdx = runIndices(i);
    outputFilename = strcat(...
        InternalProp.Runtime.OutputFileName,...
        num2str(runIndices(i),InternalProp.Runtime.DigitFormat),...
        '.', InternalProp.Runtime.OutputExtension);

    outputFullnames{i} = strcat(...
        runDirName,...
        '/run', num2str(runIdx,InternalProp.Runtime.DigitFormat),...
        '/', outputFilename);
end

%% Create a mapping Job
jobTag = sprintf('uq_evalModel of <%s> on <%s>',...
    DispatcherObj.Internal.current_model.Name, currentDate);

% Inherit the execution mode from the Dispatcher object
execMode = DispatcherObj.ExecMode;

parseFun = @(X) parseDispatchedResults(X, InternalProp.Output.Parser,...
    numOfOutArgs, numel(outFiles));

if numOfOutArgs > 1
    mergeFun = @(X,P) mergeDispatchedResults(X);
else
    mergeFun = @(X,P) cell2mat(X{:});
end

[varargout{1:numOfOutArgs}] = uq_map(exeCmd, inputs, DispatcherObj,...
    'Tag', jobTag,...
    'AutoSubmit', true,...
    'AttachedFiles', {runDir},...
    'JobWallTime', DispatcherObj.JobWallTime,...
    'FetchStreams', false,...
    'ExecMode', execMode,...
    'Name', uniqueID, ...
    'NumOfOutArgs', numOfOutArgs,...
    'FilesToFetch', outputFullnames,...
    'Parse', parseFun,...
    'Merge', mergeFun);

%% Clean up
rmdir(runDir,'s')

end


%% ------------------------------------------------------------------------
function parsedResults = parseDispatchedResults(X,parser,numOfOutArgs,numOutFiles)

if numOutFiles > 1
    numIter = floor(numel(X)/numOutFiles);
    Y = cell(numIter,1); 
    j = 1;
    k = 3;
    for i = 1:numIter
        Y{i} = X(j:k);
        j = j+3;
        k = k+3;
    end
    [parsedResults{1:numOfOutArgs}] = uq_map(@(x) parser(x), Y);
else
    [parsedResults{1:numOfOutArgs}] = uq_map(@(x) parser(x), X);
end

end


%% ------------------------------------------------------------------------
function varargout = mergeDispatchedResults(X)

mergedResults = cellfun(@cell2mat,X,'UniformOutput',false);

[varargout{1:nargout}] = mergedResults{1:nargout};

end
