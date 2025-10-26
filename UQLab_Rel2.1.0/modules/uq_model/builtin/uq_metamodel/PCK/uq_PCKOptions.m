% UQ_PCKOPTIONS display a helper for the main options needed to create a
%               Polynomial Chaos-Kriging metamodel in UQLab.
%    UQ_PCKOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createModel">uq_createModel</a> to create a PCK MODEL object in UQLab 
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectModel 


disp('Quickstart guide to the UQLab PCK Module')
disp('  ')
fprintf('In the UQLab software, PC-Kriging MODEL objects are created by the command:\n')
fprintf('    myPCK = uq_createModel(PCKOPTIONS)\n');
fprintf('The options are specified in the PCKOPTIONS structure.\n')
%
fprintf('\nExample: to create a PC-Kriging metamodel with an experimental\n')
fprintf('design of size 100 from the current INPUT and MODEL objects, type:\n\n')
fprintf('    PCKOPTIONS.Type = ''Metamodel'';\n')
fprintf('    PCKOPTIONS.MetaType = ''PCK'';\n')
fprintf('    PCKOPTIONS.ExpDesign.NSamples = 100;\n')
fprintf('    myPCK = uq_createModel(PCKOPTIONS);\n')

fprintf('\nTo evaluate the PCK metamodel on a new set of inputs Xval, type:\n\n')
fprintf('    Yval = uq_evalModel(Xval);\n')

fprintf('\nThe following options are set by default if not specified by the user:\n\n')
fprintf('    PCKOPTIONS.Mode = ''Sequential'';\n');
fprintf('    PCKOPTIONS.PCK.Degree = 3;\n');
fprintf('\n');
fprintf('The remaining PCE- and Kriging-specific options follow the defaults \nof each technique. ');
fprintf('See also: <a href="matlab:help uq_PCEOptions">uq_PCEOptions</a>, <a href="matlab:help uq_KrigingOptions">uq_KrigingOptions</a>.\n' )
fprintf('\n');
fprintf('Please refer to the PC-Kriging User Manual (<a href="matlab:uq_doc(''PCK'',''html'')">HTML</a>,<a href="matlab:uq_doc(''PCK'',''pdf'')">PDF</a>)');
fprintf('\nfor more detailed information on the available features.')
fprintf('\n\n')