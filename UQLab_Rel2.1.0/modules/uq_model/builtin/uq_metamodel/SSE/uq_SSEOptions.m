% UQ_SSEOPTIONS display a helper for the main options needed to create a
%               Stochastic spectral embedding metamodel in UQLab.
%    UQ_SSEOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createModel">uq_createModel</a> to create an SSE MODEL object in UQLab 
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectModel 

disp('Quickstart guide to the UQLab SSE Module')
disp('  ')
fprintf('In the UQLab software, SSE MODEL objects are created by the command:\n')
fprintf('    mySSE = uq_createModel(SSEOPTIONS)\n');
fprintf('The options are specified in the SSEOPTIONS structure.\n')  

fprintf('\nExample: to create an SSE metamodel of degree 3 with an experimental\n')
fprintf('design of size 100 from the current INPUT and MODEL objects:\n')
fprintf('    SSEOPTIONS.Type = ''Metamodel'';\n')
fprintf('    SSEOPTIONS.MetaType = ''SSE'';\n')
fprintf('    SSEOPTIONS.ExpDesign.NSamples = 100;\n')
fprintf('    mySSE = uq_createModel(SSEOPTIONS);\n')

fprintf('\nTo evaluate the SSE metamodel on a new set of inputs Xval, type:\n')
fprintf('    Yval = uq_evalModel(Xval);\n')

fprintf('\nThe following options are set by default if not specified by the user:\n\n')
fprintf('    SSEOPTIONS.ExpOptions.Type = ''Metamodel''\n');
fprintf('    SSEOPTIONS.ExpOptions.MetaType = ''PCE''\n');
fprintf('    SSEOPTIONS.ExpOptions.Degree = 1:4\n');
fprintf('    SSEOPTIONS.ExpOptions.Method = ''LARS''\n');
fprintf('    SSEOPTIONS.Input = uq_getInput()\n');
fprintf('    SSEOPTIONS.FullModel = uq_getModel()\n');
fprintf('    SSEOPTIONS.ExpDesign.Sampling = ''LHS''\n');
fprintf('\n');
fprintf('Please refer to the Stochastic Spectral Embedding User Manual (<a href="matlab:uq_doc(''SSE'',''html'')">HTML</a>,<a href="matlab:uq_doc(''SSE'',''pdf'')">PDF</a>)');
fprintf('\nfor more detailed information on the available features.')
fprintf('\n\n')