function success = uq_initialize_uq_uqlink(module)
% UQ_INITIALIZE_UQ_UQLINK initializes the UQLink model in UQLab

success = 0;

%% UNPROCESSED FIELDS
skipFields = {'Type', 'Name',  'Display'};

%% set default values
% Starting point of the counter when generating input files
OptDefaultcounter.Offset = 0 ;
% Number of digits in the name of the generated input files
OptDefaultcounter.Digits = 6 ;
% OptDefault Marker
OptDefaultMarker = {'<', 'X', '>'} ;
% Execution path
OptDefault.ExecutionPath = '';
% Execution path
OptDefault.ExecutablePath = '';
% Input extension
OptDefault.InputExtension = 'dat' ;
% Format of the variables in the input file
OptDefault.Format = '%1.6E';
% Display option
OptDefault.Display = 'standard' ;
% Archiving option
OptDefault.Archiving.Action = 'save' ;
OptDefault.Archiving.FolderName = '' ;
OptDefault.Archiving.TimeStamp = false ;
OptDefault.Archiving.Zip = true;
OptDefault.Archiving.SortFiles = true;

%% retrieve the current model
% Type is not checked here. If it the code arrives here then probably
% Options.Type = 'uqlink' or Options.Type = 'uq_uqlink'
if exist('module', 'var')
    current_model = uq_getModel(module);
else
    current_model = uq_getModel;
end

%% Retrieve the options and parse them
Options = current_model.Options ;

%% Make sure that mandatory variables are given and parse them
% The mandatory parameters will be parsed in current_model.Internal and will
% become the 'Parameters' options of the wrapper m-file

% Command
if ~isfield(Options,'Command') || isempty(Options.Command)
    error('A command line to execute the third-party software needs to be provided!') ;
else
    [optCommand, Options] = uq_process_option(Options, 'Command') ;
    current_model.Internal.Command = optCommand.Value ;
end

% Template file
if ~isfield(Options,'Template') || isempty(Options.Template)
    error('A template file needs to be defined!') ;
else
    [optTemplate, Options] = uq_process_option(Options, 'Template') ;
    current_model.Internal.Template = optTemplate.Value ;
    % The name without extension is defined later
end
% Make sure that the option is always in a cell array
if ~iscell(current_model.Internal.Template)
    current_model.Internal.Template = {current_model.Internal.Template} ;
end
% Ouput file options
if ~isfield(Options,'Output') || isempty(Options.Output)
    error('Options related to the output file need to be provided!') ;
else
    % Output file name
    if ~isfield(Options.Output, 'FileName') || isempty(Options.Output.FileName)
        error('The output file name should be provided!') ;
    end
    [filename, Options.Output] = uq_process_option(Options.Output,'FileName') ;
    if ~ischar(filename.Value) && ~isstring(filename.Value) && ~iscell(filename.Value)
        error('The output file name should be a string character or a cell array!');
    end
    current_model.Internal.Output.FileName = filename.Value ;
    % Make sure that the option is always in a cell array
    if ~iscell(current_model.Internal.Output.FileName)
        current_model.Internal.Output.FileName = {current_model.Internal.Output.FileName} ;
    end
    % Parser
    if ~isfield(Options.Output, 'Parser') || isempty(Options.Output.Parser)
        error('The output file parser should be provided!') ;
    end
    [parser, Options.Output] = uq_process_option(Options.Output,'Parser') ;
    if ~ischar(parser.Value) && ~isstring(parser.Value)
        error('The output file parser should be a string character!');
    end
    % Throw an error if the file does not exist or does not belong to
    % the current matlab path:
    if exist(parser.Value,'file') == 0
        error('The output parser name is incorrect or does not belong to the current MATLAB path');
    end
    % Store the mfile location in Internal
    try
        current_model.Internal.Location = which(parser.Value);
    catch
        % in case which() gives an error it's due to Options.Function being
        % an anonymous function
        error('The parser m-file : %s cannot be found!', parser.Value);
    end
    
    % Construct function handle from user input (string), then parse it.
    current_model.Internal.Output.Parser = str2func(parser.Value) ;
    
    % Check for leftover options inside Options.Output
    uq_options_remainder(Options.Output, ' UQLink output options.');
    % Remove Options.Output
    Options = rmfield(Options, 'Output');
end

%% Optional
% Counter (to create the input and output files) - Optional parameter
if isfield(Options, 'Counter')
    % Counter offset
    [optOffset, Options.Counter] = uq_process_option(Options.Counter, ...
        'Offset', OptDefaultcounter.Offset, 'double') ;
    if optOffset.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The counter offset options was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:offset_invalid';
        uq_logEvent(current_model, EVT);
    end
    if optOffset.Missing
        EVT.Type = 'D';
        EVT.Message = 'The counter offset options was missing. Assigning the default value.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:offset_missing';
        uq_logEvent(current_model, EVT);
    end
    current_model.Internal.Counter.Offset = optOffset.Value ;
    
    % Counter digits
    [optDigits, Options.Counter] = uq_process_option(Options.Counter, ...
        'Digits', OptDefaultcounter.Digits, 'double') ;
    if optDigits.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The counter digits options was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:digits_invalid';
        uq_logEvent(current_model, EVT);
    end
    if optDigits.Missing
        EVT.Type = 'D';
        EVT.Message = 'The counter digits options was missing. Assigning the default value.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:digits_missing';
        uq_logEvent(current_model, EVT);
    end
    % Make sure that digits is an integer
    if mod(optDigits.Value,1) ~= 0
        error('The option .Digits must be an integer!') ;
    end
    % Now check that Digits and Offset are consistent
    if numel(num2str(optOffset.Value+1)) > optDigits.Value
        warning('The starting counter point has more digit than .Digits option');
        fprintf('The .Digits options is set to %u \n', numel(num2str(optOffset.Value+1))) ;
        optDigits.Value = numel(num2str(optOffset.Value+1)) ;
    end
    current_model.Internal.Counter.Digits = optDigits.Value ;
    
    % Check for leftover options inside Options.Counter
    uq_options_remainder(Options.Counter, ' UQLink counter options.');
    % Remove Options.Counter
    Options = rmfield(Options, 'Counter');
else
    % No Counter option was set by the user. Assign the default values to
    % the whole structure
    [optCounter, Options] = uq_process_option(Options, 'Counter', ...
        OptDefaultcounter,'struct');
    if optCounter.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The Counter option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:counter_invalid';
        uq_logEvent(current_model, EVT);
    end
    if optCounter.Missing
        EVT.Type = 'D';
        EVT.Message = 'The Counter option was missing. Assigning the default values.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:counter_missing';
        uq_logEvent(current_model, EVT);
    end
    current_model.Internal.Counter = optCounter.Value ;
end

% Marker
[optMarker, Options] = uq_process_option(Options, 'Marker', OptDefaultMarker, ...
    {'cell'});
if optMarker.Invalid
    EVT.Type = 'W';
    EVT.Message = 'The Marker option was invalid. Using the default value instead.';
    EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:marker_invalid';
    uq_logEvent(current_model, EVT);
end
if optMarker.Missing
    EVT.Type = 'D';
    EVT.Message = 'The Marker option was missing. Assigning the default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:marker_missing';
    uq_logEvent(current_model, EVT);
end
% Make sure that the Marker option is a cell array with three
% elementes: Start delimiter, variable name and end delimiter
if length(optMarker.Value) ~= 3
    error('The marker should be a cell array with three elements!');
end
current_model.Internal.Marker = optMarker.Value ;

% .ExecutionPath : Path to the folder where the program will be executed
%  and where the input files belong.
[optExePath, Options] = uq_process_option(Options, 'ExecutionPath',...
    OptDefault.ExecutionPath, {'string','char'});
if optExePath.Invalid
    EVT.Type = 'D';
    EVT.Message = 'The Execution Path option was missing. Assigning the default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:executionpath_missing';
    uq_logEvent(current_model, EVT);
end
% If optExePath is empty, then it is a default value. Set it as the current
% path
%if isempty(optExePath.Value)
%    optExePath.Value = pwd ;
%end
current_model.Internal.ExecutionPath = optExePath.Value ;

% .ExecutablePath : Path to the folder containing the .exe
[optExecutablePath, Options] = uq_process_option(Options, 'ExecutablePath',...
    OptDefault.ExecutablePath, {'string','char'});
if optExecutablePath.Invalid
    warning('The ExecutablePath option was invalid. Using the default value instead.')
end
current_model.Internal.ExecutablePath = optExecutablePath.Value ;

% .Display : Path to the folder where the program will be executed
%  and where the input files belong.
[optDisplay, Options] = uq_process_option(Options, 'Display',...
    OptDefault.Display, {'string','char'});
if optDisplay.Invalid
    EVT.Type = 'D';
    EVT.Message = 'The Display option was invalid. Assigning the default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:display_invalid';
    uq_logEvent(current_model, EVT) ;
elseif ~ any(strcmpi(optDisplay.Value, {'quiet','standard','verbose'}) )
    EVT.Type = 'D';
    EVT.Message = 'The Display option was invalid. Assigning the default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:display_invalid';
    uq_logEvent(current_model, EVT) ;
    optDisplay.Value = OptDefault.Display ;
else
    % Do nothing
end
current_model.Internal.Display = optDisplay.Value ;

% Format in which the data are read in the true file
[optFormat, Options] = uq_process_option(Options, 'Format',...
    OptDefault.Format, {'string','char','cell'}) ;
if optFormat.Invalid
    EVT.Type = 'W';
    EVT.Message = 'The format option was invalid. Using the default value instead.';
    EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:format_invalid';
    uq_logEvent(current_model, EVT);
end
if optFormat.Missing
    EVT.Type = 'D';
    EVT.Message = 'The format option was missing. Assigning the default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:format_missing';
    uq_logEvent(current_model, EVT);
end

current_model.Internal.Format = optFormat.Value ;
if ~iscell(current_model.Internal.Format)
    current_model.Internal.Format = {current_model.Internal.Format} ;
end

% Archiving options
% Default name of the archiving folder = Model name without any space
current_model.Internal.Runtime.FolderName = ...
    current_model.Name(~isspace(current_model.Name));

if isfield(Options,'Archiving')
    % Format in which the data are read in the true file
    [optArchiveAction, Options.Archiving] = uq_process_option(Options.Archiving, 'Action',...
        OptDefault.Archiving.Action, {'string','char'}) ;
    if optArchiveAction.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The format option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_invalid';
        uq_logEvent(current_model, EVT);
    end
    if optArchiveAction.Missing
        EVT.Type = 'D';
        EVT.Message = 'The archive option was missing. Assigning the default values.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_missing';
        uq_logEvent(current_model, EVT);
    end
    % If the given option is not known, use the default, i.e 'save'
    if ~any(strcmpi(optArchiveAction.Value, {'save', 'delete', 'ignore'}))
        EVT.Type = 'W';
        EVT.Message = 'The format option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_invalid';
        uq_logEvent(current_model, EVT);
        optArchiveAction.Value = OptDefault.Archiving.Action;
    end
        
    % Parse value
    current_model.Internal.Archiving.Action = optArchiveAction.Value ;
 
%     % 'empty' Action is considered 'ignore', make it explicit
%     if isempty(current_model.Internal.Archiving.Action)
%         current_model.Internal.Archiving.Action = 'ignore';
%     end
    
    isSave = strcmpi(current_model.Internal.Archiving.Action, 'save');
    
    % Name of the folder where the results should be saved
    current_model.Internal.Runtime.ArchiveNameIsSpecified = true;

    [optArchiveFName, Options.Archiving] = uq_process_option(Options.Archiving, 'FolderName',...
        OptDefault.Archiving.FolderName, {'string','char'}) ;
    if optArchiveFName.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The Archiving FolderName option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_invalid';
        uq_logEvent(current_model, EVT);
        current_model.Internal.Runtime.ArchiveNameIsSpecified = false;
    end
    if optArchiveFName.Missing
        EVT.Type = 'D';
        EVT.Message = 'The Archiving FolderName options was missing. Assigning the default values.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_missing';
        uq_logEvent(current_model, EVT);
        current_model.Internal.Runtime.ArchiveNameIsSpecified = false;
    end
    
    % If the user did not set any name, use the name of the analysis
    if isempty(optArchiveFName.Value)
        optArchiveFName.Value = current_model.Internal.Runtime.FolderName;
    end
    
    % Now add the time stamp
    % Parse it
    current_model.Internal.Archiving.FolderName = optArchiveFName.Value ;
    
    % Zip results or not ?
    [optArchiveZip, Options.Archiving] = uq_process_option(...
        Options.Archiving, 'Zip', OptDefault.Archiving.Zip, 'logical');
    if optArchiveZip.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The Zip Archiving option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_invalid';
        uq_logEvent(current_model, EVT);
    end
    if optArchiveZip.Missing
        EVT.Type = 'D';
        EVT.Message = 'The Zip Archiving options was missing. Assigning the default values.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_missing';
        uq_logEvent(current_model, EVT);
    end
    
    current_model.Internal.Archiving.Zip = optArchiveZip.Value;
    if optArchiveZip.Value == 1 && ~isSave
        if ~optArchiveZip.Missing
            warning('The Archiving.Zip option can be set to ''true'' only if the Archiving.Action options is set to ''save''');
            warning('Setting .Archiving.Zip option to ''false''');
        end
        current_model.Internal.Archiving.Zip = false;
    end

        % .Archiving.TimeStamp: Add a time stamp to the .zip and .mat files
        % created along the algorithm
    [optArchiveTimeStamp, Options.Archiving] = uq_process_option(...
        Options.Archiving, 'TimeStamp',...
        OptDefault.Archiving.TimeStamp, 'logical');
    if optArchiveTimeStamp.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The TimeStamp Archiving option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_timestamp_invalid';
        uq_logEvent(current_model, VT);
    end
    if optArchiveTimeStamp.Missing
        EVT.Type = 'D';
        EVT.Message = 'The TimeStamp Archiving options was missing. Assigning the default values.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_timestamp_missing';
        uq_logEvent(current_model,EVT);
    end
    current_model.Internal.Archiving.TimeStamp = optArchiveTimeStamp.Value;
    
    % .Archiving.SortFiles: Flog to sort files to inputs, outputs, and aux.
    [optArchiveSortFiles, Options.Archiving] = uq_process_option(...
        Options.Archiving, 'SortFiles',...
        OptDefault.Archiving.SortFiles, 'logical');
    if optArchiveSortFiles.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The SortFiles Archiving option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_sortfiles_invalid';
        uq_logEvent(current_model, VT);
    end
    if optArchiveSortFiles.Missing
        EVT.Type = 'D';
        EVT.Message = 'The SortFiles Archiving options was missing. Assigning the default values.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_sortfiles_missing';
        uq_logEvent(current_model,EVT);
    end
    current_model.Internal.Archiving.SortFiles = optArchiveSortFiles.Value;
    
    if optArchiveSortFiles.Value && ~isSave
        if ~optArchiveSortFiles.Missing
            warning('The Archiving.SortFiles option can be set to ''true'' only if the Archiving.Action options is set to ''save''');
            warning('Setting .Archiving.SortFiles option to ''false''') ;
        end
        current_model.Internal.Archiving.Zip = false ;
    end
    
    % Check for leftover options inside Options.Archiving
    uq_options_remainder(Options.Archiving, ' UQLink archving options.');
    % Remove Options.Archiving
    Options = rmfield(Options, 'Archiving');
    
else
    [optArchive, Options] = uq_process_option(Options, 'Archiving',...
        OptDefault.Archiving, 'struct') ;
    if optArchive.Invalid
        EVT.Type = 'W';
        EVT.Message = 'The  Archiving option was invalid. Using the default value instead.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_invalid';
        uq_logEvent(current_model, EVT);
    end
    if optArchive.Missing
        EVT.Type = 'D';
        EVT.Message = 'The Archiving options was missing. Assigning the default values.';
        EVT.eventID = 'uqlab:OptDefault_model:uq_link:init:archive_missing';
        uq_logEvent(current_model, EVT);
    end
    
    % Parse it
    current_model.Internal.Archiving = optArchive.Value ;
    
    if isempty(optArchive.Value.FolderName)
        current_model.Internal.Archiving.FolderName = current_model.Internal.Runtime.FolderName ;
    end
    current_model.Internal.Runtime.ArchiveNameIsSpecified = false;
end

% Set the archiving value
if ispc
    dummy = strsplit(current_model.Internal.Archiving.FolderName, '\') ;
elseif isunix || ismac
    dummy = strsplit(current_model.Internal.Archiving.FolderName, '/') ;
end
if length(dummy) > 1
    % then the name is a path
    current_model.Internal.Runtime.ArchiveNameisPath = true ;
else
    current_model.Internal.Runtime.ArchiveNameisPath = false ;
end

% Write the final fodler name, \ie including its path in a runtime variable
if ~current_model.Internal.Runtime.ArchiveNameisPath
    current_model.Internal.Runtime.ArchiveFolderName = ...
        fullfile(current_model.Internal.ExecutionPath, current_model.Internal.Archiving.FolderName) ;
else
    current_model.Internal.Runtime.ArchiveFolderName = current_model.Internal.Archiving.FolderName ;
end

%% .ThreadSafe: Flag to enforce a thread-safe UQLink model evaluation
OptDefault.ThreadSafe = false;
[optThreadSafe,Options] = uq_process_option(...
    Options, 'ThreadSafe', OptDefault.ThreadSafe, 'logical');
if optThreadSafe.Invalid
    % Invalid specification, included if the value is empty
    EVT.Type = 'W';
    EVT.Message = 'ThreadSafe option is invalid; assign default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uqlink:init:threadsafe_invalid';
    uq_logEvent(current_model,EVT);
end
if optThreadSafe.Missing
    EVT.Type = 'D';
    EVT.Message = 'ThreadSafe option is missing; assign default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uqlink:init:threadsafe_missing';
    uq_logEvent(current_model,EVT);
end
current_model.Internal.ThreadSafe = optThreadSafe.Value;

%% .ThreadSafeID: The identifier to ensure thread-safety
OptDefault.ThreadSafeID = 'datetime';
[optThreadSafeID,Options] = uq_process_option(...
    Options, 'ThreadSafeID', OptDefault.ThreadSafeID, 'char');
if optThreadSafeID.Invalid
    % Invalid specification, included if the value is empty
    EVT.Type = 'W';
    EVT.Message = 'ThreadSafeID option is invalid; assign default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uqlink:init:threadsafeid_invalid';
    uq_logEvent(current_model,EVT);
end
if optThreadSafeID.Missing
    EVT.Type = 'D';
    EVT.Message = 'ThreadSafeID option is missing; assign default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uqlink:init:threadsafeid_missing';
    uq_logEvent(current_model,EVT);
end
if isempty(optThreadSafeID.Value)
    current_model.Internal.ThreadSafeID = OptDefault.ThreadSafeID;
else
    current_model.Internal.ThreadSafeID = optThreadSafeID.Value;
end

%% .TemplatePath : Path to the directory where the templates are located
OptDefault.TemplatePath = '';
[optTplPath,Options] = uq_process_option(Options, 'TemplatePath',...
    OptDefault.ExecutionPath, {'string','char'});
if optTplPath.Invalid
    EVT.Type = 'D';
    EVT.Message = 'TemplatePath option is missing; assign default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uqlink:init:templatepath_missing';
    uq_logEvent(current_model, EVT);
end
% If tplPath.Value is empty, then it is a default value.
% Set it to the current ExecutionPath
if isempty(optTplPath.Value)
    optTplPath.Value = current_model.Internal.ExecutionPath;
end
current_model.Internal.TemplatePath = optTplPath.Value;

%% .RemoteMATLAB: Flag that indicates if MATLAB/UQLab is remotely available
% Only relevant for Dispatching
OptDefault.RemoteMATLAB = false;
[optRemoteMATLAB,Options] = uq_process_option(Options, 'RemoteMATLAB',...
    OptDefault.RemoteMATLAB, 'logical');
if optRemoteMATLAB.Invalid
    EVT.Type = 'D';
    EVT.Message = 'RemoteMATLAB option is missing; assign default values.';
    EVT.eventID = 'uqlab:OptDefault_model:uqlink:init:remotematlab_missing';
    uq_logEvent(current_model,EVT);
end
% If optRemoteMATLAB.Value is empty, then it is a default value.
if isempty(optRemoteMATLAB.Value)
    optRemoteMATLAB.Value = OptDefault.RemoteMATLAB;
end
current_model.Internal.RemoteMATLAB = optRemoteMATLAB.Value;

%% Create runtime variables
% Input file name and its extension in two separate variables
% Get the input file name without the '.template' extension
for tt = 1:length(current_model.Internal.Template)
    
    splittedIN = strsplit(current_model.Internal.Template{tt},'.') ;
    if length(splittedIN) < 2
        error('The template name should contain the name of the input file and its extension (at least)');
    end
    current_model.Internal.Runtime.InputFileName{tt} = splittedIN{1} ;
    current_model.Internal.Runtime.InputExtension{tt} = splittedIN{2} ;
end
% Output file name and its extension in two separate variables
for tt = 1:length(current_model.Internal.Output.FileName)
    
    splittedIN = strsplit(current_model.Internal.Output.FileName{tt},'.') ;
    if length(splittedIN) < 2
        error('The output file name should contain the name of the input file and its extension');
    end
    current_model.Internal.Runtime.OutputFileName{tt} = splittedIN{1} ;
    current_model.Internal.Runtime.OutputExtension{tt} = splittedIN{2} ;
    if length(splittedIN)>2
       for kk = 3:length(splittedIN) 
         current_model.Internal.Runtime.OutputExtension{tt} = ...
             [current_model.Internal.Runtime.OutputExtension{tt}, '.', splittedIN{kk} ];
       end
    end
end

% Number of digits in the name of the files
current_model.Internal.Runtime.DigitFormat = strcat('%0', num2str(current_model.Internal.Counter.Digits), 'u') ;
% Path where matrix of available runs will be saved
% Path to the file where this should be saved. This is the name of the
% Model
saveName = current_model.Name(~isspace(current_model.Name)) ;
current_model.Internal.Runtime.Processed_generic = ...
    fullfile( current_model.Internal.ExecutionPath, ...
    strcat( saveName, '.mat' )) ;

% If no time stamp get the name of the .mat file that will be actually used
current_model.Internal.Runtime.Processed  = ...
    current_model.Internal.Runtime.Processed_generic  ;
%% Check for unused options
% Remove some fields that are not processed here:
fieldsToRemove = skipFields(isfield(Options,skipFields)) ;

Options = rmfield(Options, fieldsToRemove);

% Check if there was something else provided
uq_options_remainder(Options, ...
    current_model.Name, ...
    skipFields, current_model);

%% Initialization succesfully finished
success = 1 ;

end