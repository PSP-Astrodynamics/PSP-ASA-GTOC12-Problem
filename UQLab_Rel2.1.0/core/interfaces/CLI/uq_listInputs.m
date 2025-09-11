function uq_listInputs
% UQ_LISTINPUTS   return all the INPUT objects available in the UQLab session.
%    UQ_LISTINPUTS returns a list a INPUT objects that have been created by
%    the <a href="matlab:help uq_createInput">uq_createInput</a> command. 
%
%    The INPUT that is currently selected (used by default in several UQLab
%    commands like <a href="matlab:help uq_getSample">uq_getSample</a>) is highlighted by a '>' symbol to the left 
%    of its name. 
%
%    The INPUT objects listed by this command can be accessed from within any
%    workspace (including functions) with the <a href="matlab:help uq_getInput">uq_getInput</a> function.
%
%    The name of each model created with 
%       myInput = uq_createInput(INPUTOPTS) 
%    can be specified with the INPUTOPTS.Name field
%
%    See also: uq_createInput, uq_getInput, uq_selectInput, uq_getSample,
%              uq_listModels, uq_listAnalyses 
%

uq_listModules('input');