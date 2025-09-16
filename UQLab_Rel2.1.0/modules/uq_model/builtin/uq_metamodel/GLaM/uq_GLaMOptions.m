% UQ_GLAMOPTIONS display a helper for the main options needed to create a
%               Polynomial Chaos Expansion metamodel in UQLab.
%    UQ_GLAMOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createModel">uq_createModel</a> to create a GLaM MODEL object in UQLab 
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectModel 

disp('Quickstart guide to the UQLab GLaM Module')
disp('  ')
fprintf('In the UQLab software, GLaM MODEL objects are created by the command:\n')
fprintf('    myGLaM = uq_createModel(GLAMOPTIONS)\n');
fprintf('The options are specified in the GLAMOPTIONS structure.\n')  

fprintf('\nExample: to create a GLaM metamodel with an experimental\n')
fprintf('design of size 100 (with 15 replications) from the current INPUT and MODEL objects:\n')
fprintf('    GLAMOPTIONS.Type = ''Metamodel'';\n')
fprintf('    GLAMOPTIONS.MetaType = ''GLaM'';\n')
fprintf('    GLAMOPTIONS.ExpDesign.NSamples = 100;\n')
fprintf('    GLAMOPTIONS.ExpDesign.Replications = 15;\n')
fprintf('    myGLaM = uq_createModel(GLAMOPTIONS);\n')

fprintf('\nTo evaluate the GLaM metamodel on a new set of inputs Xval, type:\n')
fprintf('    Yval = uq_evalModel(Xval);\n')

fprintf('\nThe following options are set by default if not specified by the user:\n\n')
fprintf('    GLAMOPTIONS.MeanReg.Method = ''LARS''\n');
fprintf('    GLAMOPTIONS.MeanReg.updateBasis = false\n');
fprintf('    GLAMOPTIONS.Input = uq_getInput()\n');
fprintf('    GLAMOPTIONS.FullModel = uq_getModel()\n');
fprintf('    GLAMOPTIONS.ExpDesign.Sampling = ''LHS''\n');
fprintf('\n');
fprintf('Please refer to the Generalized Lambda Models User Manual (<a href="matlab:uq_doc(''GLaM'',''html'')">HTML</a>,<a href="matlab:uq_doc(''GLaM'',''pdf'')">PDF</a>)');
fprintf('\nfor more detailed information on the available features.')
fprintf('\n\n')