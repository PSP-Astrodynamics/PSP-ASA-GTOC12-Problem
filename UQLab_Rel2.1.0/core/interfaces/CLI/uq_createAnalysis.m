function mhandle = uq_createAnalysis(analysis_options, varargin)
% UQ_CREATEANALYSIS   create a UQLab ANALYSIS object.
%    myAnalysis = UQ_CREATEANALYSIS(ANALYSISOPTS) creates and stores in the
%    current UQLab session an object of type ANALYSIS based on the configuration
%    options given in the ANALYSISOPTS structure. 
%
%    myAnalysis = UQ_CREATEANALYSIS(ANALYSISOPTS, '-private') creates an
%    object of type ANALYSIS based on the configuration options given in
%    the ANALYSISOPTS structure, without saving it in the UQLab session.
%    This is useful, e.g., in parametric studies which create a large
%    number of temporary ANALYSIS objects that do not need to be stored in
%    memory. 
%
%    For more details about the available model types, please refer to
%    analysis-specific initialization: 
%       help <a href="matlab:uq_ReliabilityOptions">uq_ReliabilityOptions</a> - Reliability analysis (rare events estimation)
%       help <a href="matlab:uq_SensitivityOptions">uq_SensitivityOptions</a> - Sensitivity analysis
%       help <a href="matlab:uq_InversionOptions">uq_InversionOptions</a>   - Bayesian inversion options
%       help <a href="matlab:uq_RBDOOptions">uq_RBDOOptions</a>        - Reliability-based optimization options
%
%    See also: uq_getAnalysis, uq_listAnalyses, uq_selectAnalysis,
%              uq_createInput, uq_createModel,  uq_doc
%



% return if no argument is given
if ~nargin
   error('No options given, cannot build analysis!');
end

% retrieve the necessary information
gw = uq_gateway.instance();

% First let's check if the model options are available and are a structure
if ~isstruct(analysis_options) || ~isfield(analysis_options, 'Type')
    error('The options given are not recognized as valid, bailing out');
end

% assign the model type
type = analysis_options.Type;


% now let's check if a name was given. If it wasn't we create one now
if ~isfield(analysis_options, 'Name') || isempty(analysis_options.Name)
    nmodel = length(gw.analysis.available_modules);
    analysis_name = sprintf('Analysis %d', nmodel + 1);
else
    analysis_name = analysis_options.Name;
end

% let's now create the input module, by first expanding and then evaluating the  command
% line => this is necessary in order to keep the variable names in the objects and make
% them available as properties

% only assign output argument if requested
if nargout 
    str = 'mhandle = ';
else
    str = 'dummy = ';
end

str = [str 'gw.analysis.add_module(analysis_name, type'];

% so, first of all we add the model_options field to the model
Options = analysis_options;
str = [str ', Options'];

% and finally we process the remaining variables (optional)
for ii = 1:length(varargin)
    iname = inputname(ii+1);
    if ~isempty(iname)
        eval([iname ' =  varargin{ii};']);
        str = [str ', ' iname];
    else
        str = [str ', ''' varargin{ii} ''''];
    end
end
    
str = [str ');'];

% now evaluate the string to actually add the input to UQLab
eval(str);

% and finally update the variables in the caller workspace (in case we didn't do it
% earlier)
%evalin('caller', 'uq_retrieveSession;')
