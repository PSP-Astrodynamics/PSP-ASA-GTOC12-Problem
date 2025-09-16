function mhandle = uq_selectDispatcher(module)
%UQ_SELECTDISPATCHER selects a DISPATCHER object in the UQLab session.
%
%   UQ_SELECTDISPATCHER interactively prompts the user to select one of the
%   available UQLab DISPATCHER objects stored in the current UQLab session.
%   The selected DISPATCHER is used, by default, by other UQLab commands,
%   e.g., (<a href="matlab:help uq_getDispatcher">uq_getDispatcher</a> or <a 
%   href="matlab:help uq_evalModel">uq_evalModel</a>).
%
%   UQ_SELECTDISPATCHER(DISPATCHERNAME) selects the DISPATCHER object
%   with the property 'Name' equal to the specified DISPATCHERNAME.
%
%   UQ_SELECTDISPATCHER(N) selects the Nth DISPATCHER object in the UQLab
%   session. Note that the 1st DISPATCHER object is the 'empty' DISPATCHER,
%   i.e., the DISPATCHER object for the local computing resource.
%
%   myDispatcher = UQ_SELECTDISPATCHER(...) also returns the selected
%   DISPATCHER object.
%    
%   To print a list of the currently existing ANALYSIS objects, their 
%   numbers and the currently selected one, use the <a 
%   href="matlab:help uq_listDispatchers">uq_listDispatchers</a> command.
%
%   See also uq_createDispatcher, uq_getDispatcher, uq_listDispatchers.


%% session retrieval
uq_retrieveSession

%% argument parsing
% if the argument is a string, select the module as a string, otherwise get the name first

% if called without argument, display the list of available modules
if ~nargin
    UQ.dispatcher.list_available_modules;
    % now request for a model
    module = input('Please select a dispatcher: ', 's');
    
    % check if a number is passed, and if it is, use it as such
    mnumber = str2double(module);
    if ~isnan(mnumber)
        module = mnumber;
    end
    
    if isempty(module) 
        if nargout % only assign an output if requested
            mhandle = UQ_dispatcher;
        end
        return;
    end
end

if ischar(module)
    mname = module;
elseif isobject(module)
    mname = module.Name;
elseif isa(module, 'double') % a number if provided
    if module <= length(UQ.dispatcher.modules)
        mname = UQ.dispatcher.modules{module}.Name;
    else
        error('The specified dispatcher does not exist');
    end
else
    error('The MODULE argument must be a string, a number or an object!')
end

if ~isempty(UQ_dispatcher)
    current_mname = UQ_dispatcher.Name;
else
    current_mname = [];
end

%% set the selected dispatcher
UQ_workflow.set_workflow({'dispatcher'}, {mname});
% check that the dispatcher has been assigned
uq_retrieveSession;
% and set the mhandle to the selected module
mhandle = UQ_dispatcher;

% return the old module if the new one is wrong

if isempty(UQ_dispatcher)
    UQ_workflow.set_workflow({'dispatcher'}, {current_mname});
    fprintf('Warning: could not select the specified dispatcher: %s\n', mname);
    fprintf('Available modules are: %s\n', uq_cell2str(UQ.dispatcher.available_modules));
end

%% remove the output if not requested
if ~nargout
   clear('mhandle') 
end


%% update caller workspace
%evalin('caller', 'uq_retrieveSession');
