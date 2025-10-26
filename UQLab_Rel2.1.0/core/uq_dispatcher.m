%% uq_dispatcher: leaf module for dispatcher representation
% uq_dispatcher is the leaf of the gateway->core_module->module tree
% representation of uqlab. An arbitrary number of uq_dispatchers can exist for


classdef uq_dispatcher < uq_module
    properties
        %Type = 'empty';
        Runtime = [];
    end
    
    % those properties should be observable: if they change, they will notify the system
    % through the events PreSet, PostSet, etc.
    properties(SetObservable)
        % default to empty type dispatcher
        command;
        %results;
        Options = [];
        isExecuting = 0;
        merge = [];
    end
    
    methods(Hidden=true)
        % default public constructor (only contains the name)
        function this = uq_dispatcher(name, type, varargin)
            
            % set the name of this dispatcher to the one specified
            this.Name = name;
            this.Type = type;
            % core component this module belongs to
            this.core_component = 'dispatcher';
            % now add the remaining command line arguments directly as
            % properties for later access
            for ii = 3:nargin
                % if we have at least 1 optional argument, we assume it is a
                % structure and add properties according to its fields
                if ii == 3 % the first argument
                    if isstruct(varargin{1}) %only act if it is a structure
                        this.Options = varargin{1};
                        continue;
                    end
                end
            end
            
            % ok, if we defined a merge function in the properties, let's set it here
            if isprop(this, 'merge_function')
                this.set_merge_function(this.merge_function);
            end
            
            % set the initialization flag to 0 (still needs to be initialized, if available)
            this.Internal.Runtime.isInitialized = 0;
        end
        
        % add command method
        function success = set_command(this, string)
            try
                this.command = string;
            catch me
                success = 0;
                disp('There was an error while setting the requested command. ')
                disp('You may find additional information in the following exception message:');
                disp(me.message);
            end
        end
        
        % this function generates a sample of size N on the basis of the
        % requested properties
        function varargout = run(this) % runs the dispatcher on the currently selected input N times
            this.isExecuting = 1;
            try

                [varargout{1:nargout}] = uq_ssh_dispatcher(this);
                %                 end
                this.isExecuting = 0;
                % and assign the results here
                
                
            catch me
                disp('something went wrong while trying to dispatch the desired operation');
                disp('You may find additional information in the following exception message:');
                disp(me.message);
                rethrow(me);
                
            end
        end
        
        function success = set_merge_function(this,fname)
            % set a merge function to be executed at the end of the dispatcher
            this.merge = str2func(fname);
        end
        
    end
end
