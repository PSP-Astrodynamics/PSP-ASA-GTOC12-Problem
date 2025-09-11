function mhandle = uq_selectInput(module)
% UQ_SELECTINPUT   select an INPUT object in the UQLab session.
%    UQ_SELECTINPUT   interactively prompts the user to select one of the
%    available UQLab INPUT objects stored in the current session. The
%    selected INPUT is used by default by other UQLab commands, e.g.
%    <a href="matlab:help uq_getSample">uq_getSample</a> and <a href="matlab:help uq_getInput">uq_getInput</a>.
%
%    UQ_SELECTINPUT(INPUTNAME) selects the INPUT object with property
%    'Name' equal to the specified INPUTNAME.
%
%    UQ_SELECTINPUT(N) selects the Nth created INPUT.
%
%    myInput = UQ_SELECTINPUT(...) also returns the selected INPUT object
%    in the myInput variable. 
%    
%    To print a list of the currently existing INPUT objects, their
%    numbers and the currently selected one, use the <a href="matlab:help uq_listInputs">uq_listInputs</a> command.
%
%    See also: uq_createInput, uq_getInput, uq_listInputs, uq_getSample,
%              uq_selectModel, uq_selectAnalysis 
%

%% session retrieval
uq_retrieveSession

%% argument parsing
% if the argument is a string, select the module as a string, otherwise get the name first

% if called without argument, display the list of available modules
if ~nargin
    UQ.input.list_available_modules;
    % now request for a model
    module = input('Please select an input: ', 's');
    
    % check if a number is passed, and if it is, use it as such
    mnumber = str2double(module);
    if ~isnan(mnumber)
        module = mnumber;
    end
    
    if isempty(module) 
        if nargout % only assign an output if requested
            mhandle = UQ_input;
        end
        return;
    end
end


if ischar(module)
    mname = module;
elseif isobject(module)
    mname = module.Name;
elseif isa(module, 'double') % a number if provided
    if module <= length(UQ.input.modules)
        mname = UQ.input.modules{module}.Name;
    else
        error('The specified input does not exist');
    end
else
    error('The MODULE argument must be either a string or an object!')
end

if ~isempty(UQ_input)
    current_mname = UQ_input.Name;
else
    current_mname = [];
end

%% set the selected input
UQ_workflow.set_workflow({'input'}, {mname});
% check that the input has been assigned
uq_retrieveSession;
% and assign the retrieved input to the return value
mhandle = UQ_input;
% return the old module if the new one is wrong
if isempty(UQ_input)
    UQ_workflow.set_workflow({'input'}, {current_mname});

    fprintf('Warning: could not select the specified input: %s\n', mname);
    fprintf('Available modules are: %s\n', uq_cell2str(UQ.input.available_modules));
    
end

%% remove the output if not requested
if ~nargout
   clear('mhandle') 
end

%% update caller workspace
%evalin('caller', 'uq_retrieveSession');
