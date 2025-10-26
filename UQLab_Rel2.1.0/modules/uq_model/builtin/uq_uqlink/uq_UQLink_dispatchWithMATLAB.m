function varargout = uq_UQLink_dispatchWithMATLAB(X, InternalProp, varargin)
%

%% Verify inputs
if nargin > 4
    action = varargin{1};
    recoverySource = varargin{2};
    selectedRunIndices = varargin{3};
elseif nargin > 3
    action = varargin{1};           % 'recover' or 'resume'
    recoverySource = varargin{2};   % if 'recover' can be a numeric array
    selectedRunIndices = [];
elseif nargin > 2
    action = varargin{1};
    recoverySource = '';
    selectedRunIndices = [];
else
    action = '';
    recoverySource = '';
    selectedRunIndices = [];
end

%% Use default for the name of empty action
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

%% Initialize processed data (X,Y) and the size of each outputs Y
% Get the processed data from recoverySource if requested
[processedX,processedY,allX,outputSizes] = ...
    uq_UQLink_helper_initProcessedXY(X, action, numOfOutArgs, recoverySourceFile);

%% Verify the processed X
uq_UQLink_helper_verifyProcessedX(action, X, processedX)

%%
executionPath = InternalProp.ExecutionPath; % Should be decided that if it is empty just use current working directory
if isempty(executionPath)
    executionPath = pwd;
end

%% Create local run directories (optional)
DispatcherObj = uq_getDispatcher;
if InternalProp.ThreadSafe
    % For thread-safety, create a directory with a unique name
    % below the execution path unless if it is already dispatched.
    % TODO: what if it's already dispatched.
    uniqueID = uq_createUniqueID(InternalProp.ThreadSafeID);
    uniqueName = sprintf('%s_%s',InternalProp.Runtime.FolderName,uniqueID);
    processedBasename = uniqueName;
    
    % Dispatcher
    if ~strcmp(DispatcherObj.Type,'empty') && DispatcherObj.isExecuting
        cpuID = DispatcherObj.Runtime.cpuID;
        cpuIDChar = sprintf('%.4d', cpuID);
        processedBasename = InternalProp.Runtime.FolderName;
        processedBasename = sprintf('%s_%s', processedBasename, cpuIDChar);
        runDir = executionPath;
    else
        runDir = {executionPath,uniqueName};
        runDir = fullfile(runDir{:});
        mkdir(runDir)
    end
    
    processedFile = fullfile(executionPath,[processedBasename '.mat']);
else
    % Run things directly in the ExecutionPath
    runDir = executionPath;
    processedFile = fullfile(executionPath,...
        [InternalProp.Runtime.FolderName '.mat']);
end

%% Create MAT file that stored processed results
if strcmpi(action,'default')
    % TODO: what if it's already dispatched? then use cpuIdx
    uq_AllX = allX; % For backward compatibility
    save(processedFile, 'uq_AllX', '-v7.3')
else
    if InternalProp.ThreadSafe
        % In ThreadSafe, if recover or resume,
        % then copy the content of recovery source file to a new one.
        copyfile(recoverySourceFile,processedFile)
    end
end

%% Create archive directories (optional)
% TODO: what if it's already dispatched
if strcmpi(InternalProp.Archiving.Action,'save')
    
    if InternalProp.ThreadSafe
        if InternalProp.Runtime.ArchiveNameIsSpecified
            SaveDir.Parent = InternalProp.Runtime.ArchiveFolderName;
        else
            SaveDir.Parent = runDir;
        end
    else
        SaveDir.Parent = InternalProp.Runtime.ArchiveFolderName;        
    end
    
    if ~isempty(SaveDir.Parent) && ~isdir(SaveDir.Parent)
        mkdir(SaveDir.Parent)
    end

    if InternalProp.Archiving.SortFiles
        SaveDir.Input = fullfile(SaveDir.Parent,'UQLinkInput');            
        SaveDir.Output = fullfile(SaveDir.Parent,'UQLinkOutput');
        SaveDir.Aux = fullfile(SaveDir.Parent, 'UQLinkAux');
    else
        SaveDir.Input = SaveDir.Parent;
        SaveDir.Output = SaveDir.Parent;
        SaveDir.Aux = SaveDir.Parent;
    end
    
    if ~isempty(SaveDir.Input) && ~isdir(SaveDir.Input)
        mkdir(SaveDir.Input)
    end
    if ~isempty(SaveDir.Output) && ~isdir(SaveDir.Output)
        mkdir(SaveDir.Output)
    end
    if ~isempty(SaveDir.Aux) && ~isdir(SaveDir.Aux)
        mkdir(SaveDir.Aux)
    end
    
else
    SaveDir = '';
end

%% Set local variables
digitFormat = InternalProp.Runtime.DigitFormat;
if ~strcmp(DispatcherObj.Type,'empty') && DispatcherObj.isExecuting
    % If dispatched, then the templates are all in the execution path
    templatePath = InternalProp.ExecutionPath;
else
    templatePath = InternalProp.TemplatePath;
end

%% Define/Initialize Runtime variables
InternalProp.Runtime.Action = action;
InternalProp.Runtime.ChangeName = false(numel(InternalProp.Output.FileName));
InternalProp.Runtime.FirstValidRunIdx = -1;
InternalProp.Runtime.NumOfOutArgs = numOfOutArgs;
InternalProp.Runtime.OutputNotFound = true;
InternalProp.Runtime.OutputSizes = outputSizes;
InternalProp.Runtime.ProcessedFile = processedFile;
InternalProp.Runtime.ReshapeMat = true;
InternalProp.Runtime.RunDir = runDir;
InternalProp.Runtime.SaveDir = SaveDir;
InternalProp.Runtime.TemplatePath = templatePath;
InternalProp.Runtime.TrueSizeIsNotKnown = true;

InternalProp.Runtime.X = X;
InternalProp.Runtime.ProcessedX = processedX;
InternalProp.Runtime.ProcessedY = processedY;
InternalProp.Runtime.SelectedRunIndices = selectedRunIndices;

%% Get the list of run indices (indices of cases to run)
runIndices = uq_UQLink_helper_getRunIndices(InternalProp);

%% Check if output filename appears in any of the template file
% The logic: if found, then we assume that the output filename with index
% *will be* produced after executing the 3rd-party code.
% NOTE: This is a very simple pattern checking. Inside a template file,
% a string that matches 'OutputFileName' may exist although it does not
% refer explicitly to Output (e.g., OutputFileName = 'output' would
% match both 'output.lib' vs. 'output.out').
templateFullFiles = fullfile(templatePath,InternalProp.Template);
matchedPattern = uq_UQLink_util_checkForPatternInFiles(...
    templateFullFiles,...
    InternalProp.Runtime.OutputFileName);
if matchedPattern
    % An output filename is found in one of the template
    InternalProp.Runtime.OutputNotFound = false;
end

%% Check if output filename appears in the execution command
matchedPattern = regexp(InternalProp.Command,...
    strcat(InternalProp.Runtime.OutputFileName,'.',InternalProp.Runtime.OutputExtension),...
    'match');
if any(cellfun(@(x) ~isempty(x), matchedPattern))
    % An output filename is found in the execution command
    InternalProp.Runtime.OutputNotFound = false;
end

%%
if ~strcmp(DispatcherObj.Type,'empty') && DispatcherObj.isExecuting
    originalRowSize = size(DispatcherObj.Internal.Data.X,1);
    ncpu = DispatcherObj.Runtime.ncpu;
    cpuID = DispatcherObj.Runtime.cpuID;
    counterOffset = floor(originalRowSize/ncpu)*(cpuID-1);
    %filenameCounter = (counterOffset+1):counterOffset+size(X,1);
    runIndices = runIndices + counterOffset;
end

%% Iterate over run indices
for ii = 1:numel(runIndices)
    
    runIdx = runIndices(ii);

    if any(strcmpi(InternalProp.Display,{'verbose','standard'}))
        fprintf('Running Realization %d\n',runIdx)
    end
    
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
    InternalProp.Runtime.RawIdx = ii;

    %% Write input files
    uq_UQLink_helper_writeInputs(X(ii,:),InternalProp)

    %% Keep record of files before execution
    % Just before execution, list all files that are in the execution path
    listOfFilesPreExec = uq_UQLink_util_getListOfFiles(runDirIdx);

    %% Execute the command char
    exeSuccess = uq_UQLink_helper_execExtCode(InternalProp);

    %% Get the list of files after execution
    % Just after execution, list all files that are in the execution path
    listOfFilesPostExec = uq_UQLink_util_getListOfFiles(runDirIdx);
    
    %% Create outputfilenames to parse
    % Name of the output file
    outputFiles = cellfun(...
        @(X) fullfile(runDirIdx,X),...
        strcat(InternalProp.Runtime.OutputFileName,...
        num2str(runIdx,InternalProp.Runtime.DigitFormat),...
            '.', InternalProp.Runtime.OutputExtension),...
        'UniformOutput', false);

    if InternalProp.Runtime.OutputNotFound
        % We assume that if output files have been explicitly specified
        % whether in the template or in the command then they will be
        % there, so the input filename with index will also give output
        % filename with index.
        % Check if these files indeed exist (Option 1) 
        outputFilesExist = cellfun(@(x) logical(exist(x,'file')),...
            outputFiles);
        
        % If not then use the one user specified in the configuration
        % options (Option 2).
        outputFiles(~outputFilesExist) = cellfun(...
            @(X) fullfile(runDirIdx,X),...
            InternalProp.Output.FileName(~outputFilesExist),...
            'UniformOutput', false);
        % Get the flag to change the name used in the archival.
        InternalProp.Runtime.ChangeName(~outputFilesExist) = true;
    end

    %% Parse Current Output
    [currentOutputs,InternalProp] = uq_UQLink_helper_parseOutputs(...
        exeSuccess, outputFiles, InternalProp);

    %% Reshape Processed Y
    if strcmpi(InternalProp.Runtime.Action,'default')
        % If the first valid run Idx > 1, this means all other previous
        % results have been NaNs of appropriate size.
        % Re-write all the values up to previous iteration
        % with the appropriate size
        if InternalProp.Runtime.FirstValidRunIdx > 1 && ...
                InternalProp.Runtime.ReshapeMat
            processedY = uq_UQLink_util_reshapeCellWithNaNs(...
                processedY,...
                InternalProp.Runtime.OutputSizes,...
                ii-1,...
                numOfOutArgs);
                InternalProp.Runtime.ReshapeMat = false;
        end
    end

    %% Update processed results
    if ~strcmp(DispatcherObj.Type,'empty') && DispatcherObj.isExecuting
        idx = ii;
    else
        idx = runIdx;
    end
    % processed X up to this point
    currentInputs = X(idx,:);
    % processed Y up to this point
    for oo = 1:numOfOutArgs
         processedY{oo}(idx,:) = currentOutputs{oo};
    end

    %% Update the processed MAT file
    uq_UQLink_helper_updateProcessedFile(...
        currentInputs, currentOutputs, InternalProp)
    
    %% Manage resulting files
    uq_UQLink_helper_manageFiles(...
        listOfFilesPostExec, listOfFilesPreExec, InternalProp)
    
end

%% Compressed the archive (optional)
if strcmp(DispatcherObj.Type,'empty')
    if InternalProp.Archiving.Zip
        zip(SaveDir.Parent,SaveDir.Parent)
        rmdir(SaveDir.Parent,'s')
    end
end

%% Return the outputs

% Return the results
if numOfOutArgs == 1
    varargout{1} = processedY{:};
else
    [varargout{1:numOfOutArgs}] = processedY{:};
end

end
