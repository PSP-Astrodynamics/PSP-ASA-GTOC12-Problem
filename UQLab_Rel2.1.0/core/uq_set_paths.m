%% uq_set_paths: set the paths necessary to the execution of uqlab

function output = uq_set_paths(root_folder, options)


subfolders = { ...
    'core' ...
    'lib' ...
    'modules' ...
    'Examples'...
    'Doc'...
    };

% also get the core modules
core_module_dirs = dir(fullfile(root_folder, 'modules', 'uq_*'));
core_module_dirs = core_module_dirs([core_module_dirs.isdir]);
core_module_dirnames = {core_module_dirs.name};

% now for the others
try
    % let's cache the full paths before adding it
    uqlab_path_cache = cell(length(subfolders),1);
    for ii = 1:length(subfolders)
        if strcmp(subfolders{ii}, 'modules') % go non-recursive in the modules folder
            %uqlab_path_cache{ii} = [fullfile(root_folder, subfolders{ii}) pathsep];
            for jj = 1:length(core_module_dirnames)
                if core_module_dirs(ii).isdir
                    uqlab_path_cache{ii} = [fullfile(root_folder, subfolders{ii}, core_module_dirs(jj).name) pathsep uqlab_path_cache{ii}];
                end
            end
        elseif strcmp(subfolders{ii}, 'core')||strcmp(subfolders{ii}, 'Examples')
            uqlab_path_cache{ii} = [fullfile(root_folder, subfolders{ii}) pathsep];
            % same for the core folder (there may be version thingies here)
            current_subfolders = dir(fullfile(root_folder, subfolders{ii}));
            current_subfolders = current_subfolders([current_subfolders.isdir]);
            current_subfolders_names = {current_subfolders.name};

            % exclude '.','..' and any other subfolder that contains '.svn'
            idx = ~strcmp('.',current_subfolders_names)& ~strcmp('..',current_subfolders_names) & ~strcmp('.svn', current_subfolders_names);
            current_subfolders = current_subfolders(idx);
            for jj = 1:length(current_subfolders)
                uqlab_path_cache{ii} = [genpath(fullfile(root_folder, subfolders{ii}, current_subfolders(jj).name)) pathsep uqlab_path_cache{ii}];
            end
        else
            uqlab_path_cache{ii} = [genpath(fullfile(root_folder, subfolders{ii})) pathsep];
        end
    end
    % and add all of them together
    % now concatenate them together and add them
    addpath([uqlab_path_cache{:}], '-BEGIN');
    output.success = 1;
catch me
    output.success = 0;
    output.me = me;
end

% now let's make sure that the custom methods in the modules subfolder are added as the
% first folders in the path in the following order of priority: 
% external, contrib and builtin.


%if output.success
try
    % get the modules
    submodules = {'external','contrib', 'builtin'};
    
    % initialize the cell array of paths
    uqlab_path_cache = cell(length(submodules), length(core_module_dirnames));
    
    % cycle over the submodule types
    for sm = 1:length(submodules)
        %now cycle through each subfolder
        for ii = 1:length(core_module_dirnames);
            if core_module_dirs(ii).isdir
                uqlab_path_cache{sm,ii} = [genpath(fullfile(root_folder, 'modules', core_module_dirnames{ii}, submodules{sm})) pathsep];
                %addpath(genpath(fullfile(root_folder, 'modules', dirnames{ii}, submodules{sm})), '-BEGIN');
            end
        end
    end
    addpath([uqlab_path_cache{:}], '-BEGIN');
    output.success = 1;
catch me
    output.success = 0;
    fprintf('Could not set all paths\n');
    disp(me.message)
end

