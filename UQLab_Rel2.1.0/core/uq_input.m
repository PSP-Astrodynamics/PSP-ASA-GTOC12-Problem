%% uq_input: leaf module for input representation
% uq_input is the leaf of the gateway->core_module->module tree
% representation of uqlab. An arbitrary number of uq_inputs can exist for



classdef uq_input < uq_module 
    properties(SetObservable,Hidden=true)
        % the function handle that will represent the function invoked by
        % the uq_getSample function. We want a function handle because it is
        % much faster than using eval/feval.
        % sampling_scheme
        getSample
    end
    
    
    
    methods(Hidden=true)
        % default public constructor (only contains the name)
        function this = uq_input(name, type, varargin)
            
            % set the name of this input to the one specified
            this.Name = name;
            this.core_component = 'input';
            % and the type as well
            this.Type = type;
            
            % now that we have the type, we must expect a function with the
            % same name that can be called by getsample with the number of
            % samples as the unique argument
            try 
                str = ['@' type];
                this.getSample = str2func(str);
            catch me 
                % this needs to be handled properly with error handling
                % (uq_error)?? and I/O
                fprintf('Error: could not initialize the function handle. The reported error follows: \n %s \n', me.message);
                return;
            end
                        
            % now add the remaining command line arguments directly as
            % properties for later access
            for ii = 3:nargin
                % for the other variables in the input, just set them as
                % properties
                % the name of the variable in the caller workspace
                iname = inputname(ii);
                
                if ~isempty(iname) % only act if the property name can be retrieved
                    this.addprop(iname);
                    this.(iname) = varargin{ii-2}; 
                %else % throw an exception/error/warning
                    %fprintf('Warning: one of the specified properties (%d) could not be recognized. Are you sure you set it through a variable??', ii - 2);
                end
            end
            
            %             % at this point we have to run the necessary consistency checks (e.g., that the marginals are defined correctly, all of the necessary parameters are set and so on)
            %             success = uq_validate_input(this);
            %             if ~success
            %                error(['Error: could not correctly initialize the input ' this.Name '!!']);
            %             end
        end
        
        % this function generates a sample of size N on the basis of the
        % requested properties
        %function sample = getSample(this, N) % big wrapper function that will collect samples based on the specified options
        %    fh = this.fhandle;
        %    sample = fh(N);
        %end
    end
    
end
