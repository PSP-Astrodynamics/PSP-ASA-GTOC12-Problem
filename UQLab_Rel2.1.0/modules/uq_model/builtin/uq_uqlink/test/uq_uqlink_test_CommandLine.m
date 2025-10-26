function pass = uq_uqlink_test_CommandLine( level )
% UQ_UQLINK_TEST_COMMANDLINE tests the robustness of the command line when
% there is a space somewhere in the path to the executable

% See also: UQ_READ_SSBEAMDEFLECTION.m UQ_SIMPLYSUPPORTEDBEAM.CPP

% parameters
pass = true ;
eps_th = 1e-5 ;
% X = [b h L E p]; Y = V = beam deflection
X = [0.15 0.3 5 30000e6 1e4;
     0.15 0.3 5 30000e6 1e4] ;
 
Ytrue = 5 * X(:,5) .* X(:,3).^4 ./ (32 * X(:,4) .* X(:,1) .* X(:,2).^3) ;

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_uqlink_test_CommandLine...\n']);

uqlab('-nosplash')

%% CASE 1 : FOLDER CONTAINS SPACE 
%% ##### NOTE THAT THE EXECUTABLE FOR THIS CASE IS IN THE EXAMPLE FOLDER ###### %%
%% Executable name depends on architecture
EXECBASENAME = 'myBeam';
if ispc
    EXECSUFFIX = 'win';
elseif isunix
    if ~ismac
        EXECSUFFIX = 'linux';
    else
        EXECSUFFIX = 'mac';
    end
end
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

%% CREATE A FOLDER CONTAINING SPACE IN THE NAME TO TEST THE FEATURE OF AUTOMATICALLY DETECTING EXECTUABLES IN COMMAND LINE
% Directory where is located the executables and template for the test
sourcedir = fullfile(uq_rootPath,'Examples','UQLink','C_SimplySupportedBeam') ;
% Set the test folder of uq_uqlink module as parent folder
ParentFolder = fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test') ;
% Now create a folder named 'my Folder' (with space) in the parent folder
mkdir(fullfile(ParentFolder,'my Folder')) ;
% Copy all the necessary files: The three exectuables + the template
copyfile(fullfile(sourcedir,'myBeam_*'), fullfile(ParentFolder,'my Folder') ) ;
copyfile(fullfile(sourcedir,'SSBeam_Deflection.inp.tpl'), fullfile(ParentFolder,'my Folder') ) ;

% Now create the UQLink object
Mopts.Type = 'UQLink' ; 
Mopts.Name = 'Beam CLI 1' ;
Mopts.Command = [fullfile(ParentFolder, 'my Folder', EXECNAME), ' SSB_Input.inp'] ;
Mopts.ExecutionPath = fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test') ;
Mopts.Template = 'SSB_Input.inp.tpl' ;
Mopts.Output.Parser= 'uq_read_SSBeamDeflection' ;
Mopts.Output.FileName = 'SSB_Input.out' ;
Mopts.Archiving.Action = 'delete' ;
Mopts.Display = 'quiet' ;

myModel = uq_createModel(Mopts) ;
Yval = uq_evalModel(myModel,X);
% Delete the .mat file that is created to save the results
delete(myModel.Internal.Runtime.Processed) ;
% pass ?
pass = pass && max(abs(Ytrue-Yval))< eps_th;

%% CASE 2 : FOLDER CONTAINS SPACE BUT USER ENCAPSULES THE COMMAND WITH DOUBLE QUOTES: Nothing should be done 
% Modify the command by adding double qoutes as delimiter
DELIM = '"' ;
Mopts.Command = [DELIM, fullfile(ParentFolder, 'my Folder', EXECNAME), DELIM, ' SSB_Input.inp'] ;
% Update the name as well
Mopts.Name = 'Beam CLI 2' ;

% Create a new UQLink object and 
myModel = uq_createModel(Mopts) ;
Yval = uq_evalModel(myModel,X);

% Delete the .mat file that is created to save the results
delete(myModel.Internal.Runtime.Processed) ;
% pass ?
pass = pass && max(abs(Ytrue-Yval))< eps_th;

%% DELETE THE NEWLY CREATED FOLDER AND ITS CONTENT
% Let's be carefull here... Deleting the new created folder and all its
% content
rmdir(fullfile(ParentFolder, 'my Folder'), 's')
end
