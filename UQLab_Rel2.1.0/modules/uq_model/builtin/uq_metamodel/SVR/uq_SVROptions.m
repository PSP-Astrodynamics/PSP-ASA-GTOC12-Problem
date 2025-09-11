% UQ_SVROPTIONS displays a helper for the main options needed to
% create a SVR metamodel in UQLab
%    UQ_SVROPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createModel">uq_createModel</a> to create a SVR metamodel in UQLab 
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectModel 

disp('Quickstart guide to the UQLab SVR Module')
disp('  ')
disp('In the UQLab software, SVR MODEL objects are created by the command:')
disp('    mySVR = uq_createModel(SVROPTIONS)')
disp('The options are specified in the SVROPTIONS structure.')
disp(' ')
disp('Example: to create a SVR metamodel from given X and Y, type:')
disp('    SVROPTIONS.Type = ''Metamodel'';')
disp('    SVROPTIONS.MetaType = ''SVR'';')
disp('    SVROPTIONS.ExpDesign.X = X;')
disp('    SVROPTIONS.ExpDesign.Y = Y;')
disp('    mySVR = uq_createModel(SVROPTIONS);')
disp(' ')
disp('To evaluate the SVR metamodel on a new set of inputs Xval, type:')
disp('    Yval = uq_evalModel(Xval);')
disp(' ')
disp('The following options are set by default if not specified by the user:')
disp(' ')
disp('    SVROPTIONS.Kernel.Family = ''Gaussian'';');
disp('    SVROPTIONS.Kernel.Isotropic = true;');
disp('    SVROPTIONS.Loss = ''l1-eps'';') ;
disp('    SVROPTIONS.QPSolver = ''IP''; % (if size(X,1) > 300, ''SMO'')') ;
disp('    SVROPTIONS.EstimMethod = ''SpanLOO'';');
disp('    SVROPTIONS.Optim.Method = ''CMAES'';');
disp('    SVROPTIONS.Optim.MaxIter = 10;');
disp('    SVROPTIONS.Optim.Tol = 1e-3;');
disp('    SVROPTIONS.Optim.Display = ''None'';');
disp('    SVROPTIONS.Scaling = true;');
disp('    SVROPTIONS.OutputScaling = true;');
disp(' ')
disp('Please refer to the Support Vector Machines for Regression User Manual (<a href="matlab:uq_doc(''SVR'',''html'')">HTML</a>,<a href="matlab:uq_doc(''SVR'',''pdf'')">PDF</a>) ');
disp('for more detailed information on the available features.');
disp(' ')
disp(' ')

