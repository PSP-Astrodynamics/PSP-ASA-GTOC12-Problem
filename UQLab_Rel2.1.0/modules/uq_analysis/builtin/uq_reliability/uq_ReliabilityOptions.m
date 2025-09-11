% UQ_RELIABILITYOPTIONS displays a helper for the main options needed to create a
%               reliability analysis in UQLab.
%
%    UQ_RELIABILITYOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createAnalysis">uq_createAnalysis</a> to create a Reliability ANALYSIS object
%    in UQLab.
%
%    See also: uq_createAnalysis, uq_getAnalysis, uq_listAnalyses, uq_selectAnalysis 

fprintf('Quickstart guide to the UQLab Reliability Analysis Module\n')
fprintf('\n')

fprintf('In the UQLab software, Reliability ANALYSIS objects are created by the command:\n')
fprintf('\n')
fprintf('    myReliabilityAnalysis = uq_createAnalysis(RELIABILITYOPTIONS)\n');
fprintf('\n')
fprintf('The options are specified in the RELIABILITYOPTIONS structure.\n')
fprintf('\n')

fprintf('Example: to create a reliability analysis with FORM, type:\n')
fprintf('\n')
fprintf('    RELIABILITYOPTIONS.Type = ''Reliability'';\n')
fprintf('    RELIABILITYOPTIONS.Method = ''FORM'';\n')
fprintf('    myReliabilityAnalysis = uq_createAnalysis(RELIABILITYOPTIONS)\n')
fprintf('\n')

fprintf('To graphically display the analysis results, type:\n')
fprintf('\n')
fprintf('    uq_display(myAnalysis)\n')
fprintf('\n')

fprintf('The reliability analysis methods currently available in UQLab are:\n')
fprintf('\n')
fprintf('    %-15s - %s\n', '''FORM''','First order reliability method')
fprintf('    %-15s - %s\n', '''SORM''','Second order reliability method')
fprintf('    %-15s - %s\n', '''MC''','Monte-Carlo sampling-based reliability')
fprintf('    %-15s - %s\n', '''IS''','Importance sampling')
fprintf('    %-15s - %s\n', '''Subset''','Subset simulation')
fprintf('    %-15s - %s\n', '''AKMCS''','Active-Kriging Monte Carlo simulation')
fprintf('\n')

fprintf(['Please refer to the Reliability User Manual ',...
    '(<a href="matlab:uq_doc(''Reliability'',''html'')">HTML</a>,'...
    '<a href="matlab:uq_doc(''Reliability'',''pdf'')">PDF</a>)\n'])
fprintf('for more detailed information on each of the available methods.\n')
fprintf('\n')