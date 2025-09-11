%% uqlab: mediator/gateway class of the UQLab framework. Handles communication and bookkeeping between modules.
% uqlab is a gateway singleton class (mediator) used to make all of the system variables available to all of the functions/methods that may
% require them



classdef uq_gateway < dynamicprops
    %% public properties
    properties(Hidden=true) % public properties that will be available directly to the user
        core_modules;
    end
    

    %% private methods
    % the constructor is a private method, as this is a singleton class
    methods(Access=private,Hidden=true) % this can be only invocated within this class, as it must guarantee a singleton behavior
        function this = uq_gateway()
            % initialize the contents (done only once, at instance time)
            initialize_modules(this);
        end
               
    end
    
    
    
    
    
    %% static methods
    methods(Static,Hidden=true) % this is the instance method, that creates the actual singleton, or points to the existent one
        function this = instance(options)
            persistent UQuniqueInstance
                       
           
            % let's do what we are requested to do: parse options
            if exist('options', 'var')
                if isfield(options, 'new') && options.new
                    UQuniqueInstance = [];
                end
            end
            
            % Set the initial paths only if needed (can be time consuming)
            if isempty(UQuniqueInstance)
                uq_set_paths(uq_rootPath);
                this = uq_gateway(); % singleton instance
                UQuniqueInstance = this;
            else
                this = UQuniqueInstance;
            end
        end
   
    end
    
    %% public methods
    methods(Hidden=true) % this are the public methods that can be used to access to the gw information
        function list = available_modules(this)
            list = this.core_modules;
        end
        
        
        %% module initialization and importing
        function success = initialize_modules(this, fname)
            % if the variable 'fname' is defined, it means we have to load
            % them from file, rather than from scratch
            if exist('fname', 'var')
                importing = 1;
                imported = load(fname);
                this.core_modules = imported.UQ.core_modules;
            else
                importing = 0;
            end
            
            % let's first clear any unfinished business we may still have
            this.clear_modules();
            
            % this will read the uqlab configuration file and define the
            % models to be built
            uq_parse_ini(this, 'uqlab.ini')
            
            
            % and now let's initialize the core modules (this has to be
            % defined in the uqlab.ini file, otherwise it's a dead end)
            try
                for i = 1:length(this.core_modules) 
                    % in case we are loading from an input file
                    if importing
                        this.(this.core_modules{i}) = imported.UQ.(this.core_modules{i});
                    else
                        eval(sprintf('this.(this.core_modules{%d}) = uq_core_%s;', i, this.core_modules{i}));
                    end
                end
                
                % good, everything was initialized
                success = 1;
                
            catch me % if we fail here, let's bail out
                disp('could not initialize the gw class');
                disp('additional informations may be found here: ')
                disp(me.message);
                
                % something went terribly wrong, let's make everyone aware
                success = 0;
                return;
            end
                        
        end
        
        function clear_modules(this)
            % function to clear all the modules already defined
            for i = 1:length(this.core_modules)
                evalin('caller', 'clear(''%s'')',this.core_modules{i});
            end
            this.core_modules = {};
            
        end
        
        %% import from another singleton
        %   this function is used to load the state as it was saved from a
        %   previous execution
        function this = import_session_from_file(this, fname)
            % simply reinitialize the modules by giving the necessary
            % filename 
            this.initialize_modules(fname);
        end
        
        
        function success = save_session_to_file(this, filename)
          
        end
    
    end
    %% need to figure out why the destructor does not work
end
