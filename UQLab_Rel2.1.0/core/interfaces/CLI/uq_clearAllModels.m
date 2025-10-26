function success = uq_clearAllModels(varargin)
% UQ_SELECT_MODEL(MODEL) makes the specified model current in UQLab. MODEL can be both a
% string ID, or a uq_model object.
% MHANDLE = UQ_SELECT_MODEL(MODEL) also returns the selected object handle

%% session retrieval
uq_retrieveSession

% by default ask for confirmation
ASSUME_YES = 0;

%% parsing the command line
parse_keys = {'-force'};
parse_types = {'f'};
[parsed_options, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);

% and use the parsed values
if strcmp(parsed_options{1}, 'true')
    ASSUME_YES = 1;
end


if ~ASSUME_YES
    rr = input('Are you sure you want to delete all of the models currently stored in the UQLab session (y/n)? [n] ', 's');
    if any(strcmpi(rr, {'y', 'yes'}))
        ASSUME_YES = 1;
    end
end

if ~ASSUME_YES
    disp('User did not confirm, no action taken!')
    return;
end

% remove the modules from memory
UQ.model.clear_all_modules;

% and remove them from the workflow
UQ_workflow.set_workflow({'model'}, {[]});
evalin('base', 'uq_retrieveSession');