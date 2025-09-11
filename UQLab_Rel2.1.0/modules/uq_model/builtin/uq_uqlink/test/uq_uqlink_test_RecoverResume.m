function pass = uq_uqlink_test_RecoverResume( level )
% UQ_UQLINK_TEST_RECOVERRESUME tests the 'recover' and 'resume' options of
% the uq_evalModel for uqlink objects
%
% See also: UQ_READ_SSBEAMDEFLECTION.m UQ_UQLINK_TEST_POSSIBLECASES.m

% parameters
pass = true ;
eps_th = 1e-5 ;
% X = [b h L E p]; Y = V = beam deflection
X = [0.15 0.3 5 30000e6 1e4;
     0.15 0.3 5 30000e6 1e4;
     0.15 0.3 5 30000e6 1e4] ;
 
Ytrue = 5 * X(:,5) .* X(:,3).^4 ./ (32 * X(:,4) .* X(:,1) .* X(:,2).^3) ;

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_uqlink_test_RecoverResume...\n']);

uqlab('-nosplash')

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

%% 
Mopts.Type = 'UQLink' ;
Mopts.Name = 'my Beam' ;
Mopts.Command = [fullfile(uq_rootPath,'Examples','UQLink','C_SimplySupportedBeam', EXECNAME), ' SSB_Input.inp'] ;    
Mopts.ExecutionPath = fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test') ;
Mopts.Template = 'SSB_Input.inp.tpl' ;
Mopts.Output.Parser= 'uq_read_SSBeamDeflection' ;
Mopts.Output.FileName = 'SSB_Input.out' ;
Mopts.Display = 'quiet' ;

myModel = uq_createModel(Mopts) ;
Yval = uq_evalModel(myModel,X);

%% CASE 1: One of the output is NaN: It is found automatically and run again
% Load Processed input/output and modify them
load(myModel.Internal.Runtime.Processed, 'uq_ProcessedY') ;
% Put the second output to NaN
uq_ProcessedY(2,:) = NaN ;
%Save back the modified input
save(myModel.Internal.Runtime.Processed, 'uq_ProcessedY', '-append')  ;

%Now do again a run
Yval = uq_evalModel(myModel, X, 'recover') ;
load(myModel.Internal.Runtime.Processed, 'uq_ProcessedY' );
if isnan(uq_ProcessedY(2,:))
    pass = false ;
end
pass = pass && max(abs(Ytrue-Yval))< eps_th;

%% CASE 2: The user gives a list of run to re-do
% Load Processed input/output and modify them
load(myModel.Internal.Runtime.Processed,'uq_ProcessedY') ;
% Put the second output to NaN
uq_ProcessedY(2,:) = NaN ;
%Save back the modified input
save(myModel.Internal.Runtime.Processed, 'uq_ProcessedY','-append') ;

Yval = uq_evalModel(myModel, X, 'recover', 2) ;

load(myModel.Internal.Runtime.Processed, 'uq_ProcessedY') ;
if isnan(uq_ProcessedY(2,:))
    pass = false ;
end
pass = pass && max(abs(Ytrue-Yval))< eps_th;
%% CASE 3: Resume option. X has three inputs but uq_ProcessedX and _Y only have two inputs. UQLink should run only the third option.
% Load Processed input/output and modify them
load(myModel.Internal.Runtime.Processed, 'uq_ProcessedX', 'uq_ProcessedY') ;
% Remove the third output to pretend that it is not 
uq_ProcessedX =  uq_ProcessedX(1:2,:) ;
uq_ProcessedY =  uq_ProcessedY(1:2,:) ;
%Save back the modified input
save(myModel.Internal.Runtime.Processed, 'uq_ProcessedX', 'uq_ProcessedY','-append') ;

Yval = uq_evalModel(myModel, X, 'resume') ;

load(myModel.Internal.Runtime.Processed, 'uq_ProcessedX', 'uq_ProcessedY') ;
if size(uq_ProcessedX,1) ~= 3 || size(uq_ProcessedY,1) ~= 3
    pass = false ;
end
pass = pass && max(abs(Ytrue-Yval))< eps_th;


%% CASE 4: Just make sure that uq_AllX = X
try
    load(myModel.Internal.Runtime.Processed, 'uq_AllX') ;
    pass = pass && all(all(uq_AllX == X)) ;
catch
    % Couldn't load uq_AllX. This means there was an erro somewhere
    pass = false ;
end

%% Delete the .mat and .zip
try
delete(myModel.Internal.Runtime.Processed) ;
delete(sprintf('%s.zip',myModel.Internal.Runtime.ArchiveFolderName) );
catch
    % Could not delete the .mat and the .zop. This means there was an error
    % in the archiving
    pass = false ;
end

end
