function mhandle = uq_createModel(model_options, varargin)
% UQ_CREATEMODEL  create a UQLab MODEL object. 
%    myModel = UQ_CREATEMODEL(MODELOPTS) creates and stores in the current
%    UQLab session an object of type MODEL based on the configuration
%    options given in the MODELOPTS structure. 
%
%    myModel = UQ_CREATEMODEL(MODELOPTS, '-private') creates an object of
%    type MODEL based on the configuration options given in the MODELOPTS
%    structure, without saving it in the UQLab session. This is useful,
%    e.g., in case of adaptive algorithms which create a large number of
%    temporary MODEL objects that do not need to be stored in memory.
%
%    For more details about the available MODEL types, please refer to
%    model-specific initialization: 
%       help <a href="matlab:uq_ModelOptions">uq_ModelOptions</a>      - Computational model (e.g. MATLAB functions)
%       help <a href="matlab:uq_PCEOptions">uq_PCEOptions</a>        - Polynomial Chaos Expansion metamodel options
%       help <a href="matlab:uq_KrigingOptions">uq_KrigingOptions</a>    - Kriging metamodel options
%       help <a href="matlab:uq_PCKOptions">uq_PCKOptions</a>        - Polynomial Chaos Kriging metamodel options
%       help <a href="matlab:uq_LRAOptions">uq_LRAOptions</a>        - Low Rank Approximations metamodel options
%       help <a href="matlab:uq_SSEOptions">uq_SSEOptions</a>        - Stochastic Spectral Embedding options
%       help <a href="matlab:uq_SVCOptions">uq_SVCOptions</a>        - Support Vector Classification options
%       help <a href="matlab:uq_SVROptions">uq_SVROptions</a>        - Support Vector Regression options
%       help <a href="matlab:uq_UQLinkOptions">uq_UQLinkOptions</a>     - UQLink options
%
%    See also: uq_ModelOptions, uq_evalModel, uq_getModel, uq_listModels,
%              uq_selectModel, uq_createInput, uq_createAnalysis, uq_doc
%
%  - Stefano Marelli (marelli@ibk.baug.ethz.ch)

% return if no argument is given
if ~nargin
   error('No options given, cannot build model!');
end

% retrieve the necessary information
gw = uq_gateway.instance(); 

% let's now create the models, by first expanding and then evaluating the  command
% line => this is necessary in order to keep the variable names in the objects and make
% them available as properties

% First let's check if the model options are available and are a structure

if ~isstruct(model_options)
    error('The options given are not recognized as a valid structure, bailing out');
end

% assign the model type
type = 'uq_default_model'; % the default model type

if isfield(model_options, 'Type')
    type = model_options.Type;
end





% now let's check if a name was given. If it wasn't we create one now
if ~isfield(model_options, 'Name') || isempty(model_options.Name)
    nmodel = length(gw.model.available_modules);
    model_name = sprintf('Model %d', nmodel + 1);
else
    model_name = model_options.Name;
end

% if the input is a lone structure, we assume its fields need to be parsed, otherwise we
% assume each input argument is a property to add to the model

% only assign output argument if requested
if nargout 
    str = 'mhandle = ';
else
    str = 'dummy = ';
end

str = [str ' gw.model.add_module(model_name, type'];

% so, first of all we add the model_options field to the model
Options = model_options;
str = [str ', Options'];

% and finally let's process the remaining variables (optional)

for ii = 1:length(varargin)
    %     if  length(varargin) == 1  && isstruct(varargin{1})
    %         fnames = fieldnames(varargin{ii});
    %         for jj = 1:length(fnames)
    %             eval([fnames{jj} ' =  varargin{ii}.(fnames{jj});']);
    %             str = [str ', ' fnames{jj}];
    %         end
    %     else
    iname = inputname(ii+1);
    if ~isempty(iname)
        eval([iname ' =  varargin{ii};']);
        str = [str ', ' iname];
    else
        str = [str ', ''' varargin{ii} ''''];
    end
end



str = [str ');'];

% now execute the command and add the model to the existing 
eval(str);
%evalin('caller', 'uq_retrieveSession;')
