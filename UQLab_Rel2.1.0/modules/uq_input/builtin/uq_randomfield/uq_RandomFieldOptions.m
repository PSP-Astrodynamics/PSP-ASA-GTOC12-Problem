% UQ_RANDOMFIELDOPTIONS display a helper for the main options needed to 
%    create a random field in UQLab.
%    UQ_RANDOMFIELDOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createInput">uq_createInput</a> to create a RANDOM FIELD object in UQLab 
%
%    See also: uq_createInput, uq_getSample, uq_getInput, uq_listInputs,
%              uq_selectInput

disp('Quickstart guide to the UQLab Random field Module')
disp('  ')
fprintf('In the UQLab software, RANDOM FIELD objects are created by the command:\n')
fprintf('    myRFInput = uq_createInput(RFOPTIONS)\n');
fprintf('The options are specified in the RFOPTIONS structure.\n')  

fprintf('\nExample: to create a Gaussian random field defined in the domain \n')
fprintf('[0,1] with mean 1, standard deviation 1 and a Gaussian auto-correlation \n')
fprintf('function with correlation length 0.3, type:\n')
fprintf('    RFOPTIONS.Type = ''randomfield'';\n')
fprintf('    RFOPTIONS.Mean = 1;\n')
fprintf('    RFOPTIONS.Std = 1;\n')
fprintf('    RFOPTIONS.Domain = [0; 1];\n')
fprintf('    RFOPTIONS.Corr.Family = ''Gaussian'';\n')
fprintf('    RFOPTIONS.Corr.Length = 0.3;\n')
fprintf('    myRFInput = uq_createInput(RFOPTIONS);\n')

fprintf('\nTo draw 100 trajectories from the resulting object, type:\n')
fprintf('    X = uq_getSample(100);\n')

fprintf('\nThe following options are set by default if not specified by the user:\n\n')
fprintf('    RFOPTIONS.RFType = ''Gaussian''\n');
fprintf('    RFOPTIONS.DiscScheme = ''EOLE''\n');
fprintf('    RFOPTIONS.EnergyRatio = 0.99\n');
fprintf('    Furthermore, the random field is discretized on a mesh defined by\n');
fprintf('    a grid built using 5 points per correlation length per direction.\n\n') ;

fprintf('\n');
fprintf('Please refer to the Random Field User Manual (<a href="matlab:uq_doc(''RF'',''html'')">HTML</a>,<a href="matlab:uq_doc(''RF'',''pdf'')">PDF</a>)');
fprintf('\nfor more detailed information on the available features.')
fprintf('\n\n')