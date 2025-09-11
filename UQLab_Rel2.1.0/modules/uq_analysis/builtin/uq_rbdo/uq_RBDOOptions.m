% UQ_RBDOOPTIONS displays a helper for the main options needed to create a
% reliabiliy-based design optimization analysis in UQLab.
%
%    UQ_RBDOOPTIONS displays the main options needed by the command
%    <a href="matlab:help uq_createAnalysis">uq_createAnalysis</a> to create an RBDO ANALYSIS object
%    in UQLab.
%
%    See also: uq_createAnalysis, uq_getAnalysis, uq_listAnalyses, uq_selectAnalysis 

fprintf('Quickstart guide to the UQLab Reliabiliy-based design optimization (RBDO) Module\n')
fprintf('\n')

fprintf('In the UQLab software, RBDO ANALYSIS objects are created by the command:\n')
fprintf('\n')
fprintf('    myRBDOAnalysis = uq_createAnalysis(RBDOOPTIONS)\n');
fprintf('\n')
fprintf('The options are specified in the RBDOOPTIONS structure.\n')
fprintf('\n')

fprintf('Example: to create an RBDO analysis with MYCOST, MYLIMITSTATE, MYINPUT \n')
fprintf('and a targe failure probability of 1e-3, type:\n')
fprintf('\n')
fprintf('    RBDOOPTIONS.Type = ''RBDO'';\n')
fprintf('    RBDOOPTIONS.Input = MYINPUT;\n')
fprintf('    RBDOOPTIONS.Cost.Model = MYCOST;\n')
fprintf('    RBDOOPTIONS.LimitState.Model = MYLIMITSTATE;\n')
fprintf('    RBDOOPTIONS.TargetPf = 1e-3;\n')
fprintf('    mySensitivityAnalysis = uq_createAnalysis(RBDOOPTIONS)\n')
fprintf('\n')

fprintf('To graphically display the analysis results, type:\n')
fprintf('\n')
fprintf('    uq_display(myRBDOAnalysis)\n')
fprintf('\n')

fprintf('The RBDO methods currently available in UQLab are:\n')
fprintf('\n')
fprintf('    %-15s - %s\n', '''two-level''','Generalized two-level')
fprintf('    %-15s - %s\n', '''QMC''','Quantile-based RBDO')
fprintf('    %-15s - %s\n', '''RIA''','Reliability index approach')
fprintf('    %-15s - %s\n', '''PMA''','Performance measure approach')
fprintf('    %-15s - %s\n', '''SLA''','Single loop approach')
fprintf('    %-15s - %s\n', '''SORA''','Sequential optimization and reliability assessment')

fprintf('\n')

fprintf(['Please refer to the RBDO User Manual ',...
    '(<a href="matlab:uq_doc(''RBDO'',''html'')">HTML</a>,',...
    '<a href="matlab:uq_doc(''RBDO'',''pdf'')">PDF</a>)\n'])
fprintf('for more detailed information on each of the available methods.\n')
fprintf('\n')