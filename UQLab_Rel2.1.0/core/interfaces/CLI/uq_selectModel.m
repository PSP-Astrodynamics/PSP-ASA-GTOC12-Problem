function mhandle = uq_selectModel(module)
% UQ_SELECTMODEL   select a MODEL object in the UQLab session
%    UQ_SELECTMODEL interactively prompts the user to select one of the
%    available UQLab MODEL objects stored in the current session. The
%    selected MODEL is used by default by other UQLab commands, e.g.
%    <a href="matlab:help uq_evalModel">uq_evalModel</a> and <a href="matlab:help uq_getModel">uq_getModel</a>.
%
%    UQ_SELECTMODEL(MODELNAME) selects the MODEL object with property
%    'Name' equal to the specified MODELNAME.
%
%    UQ_SELECTMODEL(N) selects the Nth created MODEL.
%
%    myModel = UQ_SELECTMODEL(...) also returns the selected MODEL object
%    in the myModel variable. 
%    
%    To print a list of the currently existing MODEL objects, their 
%    numbers and the currently selected one, use the <a href="matlab:help uq_listModels">uq_listModels</a> command.
%
%    See also: uq_createModel, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectInput, uq_selectAnalysis 
%

%% session retrieval
uq_retrieveSession

%% argument parsing
% if the argument is a string, select the module as a string, otherwise get the name first

% if called without argument, display the list of available modules
if ~nargin
    UQ.model.list_available_modules;
    % now request for a model
    module = input('Please select a model: ', 's');
    
    % check if a number is passed, and if it is, use it as such
    mnumber = str2double(module);
    if ~isnan(mnumber)
        module = mnumber;
    end
    
    if isempty(module) 
        if nargout
            mhandle = UQ_model;
        end
        return;
    end
end

if ischar(module)
    mname = module;
elseif isobject(module)
    mname = module.Name;
elseif isa(module, 'double') % a number if provided
    if module <= length(UQ.model.modules)
        mname = UQ.model.modules{module}.Name;
    else
        error('The specified model does not exist');
    end
else
    error('The MODULE argument must be either a string or an object!')
end

if ~isempty(UQ_model)
    current_mname = UQ_model.Name;
else
    current_mname = [];
end

%% set the selected model
UQ_workflow.set_workflow({'model'}, {mname});
% check that the model has been assigned
uq_retrieveSession;
% assign the model handle to the return value
mhandle = UQ_model;

% return the old module if the new one is wrong
if isempty(UQ_model)
    UQ_workflow.set_workflow({'model'}, {current_mname});
    fprintf('Warning: could not select the specified model: %s\n', mname);
    fprintf('Available modules are: %s\n', uq_cell2str(UQ.model.available_modules));
    
end

if ~nargout
    clear('mhandle');
end
%% update caller workspace
%evalin('caller', 'uq_retrieveSession');
