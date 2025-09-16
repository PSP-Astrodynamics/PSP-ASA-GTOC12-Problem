function uq_listModels
% UQ_LISTMODELS   return all the MODEL objects available in the UQLab session
%    UQ_LISTMODELS returns a list a MODEL objects that have been created by
%    the <a href="matlab:help uq_createModel">uq_createModel</a> command. 
%
%    The MODEL that is currently selected (used by default in several UQLab
%    commands like <a href="matlab:help uq_evalModel">uq_evalModel</a>) is highlighted by a '>' symbol to the left
%    of its name.  
%
%    The MODEL objects listed by this command can be accessed from within any
%    workspace (including functions) with the <a href="matlab:help uq_getModel">uq_getModel</a> function.
%
%    The name MODEL myModel created with 
%       myModel = uq_createModel(MODELOPTS) 
%    can be specified with the MODELOPTS.Name field.
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_selectModel,
%              uq_listInputs, uq_listAnalyses 
%

uq_listModules('model');