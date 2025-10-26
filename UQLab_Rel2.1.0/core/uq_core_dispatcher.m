%% uq_dispatcher: dispatcher for hpc calculations
% this class handles execution of computing tasks within
% uqlab, including hpc ones, as defined in its leaf submodules,
% uq_dispatcher

% inheriting properties from the uq_core_module superclass
classdef uq_core_dispatcher < uq_core_module 
    properties(Constant, Hidden=true)
        core_module_identifier = 'dispatcher';
    end
    
    methods(Static, Hidden=true)
        function success = report()
            success = fprintf('uq_dispatcher status report:\n');
        end
    end
    
    
    methods(Hidden=true)
        % add-remove methods
        function obj = add_module(this, name, type, varargin)
            % initialization
            private_flag = false;
            
            % parse varargin for recognized key pairs
            parse_keys = {'-private'};
            parse_types = {'f'};
            [parsed_options, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);
            
            % private flag: initialize the module but do not add it to
            % the uqlab session
            if isequal(parsed_options{1},'true')
                private_flag = true;
            end
            
            % consistency check: the provided name must be unique
            if ~private_flag
                for ii = 1:length(this.module_names)
                    if strcmp(this.module_names{ii}, name)
                        error('Dispatcher names must be unique! Your request to add a dispatcher named "%s" cannot be completed!', name) ;
                    end
                end
            end
            
            % Type should be case-insensitive
            type = lower(type);
            
            % check the "type" argument. If the first 3 letters are not
            % 'uq_', prepend them
            if ~strcmp(type, 'empty') && (length(type) < 3 || ~strcmp(type(1:3), 'uq_'))
               type = ['uq_' type]; 
            end
            
            % we have to transparently expand the varargin here
            str = 'obj = uq_dispatcher(name, type';
            for ii = 1:length(varargin)
                iname = inputname(ii+3);
                eval([iname ' =  varargin{ii};']);
                str = [str ', ' iname];
            end
            
            str = [str ');'];
            
            % create a uq_module leaf object
            eval(str);
           
            % now that we have created the model module, we have to check whether an
            % initialization function was defined in the module folder (e.g., to calculate the
            % coefficients in case of a PC expansion model, run consistency checks, etc.)
            
            success = this.run_initialization_script(obj);
            
            if ~private_flag
                % append the name to the list of available modules
                this.module_names{end+1} = name;
                
                % return the pointer to the module just created
                this.modules{end+1} = obj;
                
                % now, if available, make the module the default one
                gw = uq_gateway.instance();
                % now set in the workflow the current selected module
                % as this one
                gw.workflow.current_module.set_workflow({this.core_module_identifier}, {obj.Name});
            end
        end
        %         function obj = add_module(this, name, type, varargin)
        %             % create a uq_module leaf object
        %
        %             this.modules{end+1} = uq_dispatcher(name, type, varargin);
        %
        %             % add the name to the list of available modules
        %             this.module_names{end+1} = name;
        %
        %             % return the pointer to the module just created
        %             obj = this.modules{end};
        %         end
                
    end
end
