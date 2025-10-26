% UQ_LRAOPTIONS display a helper for the main options needed to create a
%               Canonical Low-Rank Approximation metamodel in UQLab.
%    UQ_LRAOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createModel">uq_createModel</a> to create a LRA MODEL object in UQLab 
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectModel 

disp('Quickstart guide to the UQLab LRA Module')
disp('  ')
fprintf('In the UQLab software, LRA MODEL objects are created by the command:\n')
fprintf('    myLRA = uq_createModel(LRAOPTIONS)\n');
fprintf('The options are specified in the LRAOPTIONS structure.\n')  

fprintf('\nExample: to create a LRA of rank 3 with polynomials of maximum degree 5\n')  
fprintf('with an experimental design of size 100 from the current INPUT and MODEL objects, type:\n\n')  
fprintf('    LRAOPTIONS.Type = ''Metamodel'';\n')  
fprintf('    LRAOPTIONS.MetaType = ''LRA'';\n')  
fprintf('    LRAOPTIONS.Rank = 3;\n')  
fprintf('    LRAOPTIONS.Degree = 5;\n')  
fprintf('    LRAOPTIONS.ExpDesign.NSamples = 100;\n')  
fprintf('    myLRA = uq_createModel(LRAOPTIONS);\n')  

fprintf('\nTo evaluate the LRA metamodel on a new set of inputs Xval, type:\n\n')  
fprintf('    Yval = uq_evalModel(Xval);\n')  

fprintf('\nThe following options are set by default if not specified by the user:\n\n')
fprintf('    LRAOptions.ExpDesign.Sampling = ''LHS''\n');
fprintf('    LRAOptions.CorrStep.Adaptivity = ''all_d_adapt_r''\n')
fprintf('    LRAOptions.CorrStep.MaxIterStop = 100\n')
fprintf('    LRAOptions.CorrStep.MinDerrStop = 1e-6\n')
fprintf('    LRAOptions.CorrStep.Method = ''OLS''\n')
fprintf('    LRAOptions.UpdateStep.Method = ''OLS''\n')
fprintf('    LRAOptions.GenError.Parameters.NFolds = 3\n')
fprintf('    LRAOptions.RankSelection.EarlyStop = 0\n')
fprintf('    LRAOptions.RankSelection.EarlyStopSteps = 2\n')
fprintf('    LRAOptions.DegSelection.EarlyStop = 0\n')
fprintf('    LRAOptions.DegSelection.EarlyStopSteps = 2\n')
fprintf('\n');
fprintf('Please refer to the Canonical Low Rank Approximations User Manual (<a href="matlab:uq_doc(''LRA'',''html'')">HTML</a>,<a href="matlab:uq_doc(''LRA'',''pdf'')">PDF</a>)');
fprintf('\nfor more detailed information on the available features.')
fprintf('\n\n')