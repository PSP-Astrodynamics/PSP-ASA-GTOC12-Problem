%% uq_workflow: leaf module for workflow representation
% uq_workflow is the leaf of the gateway->core_module->module tree
% representation of uqlab. An arbitrary number of uq_workflow can exist for
% it




classdef uq_workflow < uq_module 
    properties(Hidden=true)
        core_module_names = {};
        selected_modules = {};
        selected_modules_handles = {};
    end
    
    methods(Hidden=true)
        % default constructor: creates an object with given name and
        % enforce license
        function this = uq_workflow(name, varargin)
            
            % set the default name
            this.Name = name;
            this.core_component = 'workflow';
            
            %% careful, this introduces a circular dependence if called within the gateway constructor
            gw = uq_gateway.instance(); 
            this.core_module_names = gw.core_modules;
            msize = size(this.core_module_names);
            % initialize the selected modules names to empty cells
            this.selected_modules = cell(msize);
            this.selected_modules_handles = cell(msize);
            
            % set default dispatcher (MAY BE RELOCATED IN THE FUTURE)
            this.selected_modules(strcmp(this.core_module_names, 'dispatcher')) = {'local'};
            
            % set itself as the default handle
            this.selected_modules_handles{strcmp(this.core_module_names, 'workflow')} = this;
        end % end of workflow constructor
        
        % set workflow values
        function success = set_workflow(this, modules, names)
            % add an entire workflow for the specified modules and the
            % specified names. 
            % success = set_workflow(this, modules, names) sets the currently selected
            % modules for the components specified in cell_array 'modules' to the ones with
            % names matching to the cell array of strings 'names'
            % success = set_workflow(this, MODULES) with MODULES a cell array of modules
            % automatically assigns the specified MODULES to the relevant core_modules.
            
            try
                % get the gateway
                gw = uq_gateway.instance();
                
                for ii = 1:numel(modules)
                    idx = strcmp(modules{ii},this.core_module_names);
                    this.selected_modules{idx} = names{ii};
                    this.selected_modules_handles{idx} = gw.(modules{ii}).get_module(names{ii});
                end
                
                % usual success code
                success = 1;
            catch me
                assignin('caller', 'uq_last_exception', me);
                success = 0;
            end
        end
        
        
        % ok, it's now time to retreive the workflow components
        function mname = get_module_name(this, module)
            % return the name of the desired component
            idx = strcmp(this.core_module_names, module); 
            
            % return the name if any module was found, or an empty string
            % otherwise
            if sum(idx)
                mname = this.selected_modules{idx};
            else
                mname = [];
            end
        end
        
    end
end
