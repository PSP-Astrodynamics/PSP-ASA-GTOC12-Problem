%% uq_core_model: class for model tools
% this class handles all the analyses that are defined in its leaf
% submodules, uq_model



% inheriting properties from the uq_core_module superclass
classdef uq_core_model < uq_core_module

    % the core module identifier
    properties(Constant)
        core_module_identifier = 'model';
    end
    
    properties % public properties, set by the user
       
    end
        
    methods(Static)
        function success = report()
            success = fprintf('uq_model status report:\n');
        end
    end
    
    
    methods
        % add-remove methods
        function obj = add_module(this, name, type, varargin)
            % initialization
            private_flag = false;
            overwrite_flag = false;
            
            % parse varargin for recognized keys/key pairs
            parse_keys = {'-private','-overwrite'};
            parse_types = {'f','f'};
            [parsed_options, varargin] = uq_simple_parser(varargin, parse_keys, parse_types);
            
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
                        error('Model Names must be unique! Your request to add a model named "%s" cannot be completed!', name) ;
                    end
                end
            end
            
            % Type should be case-insensitive
            type = lower(type);
            
            % check the "type" argument. If the first 3 letters are not
            % 'uq_', prepend them
            if length(type) < 3 || ~strcmp(type(1:3), 'uq_')
               type = ['uq_' type]; 
            end
            
            % we have to transparently expand the varargin here
            str = 'obj = uq_model(name, type';
            for ii = 1:length(varargin)
                iname = inputname(ii+3);
                if ~isempty(iname)
                    eval([iname ' =  varargin{ii};']);
                    str = [str ', ' iname];
                else
                    % just report the string, if any
                    str = [str ', ''' varargin{ii} ''''];
                end
            end
            
            str = [str ');'];
            
            % create a uq_module leaf object
            eval(str);
                 
            
            % now that we have created the model module, we have to check whether an
            % initialization function was defined in the module folder (e.g., to calculate the
            % coefficients in case of a PC expansion model, run consistency checks, etc.)
            try
                success = this.run_initialization_script(obj);
            catch uqException
                uq_error(uqException);
            end
            
            if success <= 0
               error('The initialization script returned an error! The error code is: \n %d\n', success);
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
        end
    end
end
