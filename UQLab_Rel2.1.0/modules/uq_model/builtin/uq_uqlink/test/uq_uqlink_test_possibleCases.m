function pass = uq_uqlink_test_possibleCases( level )
% UQ_UQLINK_TEST_POSSIBLECASES tests representative of possible third-party
% softwares
%
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
fprintf(['\nRunning: |' level '| uq_uqlink_test_possibleCases...\n']);

uqlab('-nosplash')

%% CASE 1 : typical model with only one input file -
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


% Case presented in the user manual:
% One input file contains all the parameters
% Command line is myBeam input.inp
Mopts.Type = 'UQLink' ; 
Mopts.Name = 'Beam Basic Case' ;
Mopts.Command = [fullfile(uq_rootPath,'Examples','UQLink','C_SimplySupportedBeam', EXECNAME), ' SSB_Input.inp'] ;
Mopts.ExecutionPath = fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test') ;
Mopts.Template = 'SSB_Input.inp.tpl' ;
Mopts.Output.Parser= 'uq_read_SSBeamDeflection' ;
Mopts.Output.FileName = 'SSB_Input.out' ;
Mopts.Archiving.Action = 'delete' ;
Mopts.Display = 'quiet' ;

myModel = uq_createModel(Mopts) ;
Yval = uq_evalModel(myModel,X);
delete(myModel.Internal.Runtime.Processed) ;
pass = pass && max(abs(Ytrue-Yval))< eps_th;

%% CASE 2: Executable takes two input files - The output file name is not written in the input file or executable command.
% If matlab does not find the output name with the numeric counter the
% output name given by the user is assumed. In this case, the output file
% is always output.out regardless of the input file name and uqlink cannot
% change that
% Input file 1: 
EXECBASENAME = 'uq_SimplySupportedBeam_v2';
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

clear Mopts ;
Mopts.Type = 'UQLink' ; 
Mopts.Name = 'Beam_v2' ;
Mopts.Command = [fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test','Case2', EXECNAME), ' SSB_Input_v2_1.inp', ' SSB_Input_v2_2.inp'] ;    
Mopts.ExecutionPath = fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test','Case2') ;
Mopts.Template = {'SSB_Input_v2_1.inp.tpl', 'SSB_Input_v2_2.inp.tpl'} ;
Mopts.Output.Parser= 'uq_read_SSBeamDeflection' ;
Mopts.Output.FileName = 'output.out' ;
Mopts.Archiving.Action = 'delete' ;
Mopts.Display = 'quiet' ;

myModel = uq_createModel(Mopts) ;
Yval = uq_evalModel(myModel,X);
delete(myModel.Internal.Runtime.Processed) ;
pass = pass && max(abs(Ytrue-Yval))< eps_th;

%% CASE 3: Executable takes one argument only: the input file. 
% The output name is written in the in the input file
EXECBASENAME = 'uq_SimplySupportedBeam_v3';
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];

clear Mopts ;
Mopts.Type = 'UQLink' ; 
Mopts.Name = 'Beam_v3' ;
Mopts.Command = [fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test','Case3', EXECNAME), ' SSB_Input_v3.inp'] ;    
Mopts.ExecutionPath = fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test','Case3') ;
Mopts.Template = {'SSB_Input_v3.inp.tpl'} ;
Mopts.Output.Parser= 'uq_read_SSBeamDeflection' ;
Mopts.Output.FileName = 'output.out' ;
Mopts.Archiving.Action = 'delete' ;
Mopts.Display = 'quiet' ;

myModel = uq_createModel(Mopts) ;
Yval = uq_evalModel(myModel,X);
delete(myModel.Internal.Runtime.Processed) ;
pass = pass && max(abs(Ytrue-Yval))< eps_th;

%% CASE 4: Executable takes two arguments: the input AND output files
EXECBASENAME = 'uq_SimplySupportedBeam_v4';
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];
clear Mopts ;
Mopts.Type = 'UQLink' ; 
Mopts.Name = 'Beam_v4' ;
Mopts.Command = [fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test','Case4',EXECNAME), ' SSB_Input_v4.inp',  ' output.out'] ;    
Mopts.ExecutionPath = fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test','Case4') ;
Mopts.Template = {'SSB_Input_v4.inp.tpl'} ;
Mopts.Output.Parser= 'uq_read_SSBeamDeflection' ;
Mopts.Output.FileName = 'output.out' ;
Mopts.Archiving.Action = 'delete' ;
Mopts.Display = 'quiet' ;

myModel = uq_createModel(Mopts) ;
Yval = uq_evalModel(myModel,X);
delete(myModel.Internal.Runtime.Processed) ;
pass = pass && max(abs(Ytrue-Yval))< eps_th;

%% CASE 5: Case 1 but this time the executable path is not written in the command line
EXECBASENAME = 'myBeam';
EXECNAME = [EXECBASENAME '_' EXECSUFFIX];
clear Mopts ;
Mopts.Type = 'UQLink' ; 
Mopts.Name = 'Beam Test Executable Option' ;
Mopts.Command = [EXECNAME ' SSB_Input.inp'] ;    
Mopts.ExecutablePath = fullfile(uq_rootPath,'Examples','UQLink','C_SimplySupportedBeam') ;
Mopts.ExecutionPath = fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test') ;
Mopts.Template = 'SSB_Input.inp.tpl' ;
Mopts.Output.Parser= 'uq_read_SSBeamDeflection' ;
Mopts.Output.FileName = 'SSB_Input.out' ;
Mopts.Archiving.Action = 'delete' ;
Mopts.Display = 'quiet' ;

myModel = uq_createModel(Mopts) ;
Yval = uq_evalModel(myModel,X);
delete(myModel.Internal.Runtime.Processed) ;
pass = max(abs(Ytrue-Yval))< eps_th;
end
