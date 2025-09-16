function uq_listDispatchers
%UQ_LISTDISPATCHERS lists all the DISPATCHER objects available in the UQLab session.
%
%   UQ_LISTDISPATCHERS returns a list of a DISPATCHER objects that have
%   been created by the <a
%   href="matlab:help uq_createDispatcher">uq_createDispatcher</a> command. 
%
%   The DISPATCHER object that is currently selected (used by default in
%   several UQLab commands like <a
%   href="matlab:help uq_evalModel">uq_evalModel</a>) is highlighted
%   by a '>' symbol to the left of its name.  
%
%   The DISPATCHER objects listed by this command can be accessed from
%   within any workspace (including functions) with the <a 
%   href="matlab:help uq_getDispatcher">uq_getDispatcher</a>
%   command.
%
%   The name of a DISPATCHER object myModel created with
%       myDispatcher = uq_createDispatcher(DISPATCHEROPTS) 
%   can be specified with the DISPATCHEROPTS.Name field.
%
%   See also uq_createDispatcher, uq_getDispatcher, uq_selectDispatchers.


uq_listModules('dispatcher');