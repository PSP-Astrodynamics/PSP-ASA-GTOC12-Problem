%% uq_core_module: superclass for all the module-type subclasses. Used to create module subclasses that connect to the uqlab class
%  it will contain the interface to the uqlab gateway.
%  At the moment it is not defined as a singleton, but this behavior may
%  be changed at any moment.



classdef uq_core_module < dynamicprops % inherit from the handle class. This means it will be passed by reference, whenever the handle is passed around
    properties(SetObservable, Access=private, Hidden=true)
       initialized; 
    end
   
    % the module identifier that uniquely identifies the core module (e.g.,
    % 'input', or 'analysis', or 'model'
    properties(Abstract, Constant, Hidden=true)
        core_module_identifier;
    end
    
    properties(SetObservable, Hidden=true)
        % cell array of  module names
        modules = {};
        module_names = {};
        
    end
    
    methods(Abstract, Static, Hidden=true) 
        state = report();  % abstract reporting method to report internal status current module
        add_module(); 
    end
    
    
    methods(Hidden=true)
        % default constructor: check the license here
        function this = uq_core_module
            
        end
        
        function modules = get_all_modules(this)
            modules = this.modules;
        end
        
        function modules = available_modules(this)
           modules = this.module_names; 
        end
        
        function list_str = list_available_modules(this)  % lists all the available modules in the current supermodule
            % let's instance the gateway to find out which one is currently selected
            gw = uq_gateway.instance();
            
            % find the relevant supermodule
            idx = strcmp(gw.workflow.current_module.core_module_names, this.core_module_identifier);
            
            % now get the name of the selected one
            current_selected_module = gw.workflow.current_module.selected_modules{idx};
            
            % finally, get its index in the current scope
            current_selected_module_idx = find(strcmp(this.module_names, current_selected_module),1);
            list_str = [];
            list_str = [list_str sprintf('Available %s objects: \n', this.core_module_identifier)];
            
            for ii = 1:length(this.modules)
                % ignore empty modules
                if isequal(lower(this.modules{ii}.Type), 'empty')
                    continue;
                end
                
                if ii == current_selected_module_idx
                    firstchar = '> ';
                else
                    firstchar = '  ';
                end
                list_str = [list_str sprintf('%s%d) %s \n', firstchar, ii, this.modules{ii}.Name)];
            end
            
            fprintf('%s',list_str);
        end
        
        function module = get_module(this, name) % get a leaf module by name
            % find the module by name
            idx = strcmp(this.module_names, name);
            
            % if found, return it, otherwise return an empty value
            if sum(idx)
                module = this.modules{idx};
            else
                module = [];
            end
        end
        
        function success = remove_module(this, name)
            isCurrent = 0;
            
            % removing the module with the specified name
            idx = ~strcmp(this.module_names, name);
            
            % make sure that the currently selected workflow does not point
            % to the module being removed
            gw = uq_gateway.instance();
             % find the relevant supermodule
            widx = strcmp(gw.workflow.current_module.core_module_names, this.core_module_identifier);
            
            % now get the name of the selected one
            current_selected_module = gw.workflow.current_module.selected_modules{widx};
            
            if strcmp(current_selected_module,name);
               isCurrent = 1; 
            end
            % if the currently selected module is the one we are deleting,
            % raise a flag
            
            
            % well, everything should be done through try and catch
            % statements
            try
                % note the syntax, forcing cell concatenation (because
                % otherwise it wouldn't be a cell anymore when only one element
                % is left
                this.modules{~idx} = [];
                this.modules = {this.modules{idx}};
                % also update the module names by removing  one of them
                this.module_names = {this.module_names{idx}};
                
                % if the module we removed was the current one, set the
                % last one remaining as the current
                if isCurrent && ~isempty(this.module_names)
                    gw.workflow.current_module.set_workflow({this.core_module_identifier}, {this.module_names{end}});
                end
                
                % if we get here, it means we are at a good stage
                success = 1;
            catch me % error handling will be done here
                success = 0;
            end
        end
        
        %  now for the virtual modules defined in the superclass
        %  get currently selected model. It requires the gateway to run
        function obj = current_module(this)
            % get the handle to the gateway
            gw = uq_gateway.instance();
            
            % now get from the workflow the current selected module
            % current workflow:
            wf = gw.workflow.current_workflow_handle;
            
            % select the module specified if existent
            if ~isempty(wf)
                %obj = this.get_module(wf.get_module_name(this.core_module_identifier));
                obj = wf.selected_modules_handles{strcmp(this.core_module_identifier, gw.core_modules)};
            else
                obj = [];
            end
        end
        
        function success = run_initialization_script(this, obj)
            % now that we have created the module, we have to check whether an
            % initialization function was defined in the module folder (e.g., to calculate the
            % coefficients in case of a PC expansion model, run consistency checks, etc.)
            
            root_folder = uq_rootPath;
            % check that the module is located where it is expected to be:
            % $UQ_root/modules/uq_model/{external,contrib,builtin}
            try
                module_found = false;
                if strcmpi(obj.Type, 'empty')
                    module_found = true;
                end
                for cms = {'external', 'contrib', 'builtin'}
                    module_folder = fullfile(root_folder, 'modules', sprintf('uq_%s', this.core_module_identifier), cms{1}, obj.Type);
                    % if we find the module folder, let's check that the necessary uq_Type script
                    % exist, and execute it
                    
                    % initialize a 'module found' flag so as to figure out
                    % when a non-existent module is requested
                    if java.io.File(module_folder).exists()
                        init_filename = fullfile(module_folder, ['uq_initialize_' obj.Type]);
                        % Check the executable (to make sure it's in the
                        % correct folder
                        init_executable = [];
                        if java.io.File([init_filename '.m']).exists()
                            init_executable = [init_filename,'.m'];
                        end
                        
                        if java.io.File([init_filename '.p']).exists()
                            init_executable = [init_filename,'.p'];
                        end
                        
                        if ~isempty(init_executable)
                            module_found = true;
                        end
                        % execute it only if the path is set correctly, using the model Name
                        % as an argument for retrieval
                        if module_found
                            % careful to p-coding!!
                            if ~strcmp([init_filename '.m'] , init_executable) && ~strcmp([init_filename '.p'] , init_executable)
                                error(['Warning: initialization executable seems to be located in the wrong location: ' init_executable '!']);
                            end
                            %eval(['uq_initialize_' obj.Type '(obj);']);
                            
                            initHandle = str2func(['uq_initialize_' obj.Type]);
                            initHandle(obj);
                            % set the object to initialized
                            setinitialized(obj);
                            
                            % now add the relevant print and display
                            % methods if existent
                            if java.io.File(fullfile(module_folder, ['uq_print_' obj.Type  '.m'])).exists() || java.io.File(fullfile(module_folder, ['uq_print_' obj.Type  '.p'])).exists()
                                obj.printFun = str2func(['@uq_print_' obj.Type]);
                            end
                            
                            if java.io.File(fullfile(module_folder, ['uq_display_' obj.Type '.m'])).exists() || java.io.File(fullfile(module_folder, ['uq_display_' obj.Type  '.p'])).exists()
                                obj.displayFun = str2func(['@uq_display_' obj.Type]);
                            end
                            break;
                        end
                    end
                end
                
                
                % if the module was not yet initialized, check if it is
                % not a core module and intialize it
                if ~isfield(obj.Internal, 'Runtime') || ~isfield(obj.Internal.Runtime, 'isInitialized') || ~obj.Internal.Runtime.isInitialized
                    
                    module_folder = fullfile(root_folder, 'core', 'modules', sprintf('uq_%s', this.core_module_identifier), obj.Type);
                    if java.io.File(module_folder).exists()
                        init_filename = fullfile(module_folder, ['uq_initialize_' obj.Type]);
                    % Check the executable (to make sure it's in the
                        % correct folder
                        init_executable = [];
                        if java.io.File([init_filename '.m']).exists()
                            init_executable = [init_filename,'.m'];
                        end
                        
                        if java.io.File([init_filename '.p']).exists()
                            init_executable = [init_filename,'.p'];
                        end
                        
                        if ~isempty(init_executable)
                            module_found = true;
                        end
                        % execute it only if the path is set correctly, using the model Name
                        % as an argument for retrieval
                        if module_found
                            % careful to p-coding!!
                            if ~strcmp([init_filename '.m'] , init_executable) && ~strcmp([init_filename '.p'] , init_executable)
                                error(['Warning: initialization executable seems to be located in the wrong location: ' init_executable '!']);
                            end
                            eval(['uq_initialize_' obj.Type '(obj);']);
                            % set the object to initialized
                            setinitialized(obj);
                        end
                    end
                end
                if ~module_found
                    error('The specified %s module ''%s'' was not found in the UQLab path.\nPlease run uqlab -reinitialize if you have just created a new module folder',this.core_module_identifier,obj.Type)
                end
                success = obj.Internal.Runtime.isInitialized;
            catch me 
                success = 0;
                %warning('Could not execute the initialization script. The recorded error is: \n%s\n', me.message);
                rethrow(me);
            end
           
        end
        
        function success = clear_all_modules(this)
            try
                for ii = 1:length(this.modules)
                    this.remove_module(this.modules{1}.Name);
                end
                success = 1;
            catch me
                success = 0;
                warning(me.identifier,'Could not execute delete all modules. The recorded error is: \n%s\n', me.message);
            end
        end
        
        function imported_module = import_module(this, obj)
            % check that the class is the correct one
            objclass = class(obj);
            if ~isequal(this.core_module_identifier, objclass(4:end))
                error('The imported module belongs to the wrong class. \nTried to import a %s object as a %s module', objclass, this.core_module_identifier);
            end
            
            % check that the model does not already exist in the session
            for ii = 1:length(this.modules)
                if this.modules{ii} == obj
                    imported_module = this.modules{ii};
                    return
                    %error('The imported %s is already existent in this UQLab session with identifier: %s\n', this.core_module_identifier, ['''' this.module_names{ii} '''']);
                end
            end
            
            % now check that the name is unique
            if any(strcmp(obj.Name, this.module_names))
                obj.Internal.OriginalName = obj.Name;
                changeName(obj,sprintf('%s_%s', obj.Name, datestr(now,'yyyymmddHHMMSSfff')));
                warning('Trying to import a module with duplicate name (''%s''). Name changed to ''%s''!', obj.Internal.OriginalName, obj.Name);
            end
            
            % if everything is fine, add the object
            this.modules{end+1} = obj;
            this.module_names{end + 1} = obj.Name;

            % do not set it active
            % gw = uq_gateway.instance();
            % gw.workflow.current_module.set_workflow({this.core_module_identifier}, {obj.Name});
            
            % finally return it
            imported_module = this.modules{end};
        end
        
    end
    
end
