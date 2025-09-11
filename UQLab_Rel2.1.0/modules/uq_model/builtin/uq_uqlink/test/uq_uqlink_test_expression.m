function pass = uq_uqlink_test_expression( level )
% UQ_UQLINK_TEST_EPXRESSION tests the use of expressions in the input file
%
% See also: UQ_READ_SSBEAMDEFLECTION.m UQ_SIMPLYSUPPORTEDBEAM.CPP

% parameters
pass = true ;
eps_th = 1e-5 ;
% X = [b h L E p1 p2]; Y = V = beam deflection
X = [0.15 0.3 5 30000e6 5e3 1e3;
     0.15 0.3 5 30000e6 5e3 1e3] ;
 
Ytrue = 5 * (X(:,5) + 5.*X(:,6)) .* X(:,3).^4 ./ (32 * X(:,4) .* X(:,1) .* X(:,2).^3) ;

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_uqlink_test_expression...\n']);

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
Mopts.Name = 'Beam  Expr' ;
Mopts.Command = [fullfile(uq_rootPath,'Examples','UQLink','C_SimplySupportedBeam', EXECNAME), ' SSB_Input_expr.inp'] ;
Mopts.ExecutionPath = fullfile(uq_rootPath,'modules','uq_model','builtin','uq_uqlink','test') ;
Mopts.Template = 'SSB_Input_expr.inp.tpl' ;
Mopts.Output.Parser= 'uq_read_SSBeamDeflection' ;
Mopts.Output.FileName = 'SSB_Input_expr.out' ;
Mopts.Archiving.Action = 'delete' ;
Mopts.Display = 'quiet' ;

myModel = uq_createModel(Mopts) ;
Yval = uq_evalModel(myModel,X);
delete(myModel.Internal.Runtime.Processed) ;
pass = pass && max(abs(Ytrue-Yval))< eps_th;


end
