% UQ_MODELOPTIONS display a helper for the main options needed to create a
%                 computational model in UQLab.
%    UQ_MODELOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createModel">uq_createModel</a> to create a MODEL object in UQLab 
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectModel 


disp('Quickstart guide to the UQLab Model Module')
disp('  ')
fprintf('In the UQLab software, MODEL objects are created by the command:\n')
fprintf('    myModel = uq_createModel(MODELOPTIONS)\n');
fprintf('The options are specified in the MODELOPTIONS structure.\n')  

fprintf('\nExample: to create a MODEL object that implements the Ishigami \nanalytical function, type:\n')
fprintf('    f = @(x) sin(x(1))+7*(sin(x(2))^2) + 0.01*(x(3)^4)*sin(x(1));\n');
fprintf('    MODELOPTIONS.mHandle = f;\n')
fprintf('    myModel = uq_createModel(MODELOPTIONS);\n')

fprintf('\nTo evaluate the MODEL on the point x = [pi/2 pi/2 pi/2], type:\n')
fprintf('    y = uq_evalModel([pi/2 pi/2 pi/2]);\n')

fprintf('\nStandard formats to create a MODEL are matlab function handles (''mHandle''),\n')
fprintf('strings (''mString'') and Matlab m-files (''mFile''). \n')
fprintf('\nThe following options are set by default if not specified by the user:\n\n')
fprintf('    MODELOPTIONS.isVectorized = true;  %% (if the MODEL is an ''mFile'')\n')
fprintf('    MODELOPTIONS.isVectorized = false; %% (if the MODEL is an ''mString'' or an ''mHandle'')\n')
fprintf('\n')
fprintf('Please refer to the Model User Manual (<a href="matlab:uq_doc(''Model'',''html'')">HTML</a>,<a href="matlab:uq_doc(''Model'',''pdf'')">PDF</a>)');
fprintf('for more detailed\ninformation on the available features.')
fprintf('\n\n')