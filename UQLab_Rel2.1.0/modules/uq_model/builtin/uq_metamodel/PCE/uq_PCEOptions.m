% UQ_PCEOPTIONS display a helper for the main options needed to create a
%               Polynomial Chaos Expansion metamodel in UQLab.
%    UQ_PCEOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createModel">uq_createModel</a> to create a PCE MODEL object in UQLab 
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectModel 

disp('Quickstart guide to the UQLab PCE Module')
disp('  ')
fprintf('In the UQLab software, PCE MODEL objects are created by the command:\n')
fprintf('    myPCE = uq_createModel(PCEOPTIONS)\n');
fprintf('The options are specified in the PCEOPTIONS structure.\n')  

fprintf('\nExample: to create a PCE metamodel of degree 3 with an experimental\n')
fprintf('design of size 100 from the current INPUT and MODEL objects:\n')
fprintf('    PCEOPTIONS.Type = ''Metamodel'';\n')
fprintf('    PCEOPTIONS.MetaType = ''PCE'';\n')
fprintf('    PCEOPTIONS.Degree = 3;\n')
fprintf('    PCEOPTIONS.ExpDesign.NSamples = 100;\n')
fprintf('    myPCE = uq_createModel(PCEOPTIONS);\n')

fprintf('\nTo evaluate the PCE metamodel on a new set of inputs Xval, type:\n')
fprintf('    Yval = uq_evalModel(Xval);\n')

fprintf('\nThe following options are set by default if not specified by the user:\n\n')
fprintf('    PCEOPTIONS.Method = ''LARS''\n');
fprintf('    PCEOPTIONS.Degree = 1:3\n');
fprintf('    PCEOPTIONS.Input = uq_getInput()\n');
fprintf('    PCEOPTIONS.FullModel = uq_getModel()\n');
fprintf('    PCEOPTIONS.ExpDesign.Sampling = ''LHS''\n');
fprintf('    PCEOPTIONS.LARS.LarsEarlyStop = true\n');
fprintf('    PCEOPTIONS.LARS.HybridLars = true\n');
fprintf('    PCEOPTIONS.TruncOptions.qNorm = 1\n');
fprintf('    PCEOPTIONS.TruncOptions.MaxInteraction = M\n');
fprintf('\n');
fprintf('Please refer to the Polynomial Chaos Expansions User Manual (<a href="matlab:uq_doc(''PCE'',''html'')">HTML</a>,<a href="matlab:uq_doc(''PCE'',''pdf'')">PDF</a>)');
fprintf('\nfor more detailed information on the available features.')
fprintf('\n\n')