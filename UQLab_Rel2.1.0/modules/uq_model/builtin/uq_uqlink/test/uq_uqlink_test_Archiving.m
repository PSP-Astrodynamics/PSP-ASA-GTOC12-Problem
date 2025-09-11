function pass = uq_uqlink_test_Archiving(level)
%UQ_UQLINK_TEST_ARCHIVING tests that the archiving options of the module
%   work properly.
%
% See also: UQ_READ_SSBEAMDEFLECTION.m UQ_UQLINK_TEST_POSSIBLECASES.m

%% Initialize the test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...', level, mfilename)

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
for i = 1:numel(testFunctions)
    feval(testFunctions{i})
end

%% Return the results
pass = true;

end


%% ------------------------------------------------------------------------
function testZipDefault()
% A test case for the default case, files are saved and archived into zip.

% Set up a UQLink model
EXECBASENAME = 'uq_SimplySupportedBeam_v2';
if ispc
    EXECSUFFIX = 'win';
else
    if ismac
        EXECSUFFIX = 'mac';
    else
        EXECSUFFIX = 'linux';
    end
end
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

ModelOpts.Type = 'UQLink' ;
ModelOpts.Name = uq_createUniqueID();
currentDir = fileparts(mfilename('fullpath'));
ModelOpts.ExecutionPath = fullfile(currentDir,'Case2');
ModelOpts.Command = [...
    fullfile(ModelOpts.ExecutionPath,EXECNAME),...
    ' SSB_Input_v2_1.inp', ' SSB_Input_v2_2.inp'];
ModelOpts.Template = {'SSB_Input_v2_1.inp.tpl', 'SSB_Input_v2_2.inp.tpl'};
ModelOpts.Output.Parser= 'uq_read_SSBeamDeflection';
ModelOpts.Output.FileName = 'output.out';
ModelOpts.Display = 'quiet';

% Create a UQLink model
myModel = uq_createModel(ModelOpts);

% Evaluate the UQLink model
X = [0.15 0.3 5 30000e6 1e4];
uq_evalModel(myModel,X);

try
    % Verify if the zip file exist
    assert(logical(exist(...
        sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName),...
        'file')))
catch e
    delete(myModel.Internal.Runtime.Processed)
    rethrow(e)
end

% Clean up
delete(myModel.Internal.Runtime.Processed)
delete(sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName))

end


%% ------------------------------------------------------------------------
function testZipTrue()
% A test for the case that 'Archive.Zip' is assigned to true.
% The zip file of the files produced during 3rd-party code executions 
% will be created.

% Set up a UQLink model
EXECBASENAME = 'uq_SimplySupportedBeam_v2';
if ispc
    EXECSUFFIX = 'win';
else
    if ismac
        EXECSUFFIX = 'mac';
    else
        EXECSUFFIX = 'linux';
    end
end
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

ModelOpts.Type = 'UQLink';
ModelOpts.Name = uq_createUniqueID();
currentDir = fileparts(mfilename('fullpath'));
ModelOpts.ExecutionPath = fullfile(currentDir,'Case2');
ModelOpts.Command = [...
    fullfile(ModelOpts.ExecutionPath,EXECNAME),...
    ' SSB_Input_v2_1.inp', ' SSB_Input_v2_2.inp'];
ModelOpts.Template = {'SSB_Input_v2_1.inp.tpl', 'SSB_Input_v2_2.inp.tpl'};
ModelOpts.Output.Parser= 'uq_read_SSBeamDeflection';
ModelOpts.Output.FileName = 'output.out';
ModelOpts.Display = 'quiet';

% Set 'Archive.Zip'
ModelOpts.Archiving.Zip = true;

% Create a UQLink model
myModel = uq_createModel(ModelOpts);
X = [0.15 0.3 5 30000e6 1e4];

% Evaluate the UQLink model
uq_evalModel(myModel,X);

try
    % Verify if the zipped archived exists
    assert(logical(exist(...
        sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName),...
        'file')))
catch e
    delete(myModel.Internal.Runtime.Processed)
    rethrow(e)
end

% Clean up
delete(myModel.Internal.Runtime.Processed)
delete(sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName))

end


%% ------------------------------------------------------------------------
function testZipFalse()
% A test for the case that 'Archive.Zip' is assigned false.
% The zip file of the files produced during 3rd-party code executions 
% will not be created and the files remain in the directory structure.

% Set up a UQLink model
EXECBASENAME = 'uq_SimplySupportedBeam_v2';
if ispc
    EXECSUFFIX = 'win';
else
    if ismac
        EXECSUFFIX = 'mac';
    else
        EXECSUFFIX = 'linux';
    end
end
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

ModelOpts.Type = 'UQLink';
ModelOpts.Name = uq_createUniqueID();
currentDir = fileparts(mfilename('fullpath'));
ModelOpts.ExecutionPath = fullfile(currentDir,'Case2');
ModelOpts.Command = [...
    fullfile(ModelOpts.ExecutionPath,EXECNAME),...
    ' SSB_Input_v2_1.inp', ' SSB_Input_v2_2.inp'];
ModelOpts.Template = {'SSB_Input_v2_1.inp.tpl', 'SSB_Input_v2_2.inp.tpl'};
ModelOpts.Output.Parser= 'uq_read_SSBeamDeflection';
ModelOpts.Output.FileName = 'output.out';
ModelOpts.Display = 'quiet';

% Set 'Archive.Zip'
ModelOpts.Archiving.Zip = false;

% Create a UQLink model
myModel = uq_createModel(ModelOpts);
X = [0.15 0.3 5 30000e6 1e4];

% Evaluate the UQLink model
uq_evalModel(myModel,X);

try
    % Verify if the zip file does not exist
    assert(~exist(...
        sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName),...
        'file'))
    % Verify if the output file remains
    assert(logical(exist(...
        fullfile(...
        myModel.Internal.Runtime.ArchiveFolderName,...
            'UQLinkOutput',...
            'output000001.out'),...
        'file')))
    % Verify if the first input file remains
    assert(logical(exist(...
        fullfile(...
            myModel.Internal.Runtime.ArchiveFolderName,...
            'UQLinkInput',...
            'SSB_Input_v2_1000001.inp'),...
        'file')))
    % Verify if the second input file remains
    assert(logical(exist(...
        fullfile(...
            myModel.Internal.Runtime.ArchiveFolderName,...
            'UQLinkInput',...
            'SSB_Input_v2_2000001.inp'),...
        'file')))
catch e
    % Clean up
    delete(myModel.Internal.Runtime.Processed)
    rmdir(myModel.Internal.Runtime.ArchiveFolderName,'s')
    rethrow(e)
end

% Clean up
delete(myModel.Internal.Runtime.Processed)
rmdir(myModel.Internal.Runtime.ArchiveFolderName,'s')

end


%% ------------------------------------------------------------------------
function testZipInvalid()
% A test for the case that 'Archive.Zip' is assigned an invalid value.
% The zip file of the files produced during 3rd-party code executions 
% will be created.

% Set up a UQLink model
EXECBASENAME = 'uq_SimplySupportedBeam_v2';
if ispc
    EXECSUFFIX = 'win';
else
    if ismac
        EXECSUFFIX = 'mac';
    else
        EXECSUFFIX = 'linux';
    end
end
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

ModelOpts.Type = 'UQLink';
ModelOpts.Name = uq_createUniqueID();
currentDir = fileparts(mfilename('fullpath'));
ModelOpts.ExecutionPath = fullfile(currentDir,'Case2');
ModelOpts.Command = [...
    fullfile(ModelOpts.ExecutionPath,EXECNAME),...
    ' SSB_Input_v2_1.inp', ' SSB_Input_v2_2.inp'];
ModelOpts.Template = {'SSB_Input_v2_1.inp.tpl', 'SSB_Input_v2_2.inp.tpl'};
ModelOpts.Output.Parser= 'uq_read_SSBeamDeflection';
ModelOpts.Output.FileName = 'output.out';
ModelOpts.Display = 'quiet';

% Set 'Archive.Zip'
ModelOpts.Archiving.Zip = 123;  % an invalid value

% Create a UQLink model
myModel = uq_createModel(ModelOpts);

% Evaluate the UQLink model
X = [0.15 0.3 5 30000e6 1e4];
uq_evalModel(myModel,X);

try
    % Verify if the zipped archived exist
    assert(logical(exist(...
        sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName),...
        'file')))
catch e
    delete(myModel.Internal.Runtime.Processed)
    rethrow(e)
end

% Clean up
delete(myModel.Internal.Runtime.Processed)
delete(sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName))

end


%% ------------------------------------------------------------------------
function testArchiveIgnore()
% A test for the case that archiving is set to 'ignore'.
% Check that the two input files and the output file remains in the
% EXECUTION PATH.

% Set up a UQLink model
EXECBASENAME = 'uq_SimplySupportedBeam_v2';
if ispc
    EXECSUFFIX = 'win';
else
    if ismac
        EXECSUFFIX = 'mac';
    else
        EXECSUFFIX = 'linux';
    end
end
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

ModelOpts.Type = 'UQLink' ;
ModelOpts.Name = uq_createUniqueID();
currentDir = fileparts(mfilename('fullpath'));
ModelOpts.ExecutionPath = fullfile(currentDir,'Case2');
ModelOpts.Command = [...
    fullfile(ModelOpts.ExecutionPath,EXECNAME),...
    ' SSB_Input_v2_1.inp', ' SSB_Input_v2_2.inp'];
ModelOpts.Template = {'SSB_Input_v2_1.inp.tpl', 'SSB_Input_v2_2.inp.tpl'} ;
ModelOpts.Output.Parser= 'uq_read_SSBeamDeflection' ;
ModelOpts.Output.FileName = 'output.out' ;
ModelOpts.Archiving.Action = 'ignore' ;
ModelOpts.Display = 'quiet' ;

% Create a UQLink model
myModel = uq_createModel(ModelOpts) ;

% Evaluate the UQLink model
X = [0.15 0.3 5 30000e6 1e4];
uq_evalModel(myModel,X);

try
    % Verify if the zip file does not exist
    assert(~exist(...
        sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName),...
        'file'))
    % Verify if the output file remains
    assert(logical(exist(fullfile(ModelOpts.ExecutionPath,'output.out'),...
        'file')))
    % Verify if the first input file remains
    assert(logical(exist(...
        fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_1000001.inp'),...
        'file')))
    % Verify if the second input file remains
    assert(logical(exist(...
        fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_2000001.inp'),...
        'file')))
catch e
    % Clean up
    warning('off')
    delete(myModel.Internal.Runtime.Processed)
    delete(fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_1000001.inp'))
    delete(fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_2000001.inp'))
    delete(fullfile(ModelOpts.ExecutionPath,'output.out'))
    warning('on')
    rethrow(e)
end

% Clean up
delete(myModel.Internal.Runtime.Processed)
delete(fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_1000001.inp'))
delete(fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_2000001.inp'))
delete(fullfile(ModelOpts.ExecutionPath,'output.out'))

end


%% ------------------------------------------------------------------------
function testArchiveIgnoreInvalid()
% A test for the case that archiving is set to an invalid value.
% Check that the files are archived into a zip file (the default).

% Set up a UQLink model
EXECBASENAME = 'uq_SimplySupportedBeam_v2';
if ispc
    EXECSUFFIX = 'win';
else
    if ismac
        EXECSUFFIX = 'mac';
    else
        EXECSUFFIX = 'linux';
    end
end
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

ModelOpts.Type = 'UQLink';
ModelOpts.Name = uq_createUniqueID();
currentDir = fileparts(mfilename('fullpath'));
ModelOpts.ExecutionPath = fullfile(currentDir,'Case2');
ModelOpts.Command = [...
    fullfile(ModelOpts.ExecutionPath,EXECNAME),...
    ' SSB_Input_v2_1.inp', ' SSB_Input_v2_2.inp'];
ModelOpts.Template = {'SSB_Input_v2_1.inp.tpl', 'SSB_Input_v2_2.inp.tpl'};
ModelOpts.Output.Parser= 'uq_read_SSBeamDeflection';
ModelOpts.Output.FileName = 'output.out';
ModelOpts.Display = 'quiet';

% Set 'Archiving.Action'
ModelOpts.Archiving.Action = 'something';  % An invalid value

% Create a UQLink model
myModel = uq_createModel(ModelOpts);
X = [0.15 0.3 5 30000e6 1e4];

% Evaluate the UQLink model
uq_evalModel(myModel,X);

% Verify if the zipped archived exists
assert(logical(exist(...
    sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName),...
    'file')))

% Clean up
delete(myModel.Internal.Runtime.Processed)
delete(sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName))

end


%% ------------------------------------------------------------------------
function testArchiveIgnoreZipTrue()
% A test for the case that archiving is set to 'ignore' but zip is
% requested. Check that the two input files and the output file remains in
% the EXECUTION PATH.
 
% Set up a UQLink model
EXECBASENAME = 'uq_SimplySupportedBeam_v2';
if ispc
    EXECSUFFIX = 'win';
else
    if ismac
        EXECSUFFIX = 'mac';
    else
        EXECSUFFIX = 'linux';
    end
end
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

ModelOpts.Type = 'UQLink';
ModelOpts.Name = uq_createUniqueID();
currentDir = fileparts(mfilename('fullpath'));
ModelOpts.ExecutionPath = fullfile(currentDir,'Case2');
ModelOpts.Command = [...
    fullfile(ModelOpts.ExecutionPath,EXECNAME),...
    ' SSB_Input_v2_1.inp', ' SSB_Input_v2_2.inp'];
ModelOpts.Template = {'SSB_Input_v2_1.inp.tpl', 'SSB_Input_v2_2.inp.tpl'};
ModelOpts.Output.Parser= 'uq_read_SSBeamDeflection';
ModelOpts.Output.FileName = 'output.out';
ModelOpts.Display = 'quiet';

% Set 'Archiving'
ModelOpts.Archiving.Action = 'ignore'; 
ModelOpts.Archiving.Zip = true;

% Create a UQLink model
warning('off')  % Because a warning is expected
myModel = uq_createModel(ModelOpts);
warning('on')
X = [0.15 0.3 5 30000e6 1e4];

% Evaluate the UQLink model
uq_evalModel(myModel,X);

try
    % Verify if the zip file does not exist
    assert(~exist(...
        sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName),...
        'file'))
    % Verify if the output file remains
    assert(logical(exist(fullfile(ModelOpts.ExecutionPath,'output.out'),...
        'file')))
    % Verify if the first input file remains
    assert(logical(exist(...
        fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_1000001.inp'),...
        'file')))
    % Verify if the second input file remains
    assert(logical(exist(...
        fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_2000001.inp'),...
        'file')))
catch e
    % Clean up
    warning('off')
    delete(myModel.Internal.Runtime.Processed)
    delete(fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_1000001.inp'))
    delete(fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_2000001.inp'))
    delete(fullfile(ModelOpts.ExecutionPath,'output.out'))
    warning('on')
    rethrow(e)
end

% Clean up
delete(myModel.Internal.Runtime.Processed)
delete(fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_1000001.inp'))
delete(fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_2000001.inp'))
delete(fullfile(ModelOpts.ExecutionPath,'output.out'))

end


%% ------------------------------------------------------------------------
function testArchiveDelete()
% A test for the case that archiving is set to 'delete'.

% Set up a UQLink model
EXECBASENAME = 'uq_SimplySupportedBeam_v2';
if ispc
    EXECSUFFIX = 'win';
else
    if ismac
        EXECSUFFIX = 'mac';
    else
        EXECSUFFIX = 'linux';
    end
end
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

ModelOpts.Type = 'UQLink';
ModelOpts.Name = uq_createUniqueID();
currentDir = fileparts(mfilename('fullpath'));
ModelOpts.ExecutionPath = fullfile(currentDir,'Case2');
ModelOpts.Command = [...
    fullfile(ModelOpts.ExecutionPath,EXECNAME),...
    ' SSB_Input_v2_1.inp', ' SSB_Input_v2_2.inp'];
ModelOpts.Template = {'SSB_Input_v2_1.inp.tpl', 'SSB_Input_v2_2.inp.tpl'};
ModelOpts.Output.Parser= 'uq_read_SSBeamDeflection';
ModelOpts.Output.FileName = 'output.out';
ModelOpts.Display = 'quiet';

% Set 'Archiving.Action'
ModelOpts.Archiving.Action = 'delete';

% Create a UQLink model
myModel = uq_createModel(ModelOpts);

% Evaluate the UQLink model
X = [0.15 0.3 5 30000e6 1e4];
uq_evalModel(myModel,X);

try
    % Verify if the zip file does not exist
    assert(~exist(...
        sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName),...
        'file'))
    % Verify if the output file remains
    assert(logical(~exist(fullfile(ModelOpts.ExecutionPath,'output.out'),...
        'file')))
    % Verify if the first input file remains
    assert(logical(~exist(...
        fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_1000001.inp'),...
        'file')))
    % Verify if the second input file remains
    assert(logical(~exist(...
        fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_2000001.inp'),...
        'file')))
catch e
    % Clean up
    warning('off')
    delete(myModel.Internal.Runtime.Processed)
    delete(fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_1000001.inp'))
    delete(fullfile(ModelOpts.ExecutionPath,'SSB_Input_v2_2000001.inp'))
    delete(fullfile(ModelOpts.ExecutionPath,'output.out'))
    warning('on')
    rethrow(e)
end

% Clean up
delete(myModel.Internal.Runtime.Processed)

end
