% UQ_SVCOPTIONS displays a helper for the main options needed to
% create a SVC metamodel in UQLab
%    UQ_SVCOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createModel">uq_createModel</a> to create a SVC metamodel in UQLab 
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectModel 

disp('Quickstart guide to the UQLab SVC Module')
disp('  ')
disp('In the UQLab software, SVC MODEL objects are created by the command:')
disp('    mySVC = uq_createModel(SVCOPTIONS)')
disp('The options are specified in the SVCOPTIONS structure.')
disp(' ')
disp('Example: to create a SVC metamodel from given X and Y, type:')
disp('    SVCOPTIONS.Type = ''Metamodel'';')
disp('    SVCOPTIONS.MetaType = ''SVC'';')
disp('    SVCOPTIONS.ExpDesign.X = X;')
disp('    SVCOPTIONS.ExpDesign.Y = Y;')
disp('    mySVC = uq_createModel(SVCOPTIONS);')
disp(' ')
disp('To evaluate the SVC metamodel on a new set of inputs Xval, type:')
disp('    Yval = uq_evalModel(Xval);')
disp(' ')
disp('The following options are set by default if not specified by the user:')
disp(' ')
disp('    SVCOPTIONS.Kernel.Family = ''Gaussian'';');
disp('    SVCOPTIONS.Kernel.Isotropic = true;');
disp('    SVCOPTIONS.Penalization = ''linear'';') ;
disp('    SVCOPTIONS.QPSolver = ''IP'';  % (if size(X,1) > 300, ''SMO'')') ;
disp('    SVCOPTIONS.EstimMethod = ''SpanLOO'';');
disp('    SVCOPTIONS.Optim.Method = ''CMAES'';');
disp('    SVCOPTIONS.Optim.MaxIter = 10;');
disp('    SVCOPTIONS.Optim.Tol = 1e-2;');
disp('    SVCOPTIONS.Optim.Display = ''None'';');
disp('    SVCOPTIONS.Scaling = 1;');
disp(' ')
disp('Please refer to the Support Vector Machines for Classification User Manual (<a href="matlab:uq_doc(''SVC'',''html'')">HTML</a>,<a href="matlab:uq_doc(''SVC'',''pdf'')">PDF</a>) ');
disp('for more detailed information on the available features.');
disp(' ')
disp(' ')

% 