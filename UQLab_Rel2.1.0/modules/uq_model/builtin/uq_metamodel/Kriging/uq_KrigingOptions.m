%UQ_KRIGINGOPTIONS displays a helper for the main options needed to create
% a Kriging metamodel in UQLab.
%
%   UQ_KRIGINGOPTIONS displays the main options needed by the command
%   <a href="matlab:help uq_createModel">uq_createModel</a> to create a Kriging metamodel in UQLab.
%
%   See also uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%   uq_selectModel.

disp('Quickstart guide to the UQLab Kriging Module')
disp('  ')
disp('In the UQLab software, Kriging MODEL objects are created by the command:')
disp('    myKriging = uq_createModel(KRIGINGOPTIONS)')
disp('The options are specified in the KRIGINGOPTIONS structure.')
disp(' ')
disp('Example: to create a Kriging metamodel from given X and Y, type:')
disp('    KRIGINGOPTIONS.Type = ''Metamodel'';')
disp('    KRIGINGOPTIONS.MetaType = ''Kriging'';')
disp('    KRIGINGOPTIONS.ExpDesign.X = X;')
disp('    KRIGINGOPTIONS.ExpDesign.Y = Y;')
disp('    myKriging = uq_createModel(KRIGINGOPTIONS);')
disp(' ')
disp('To create a Kriging metamodel for regression with an unknown noise, also add:')
disp('    KRIGINGOPTIONS.Regression.EstimNoise = true;')
disp(' ')
disp('If the noise variance sigmaNSQ is known, add instead:')
disp('    KRIGINGOPTIONS.Regression.EstimNoise = false;')
disp('    KRIGINGOPTIONS.Regression.SigmaNSQ = sigmaNSQ;')
disp(' ')
disp('To evaluate the Kriging metamodel on a new set of inputs Xval:')
disp('    Yval = uq_evalModel(Xval);')
disp(' ')
disp('The following options are set by default if not specified by the user:')
disp(' ')
disp('    KRIGINGOPTIONS.Corr.Family = ''Matern-5_2''');
disp('    KRIGINGOPTIONS.Corr.Type = ''Ellipsoidal''');
disp('    KRIGINGOPTIONS.Corr.Isotropic = false');
disp('    KRIGINGOPTIONS.Corr.Nugget = 1e-10');
disp('    KRIGINGOPTIONS.Trend.Type = ''Ordinary''')
disp('    KRIGINGOPTIONS.EstimMethod = ''CV''');
disp('    KRIGINGOPTIONS.Optim.Method = ''HGA''');
disp('    KRIGINGOPTIONS.Optim.Bounds = [1e-3; 10]');
disp('    KRIGINGOPTIONS.Optim.MaxIter = 20');
disp('    KRIGINGOPTIONS.Optim.Tol = 1e-4');
disp('    KRIGINGOPTIONS.Optim.Display = ''None''');
disp('    KRIGINGOPTIONS.Optim.HGA.nLM = 5');
disp('    KRIGINGOPTIONS.Optim.HGA.nPop = 30');
disp('    KRIGINGOPTIONS.Optim.HGA.nStall = 2');
disp('    KRIGINGOPTIONS.Scaling = true');
disp(' ')
disp(['Please refer to the Kriging User Manual ',...
    '(<a href="matlab:uq_doc(''Kriging'',''html'')">HTML</a>,',...
    '<a href="matlab:uq_doc(''Kriging'',''pdf'')">PDF</a>)',...
    'for detailed']);
disp('information on the available features.');
disp(' ')
disp(' ')
