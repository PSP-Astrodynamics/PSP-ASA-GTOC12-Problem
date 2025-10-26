function varargout = uq_retrieveSession(varargin)
% uq_retreive: creates in the current workspace all the variables that have
% been created by the uqlab framework. It is the main wrapper around the
% gateway + supermodule structure

%% parse the command line, if any
if nargin
    % note: they should in the same order as in core_modules
    parse_keys = {'UQ','model','input', 'analysis','dispatcher', 'workflow'};
    parse_types = {'f', 'f', 'f', 'f', 'f', 'f'};
    [parsed_retrieve_vars, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);
    retrieve_vars = strcmp(parsed_retrieve_vars, 'true');
else
    retrieve_vars = true(1,6);
end

% get the singleton gateway instance
uq_gw = uq_gateway.instance();

% now get the modules that need be loaded
core_modules = uq_gw.available_modules;
nmodules = numel(core_modules);

% as well as the current workflow
if ~isempty(uq_gw.workflow.current_workflow_handle)
    selected_modules_handles = uq_gw.workflow.current_workflow_handle.selected_modules_handles;
else
    selected_modules_handles = cell(1, nmodules);
end


nout = 0;
if retrieve_vars(1)
    if ~nargout
        % assign in the caller workspace the singleton gateway
        assignin('caller', 'UQ', uq_gw);
    else
        nout = nout + 1;
        varargout{1} = uq_gw;
    end
end
if ~any(retrieve_vars(2:end))
    return;
end

% and assign convenient shortcuts to the modules currently selected to the main workspace

for ii = 1:nmodules
    if retrieve_vars(1+ii)
        if nargout
            nout = nout + 1;
            varargout{nout} = selected_modules_handles{ii};
        else
            assignin('caller', sprintf('UQ_%s', core_modules{ii}), selected_modules_handles{ii});
        end
    end
end

