%% uq_core_workflow: class for workflow tools
% this class handles all the analyses that are defined in its leaf
% submodules, uq_workflow



% inheriting properties from the uq_core_module superclass
classdef uq_core_workflow < uq_core_module 
    properties(Constant)
        % name of the current core_module implementation 
        core_module_identifier = 'workflow' ;
    end
    
    properties % public properties, set by the user
        % at initialization it will contain only the default workflow,
        % which is defined as an emptyset. It will be populated
        % automatically when the various components are added to the
        % gateway
        current_workflow = 'default';
        current_workflow_handle = [];
    end
    
    methods(Static)
        function success = report()
            success = fprintf('uq_workflow status report:\n');
        end
    end
    
    
    methods        
        % add-remove methods
        function obj = add_module(this, name, varargin)
            % consistency check: the provided name must be unique
            for ii = 1:length(this.module_names)
                if strcmp(this.module_names{ii}, name)
                   error('Input identifiers must be unique! Your request to add a workflow named "%s" cannot be completed!', name) ;
                end
            end
            % create a uq_module leaf object
            this.modules{end+1} = uq_workflow(name, varargin);
            
            % add the name to the list of available modules
            this.module_names{end+1} = name; 
            
            % return the pointer to the module just created
            obj = this.modules{end};
            
            % now set in the child workflow the correct value
            % as this one
            obj.set_workflow({this.core_module_identifier}, {obj.Name});
            this.current_workflow_handle = obj;
        end
        
        % overwriting the default current_module function due to the
        % special characteristics of uq_workflow
        function obj = current_module(this)
            % return the currently selected module
            %obj = get_module(this, this.current_workflow);
            obj = this.current_workflow_handle;
        end
        
        % method to set the current workflow module
        function success = set_workflow(this, name) 
            if sum(strcmp(this.module_names, name))
                this.current_workflow = name;
                this.current_workflow_handle = get_module(this, name);
                success = 1;
            else
                success = 0;
            end
        end
    end
end
