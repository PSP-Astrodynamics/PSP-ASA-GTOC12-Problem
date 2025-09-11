% UQ_SENSITIVITYOPTIONS displays a helper for the main options needed to create a
%               sensitivity analysis in UQLab.
%
%    UQ_SENSITIVITYOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createAnalysis">uq_createAnalysis</a> to create a Sensitivity ANALYSIS object
%    in UQLab.
%
%    See also: uq_createAnalysis, uq_getAnalysis, uq_listAnalyses, uq_selectAnalysis 

fprintf('Quickstart guide to the UQLab Sensitivity Analysis Module\n')
fprintf('\n')

fprintf('In the UQLab software, Sensitivity ANALYSIS objects are created by the command:\n')
fprintf('\n')
fprintf('    mySensitivityAnalysis = uq_createAnalysis(SENSITIVITYOPTIONS)\n');
fprintf('\n')
fprintf('The options are specified in the SENSITIVITYOPTIONS structure.\n')
fprintf('\n')

fprintf('Example: to create a sensitivity analysis with Sobol'' indices of order 1\n')
fprintf('with 1e4 samples per input variable, type:\n')
fprintf('\n')
fprintf('    SENSITIVITYOPTIONS.Type = ''Sensitivity'';\n')
fprintf('    SENSITIVITYOPTIONS.Method = ''Sobol'';\n')
fprintf('    SENSITIVITYOPTIONS.Sobol.Order = 1;\n')
fprintf('    SENSITIVITYOPTIONS.Sobol.SampleSize = 1e4;\n')
fprintf('    mySensitivityAnalysis = uq_createAnalysis(SENSITIVITYOPTIONS)\n')
fprintf('\n')

fprintf('To graphically display the analysis results, type:\n')
fprintf('\n')
fprintf('    uq_display(mySensitivityAnalysis)\n')
fprintf('\n')

fprintf('The sensitivity analysis methods currently available in UQLab are:\n')
fprintf('\n')
fprintf('    %-15s - %s\n', '''Correlation''','Input/output correlation indices')
fprintf('    %-15s - %s\n', '''SRC''','Standard regression coefficients')
fprintf('    %-15s - %s\n', '''Perturbation''','Perturbation-based indices')
fprintf('    %-15s - %s\n', '''Cotter''','Cotter sensitivity measure')
fprintf('    %-15s - %s\n', '''Morris''','Morris elementary effects')
fprintf('    %-15s - %s\n', '''Sobol''','Sobol'' indices')
fprintf('    %-15s - %s\n', '''Borgonovo''','Borgonovo indices')
fprintf('    %-15s - %s\n', '''ANCOVA''','ANCOVA indices')
fprintf('    %-15s - %s\n', '''Kucherenko''','Kucherenko indices')
fprintf('\n')

fprintf(['Please refer to the Sensitivity User Manual ',...
    '(<a href="matlab:uq_doc(''Sensitivity'',''html'')">HTML</a>,',...
    '<a href="matlab:uq_doc(''Sensitivity'',''pdf'')">PDF</a>)\n'])
fprintf('for more detailed information on each of the available methods.\n')
fprintf('\n')