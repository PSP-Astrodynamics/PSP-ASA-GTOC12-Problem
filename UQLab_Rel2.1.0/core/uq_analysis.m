%% uq_analysis: leaf module for analysis representation
% uq_analysis is the leaf of the gateway->core_module->module tree
% representation of uqlab. An arbitrary number of uq_analysis can exist for


classdef uq_analysis < uq_module 
    properties(Access=private, Hidden=true)
        % in case we want to store multiple results, we need a counter
        results_idx = 1;
    end
    
    properties(SetObservable)
        Options = [];
        Results = [];
    end
    
    methods(Hidden=true)
        % default public constructor (only contains the name)
        function this = uq_analysis(name, type, varargin)
            
            % set the name of this analysis to the one specified
            this.Name = name;
            this.Type = type;
            % the core component is "analysis"
            this.core_component = 'analysis';
            
            % check the recursion level of varargin: if in the caller
            % workspace it was called 'varargin', it means we have to
            % un-nest it
            if nargin > 2
                if strcmp(inputname(3), 'varargin')
                    varargin = varargin{1};
                end
            end
            
            % now add the remaining command line arguments directly as
            % properties for later access
            for ii = 3:nargin
                % if we have at least 1 optional argument, we assume it is a
                % structure and add properties according to its fields
                if ii == 3 % the first argument
                    % those options will be added to the "Options" structure
                    if isstruct(varargin{1}) %only act if it is a structure
                        this.Options = varargin{1};
                        % get the field names
                        %fnames = fieldnames(varargin{1});
                        % and their number
                        %nfields = length(fnames);
                        
                        % now for each of them add a property to the module
                        % that reflects it
                        %for jj = 1:nfields
                            % set the property and its value
                        %    uq_addprop(this, fnames{jj}, varargin{1}.(fnames{jj}));
                            %this.addprop(fnames{jj});
                            %this.(fnames{jj}) = varargin{1}.(fnames{jj});
                        %end
                        
                        continue;
                    end
                else
                    this.Internal.ExtraOptions = varargin{ii};
                end
                
            end
            
        end
        
        % this function generates a sample of size N on the basis of the
        % requested properties
        function results = run(this, varargin) % runs the analysis on the currently selected input N times
            try
                if isempty(this.Results)
                    this.Results = eval([this.Type '(this)']);
                else
                    this.Results(this.results_idx) = eval([this.Type '(this)']);
                end
                % and now assign the output
                results = this.Results(this.results_idx);
                
                % and increment the results counter
                this.results_idx = this.results_idx + 1;
                
            catch me
                results = [];
                disp('Something went wrong while performing the analysis');
                disp('You may find additional information in the following exception message:');
                rethrow(me);
            end
        end
        
    end
end
