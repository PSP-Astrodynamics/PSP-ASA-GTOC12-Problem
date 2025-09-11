function uq_print_uq_default_model( module, varargin )
%UQ_PRINT_UQ_DEFAULT_MODEL prints out information regarding a model module
% 
% See also: UQ_EVAL_UQ_DEFAULT_MODEL


%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_default_model')
    error('uq_print_uq_default_model only operates on objects of type ''uq_default_model''')
end

%% PRINT
fprintf('-------------------------------------------\n')
fprintf('Model object name:\t%s\n', module.Name)

if isprop(module, 'mFile') && ~isempty(module.mFile) 
    fprintf('Defined by: \t\t%s (%s)\n', module.mFile,'m-file')
    fprintf('m-file location: \t%s\n', module.Internal.Location)
elseif isprop(module, 'mString') && ~isempty(module.mString) ;
    fprintf('Defined by: \t\t%s (%s)\n', module.mString,'m-string')
elseif isprop(module, 'mHandle') && ~isempty(module.mHandle) ;
    fprintf('Defined by: \t\t%s (%s)\n', func2str(module.mHandle),'m-handle')
else
    error('The given model object does not seem to be properly configured/initialized!')
end
% print model parameters
Para = module.Parameters;
% if the parameters are stored in a numeric vector/matrix
if isnumeric(Para)
    ll = length(size(Para));
    % print the parameters if they are saved in a matrix
    if ll<3
        fprintf('Parameters: \t\t[%s]\n', uq_sprintf_mat(Para));
        
    % otherwise, print only the dimension
    else
        str = regexprep(num2str(size(Para)), '  ', '×');
        fprintf('Parameters: \t\t%s\n', [num2str(ll),'-d array of size ',str]);
    end

% if the parameters are logical (boolean)
elseif islogical(module.Parameters)
    ll = length(size(Para));
    % print the parameters if they are saved in a matrix
    if ll<3
        fprintf('Parameters: \t\tlogical array [%s]\n', uq_sprintf_mat(Para,'%i'));
        
    % otherwise, print only the dimension    
    else
        str = regexprep(num2str(size(Para)), '  ', '×');
        fprintf('Parameters: \t\t%s\n', [num2str(ll),'-d logical array of size ',str]);
    end
    
% if the parameters are saved in a cell array, we only display its dimension
elseif iscell(Para)
    str = regexprep(num2str(size(Para)), '  ', '×');
    str = ['cell array of size ', str];
    fprintf('Parameters: \t\t%s\n',str);

% if the parameters are saved in a structure, we only display the name of the fields   
elseif isstruct(Para)
    str = fieldnames(Para);
    str = sprintf('%s, ',str{:});
    str(end-1:end)=[];
    str = ['structure with fields ', str];
    fprintf('Parameters: \t\t%s\n',str);

% for arbitrary types of the parameters, we only display its type (class)
else    
    fprintf('Parameters of type: %s\n', class(module.Parameters));
end

if module.isVectorized
    fprintf('Vectorized: \t\ttrue\n')
else
    fprintf('Vectorized: \t\tfalse\n')
end

if module.isStochastic
    fprintf('Stochastic: \t\ttrue\n')
    if module.stochasticSim.supportRep
        fprintf('SupportRep: \t\ttrue\n')
    else
        fprintf('SupportRep: \t\tfalse\n')
    end
    if module.stochasticSim.SeedControl
        fprintf('SeedControl: \t\ttrue\n')
    else
        fprintf('SeedControl: \t\tfalse\n')
    end
else
    fprintf('Stochastic: \t\tfalse\n')
end
fprintf('-------------------------------------------\n')
end