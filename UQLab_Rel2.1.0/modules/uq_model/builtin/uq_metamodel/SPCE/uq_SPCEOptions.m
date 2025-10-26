% UQ_SPCEOPTIONS display a helper for the main options needed to create a
%               Polynomial Chaos Expansion metamodel in UQLab.
%    UQ_SPCEOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createModel">uq_createModel</a> to create a SPCE MODEL object in UQLab 
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectModel 

disp('Quickstart guide to the UQLab SPCE Module')
disp('  ')
fprintf('In the UQLab software, SPCE MODEL objects are created by the command:\n')
fprintf('    mySPCE = uq_createModel(SPCEOPTIONS)\n');
fprintf('The options are specified in the SPCEOPTIONS structure.\n')  

fprintf('\nExample: to create a SPCE metamodel with an experimental\n')
fprintf('design of size 100 (with 15 replications) from the current INPUT and MODEL objects:\n')
fprintf('    SPCEOPTIONS.Type = ''Metamodel'';\n')
fprintf('    SPCEOPTIONS.MetaType = ''SPCE'';\n')
fprintf('    SPCEOPTIONS.ExpDesign.NSamples = 100;\n')
fprintf('    SPCEOPTIONS.ExpDesign.Replications = 15;\n')
fprintf('    mySPCE = uq_createModel(SPCEOPTIONS);\n')

fprintf('\nTo evaluate the SPCE metamodel on a new set of inputs Xval, type:\n')
fprintf('    Yval = uq_evalModel(Xval);\n')

fprintf('\nThe following options are set by default if not specified by the user:\n\n')
fprintf('    SPCEOPTIONS.Degree = 1:5\n');
fprintf('    SPCEOPTIONS.Input = uq_getInput()\n');
fprintf('    SPCEOPTIONS.FullModel = uq_getModel()\n');
fprintf('    SPCEOPTIONS.ExpDesign.Sampling = ''LHS''\n');
fprintf('    SPCEOPTIONS.TruncOptions.qNorm = 1\n');
fprintf('    SPCEOPTIONS.TruncOptions.MaxInteraction = M\n');
fprintf('    SPCEOPTIONS.IntMethod = ''Quadrature''\n');
fprintf('\n');
fprintf('Please refer to the Stochastic Polynomial Chaos Expansions User Manual (<a href="matlab:uq_doc(''SPCE'',''html'')">HTML</a>,<a href="matlab:uq_doc(''SPCE'',''pdf'')">PDF</a>)');
fprintf('\nfor more detailed information on the available features.')
fprintf('\n\n')