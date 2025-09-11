%% uq_model: leaf module for model representation
% uq_model is the leaf of the gateway->core_module->module tree
% representation of uqlab. An arbitrary number of uq_models can exist for


classdef uq_model < uq_module 
    properties(SetObservable,Hidden=true)
        eval;
        run;
    end
    
    methods(Hidden=true)
        % default public constructor (only contains the name)
        function this = uq_model(name, type, varargin)
            
            % set the name of this model to the one specified
            this.Name = name;
            this.Type = type;
            this.core_component = 'model';
            
            % now that we have the type, we must expect a function with the
            % same name that can be called by getsample with the number of
            % samples as a unique argument
            try 
                % in general we expect two scripts in the path: eval_type.m and
                % uq_type, the first needed to evaluate a model on a given input,
                % and one that automatically evaluates it on a sample
                str = ['@uq_run_' type];
                evstr = ['@uq_eval_' type];
                
                % and now define the necessary handles
                this.run = str2func(str); % will execute the specified operations within UQLab on a sample
                this.eval = str2func(evstr); % will evaluate the model on a specified input vector
            catch me 
                % this needs to be handled properly with error handling
                % (uq_error)?? and I/O
                fprintf('Error: could not initialize the function handle. The reported error follows: \n %s \n', me.message);
                return;
            end
            
            for ii = 3:nargin
                % for the other variables in the input, just set them as
                % properties
                % the name of the variable in the caller workspace
                iname = inputname(ii);
                
                if ~isempty(iname) % only act if the property name can be retrieved
                    % add the property-value
                    uq_addprop(this, iname, varargin{ii-2});
                %else % throw an exception/error/warning
                    %fprintf('Warning: one of the specified properties (%d: %s) could not be recognized. Are you sure you set it through a variable??\n\n', ii - 2, varargin{ii-2});
                end
            end % end of loop over the input arguments
            this.Internal.Runtime.isInitialized = 0;
        end % constructor method
    end % end of methods section
end % end of class definition
