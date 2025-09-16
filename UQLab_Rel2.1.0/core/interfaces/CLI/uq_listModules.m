function varargout = uq_listModules(varargin)
% provide a list of the currently selected modules
list_str = '';
current_workflow = uq_retrieveSession('workflow');
UQ = uq_retrieveSession('UQ');

selected_modules = current_workflow.selected_modules;
mnames = current_workflow.core_module_names;
module_visibility = UQ.core_module_visibility;


%% parsing the command line
parse_keys = {'all', mnames{:}};
parse_types = {'f','f','f','f','f','f','f'};
[uq_startup_options, varargin] = uq_simple_parser(lower(varargin), parse_keys, parse_types);


modOpts = strfind(uq_startup_options(2:6), 'true');
listAll = isequal(uq_startup_options{1}, 'true');
if listAll
    listSome = 0;
else
    listSome = sum([modOpts{:}]);
end

listSelected = ~listAll && ~listSome;

if listSelected
    fprintf('Currently selected objects in UQLab:\n')
end

% now to the printing!
for ii = 1:length(mnames)
    if ~module_visibility(ii)
        continue;
    end
    
    if ~isempty(selected_modules{ii}) && ~isequal(lower(selected_modules{ii}), 'empty')
        if listAll|| ~isempty(modOpts{ii})
            list_str = UQ.(mnames{ii}).list_available_modules;
        elseif listSelected
            list_str = sprintf('%s object: ''%s''\n', mnames{ii}, selected_modules{ii});
            fprintf(list_str)
        end
    end
end
fprintf('\n');


if nargout
    varargout{1} = selected_modules;
    varargout{2} = mnames;
    varargout{3} = list_str;
end
