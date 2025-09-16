%% uq_core_input: class for input tools
% this class handles all the inputs that are defined in its leaf
% submodules, uq_input

% inheriting properties from the uq_core_module superclass
classdef uq_core_input < uq_core_module 
    
    % the core module identifier
    properties(Constant, Hidden=true)
        core_module_identifier = 'input';
    end
    
    methods(Static, Hidden=true)
        function success = report()
            success = fprintf('uq_input status report:\n');
        end
    end
    
    
    methods(Hidden=true)
        % add-remove methods
        function obj = add_module(this, name, type, varargin)
            % initialization
            private_flag = false;
            overwrite_flag = false;
            
            % parse varargin for recognized keys/key pairs
            parse_keys = {'-private','-overwrite'};
            parse_types = {'f','f'};
            [parsed_options, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);
            
            % overwrite flag: if the name is already in use, overwrite the
            % existing module with the same name
            if isequal(parsed_options{2},'true')
                overwrite_flag = true;
            end
            
            % Type should be case-insensitive
            type = lower(type);
            % check the "type" argument. If the first 3 letters are not
            % 'uq_', prepend them
            if length(type) < 3 || ~strcmp(type(1:3), 'uq_')
               type = ['uq_' type]; 
            end
            
            % private flag: initialize the module but do not add it to
            % the uqlab session
            if isequal(parsed_options{1},'true')
                private_flag = true;
            end
            
                        
            % overwrite flag: if the name is already in use, overwrite the
            % existing module with the same name
            if isequal(parsed_options{2},'true')
                overwrite_flag = true;
            end
            
            
            % consistency check: the provided name must be unique
            if ~private_flag && ~overwrite_flag
                for ii = 1:length(this.module_names)
                    if strcmp(this.module_names{ii}, name)
                        error('Input Names must be unique! Your request to add an input named "%s" cannot be completed!', name) ;
                    end
                end
            end
            
            % we have to transparently expand the varargin here
            str = 'obj = uq_input(name, type';
            for ii = 1:length(varargin)
                iname = inputname(ii+3);
                eval([iname ' =  varargin{ii};']);
                str = [str ', ' iname];
            end
            
            str = [str ');'];
            
            % create a uq_module leaf object
            eval(str);
            

            % now run the initialization script, if defined
            try
                success = this.run_initialization_script(obj);
            catch uqException
                uq_error(uqException);
            end
            
            
                        
            if success <= 0
               fprintf('Warning!! the initialization script returned an error! Continuing anyway. The error code is: \n %d\n', success);
            end
            % add the module to the uqlab session if it is not made private
            if ~private_flag
                midx = length(this.modules) + 1;
                % if the overwrite flag is set, first look for another
                % module with the same name
                if overwrite_flag
                    mm = find(strcmp(this.module_names, name),1);
                    if ~isempty(mm)
                       % module found: use the index just found
                       midx = mm;
                    end
                end
                
                % append the name to the list of available modules
                this.module_names{midx} = name;
                
                % return the pointer to the module just created
                this.modules{midx} = obj;
                
                % now, if available, make the module the default one
                gw = uq_gateway.instance();
                % now set in the workflow the current selected module
                % as this one
                gw.workflow.current_module.set_workflow({this.core_module_identifier}, {obj.Name});
            end
        end % end of add_module
    end % end of methods
end % end class
