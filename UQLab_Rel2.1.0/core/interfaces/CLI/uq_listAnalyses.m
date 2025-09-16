function uq_listAnalyses
% UQ_LISTANALYSES return all the ANALYSIS objects available in the UQLab session
%    UQ_LISTANALYSES returns a list a ANALYSIS objects that have been created by
%    the uq_createAnalysis command. 
%
%    The ANALYSIS that is currently selected (used by default in several UQLab
%    commands like <a href="matlab:help uq_getAnalysis">uq_getAnalysis</a>) is highlighted by a '>' symbol to the left 
%    of its name. 
%
%    The ANALYSIS objects listed by this command can be accessed from within any
%    workspace (including functions) with the <a href="matlab: help uq_getAnalysis">uq_getAnalysis</a> function.
%
%    The name of each model created with 
%       myAnalysis = uq_createAnalysis(ANALYSISOPTS) 
%    can be specified with the ANALYSISOPTS.Name field
%
%    See also: uq_createAnalysis, uq_getAnalysis, uq_selectAnalysis, 
%              uq_listInputs, uq_listModels
%

uq_listModules('analysis');