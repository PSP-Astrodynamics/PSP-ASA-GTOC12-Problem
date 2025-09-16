function mhandle = uq_createInput(input_options, varargin)
% UQ_CREATEINPUT   create a UQLab INPUT object 
%    myInput = UQ_CREATEINPUT(INPUTOPTS) creates and stores in the current
%    UQLab session an object of type INPUT based on the configuration
%    options given in the INPUTOPTS structure. 
%
%    myInput = UQ_CREATEINPUT(INPUTOPTS, '-private') creates an object of
%    type INPUT based on the configuration options given in the INPUTOPTS
%    structure, without saving it in the UQLab session. This is useful,
%    e.g., in case of parametric studies which create a large number of
%    temporary INPUT objects that do not need to be stored in memory.
%
%    Example 1 (representation): create a 2-dimensional INPUT object with independent
%    uniform random variables in [-1,1]:
%       INPUTOPTS.Marginals(1).Type = 'Uniform';
%       INPUTOPTS.Marginals(1).Parameters = [-1 1];
%       INPUTOPTS.Marginals(2).Type = 'Uniform';
%       INPUTOPTS.Marginals(2).Parameters = [-1 1];
%       myInput = UQ_CREATEINPUT(INPUTOPTS);
%
%    To draw N samples from the resulting object use:
%       X = uq_getSample(N)
%
%    Example 2 (statistical inference): infer the marginals and copula of an
%    input from data X among supported parametric models.
%       INPUTOPTS.Inference.Data = X;
%       myInput = UQ_CREATEINPUT(INPUTOPTS);
%
%    For additional information about the available INPUTOPTS configuration
%    fields type: 
%       help <a href="matlab:uq_InputOptions">uq_InputOptions</a>
%       help <a href="matlab:uq_InputOptions">uq_RandomFieldOptions</a>
%
%    To open the INPUT User Manual or the INFERENCE User Manual, type:
%       <a href="matlab:uq_doc('Input')">uq_doc('Input')</a>
%       <a href="matlab:uq_doc('Inference')">uq_doc('Inference')</a>
%       <a href="matlab:uq_doc('RF')">uq_doc('RF')</a>
%
%    See also: uq_getInput, uq_listInputs, uq_selectInput, uq_getSample,
%              uq_createModel, uq_createAnalysis 
%

% return if no argument is given
if ~nargin
   error('No options given, cannot build input!');
end

% retrieve the necessary information
gw = uq_gateway.instance();


% we need to at least provide a set of options
if ~nargin
    error('please provide at least a configuration structure to the input model');
end

% First let's check if the model options are available and are a structure
if ~isstruct(input_options)
    error('The options given are not recognized as valid, bailing out');
end



%% Setting the default options and parsing the command line
type = 'uq_default_input';
% offset for the input names (when using inputname() to get the names of
% the input variables from the command line)
ioffset = 0;
%  now parsing the command line
parse_keys = {'Type'};
parse_types = {'f'};
% let's now parse the inputs first for any known option
[cl_options, res_fieldnames] = uq_simple_parser(fieldnames(input_options), parse_keys, parse_types);

% and use the parsed values
% first the input type:
if ~strcmp(cl_options{1}, 'false')
    type = input_options.Type;
end


% now let's check if a name was given. If it wasn't we create one now
if ~isfield(input_options, 'Name') || isempty(input_options.Name)
    nmodel = length(gw.input.available_modules);
    input_name = sprintf('Input %d', nmodel + 1);
else
    input_name = input_options.Name;
end


% let's now create the input module, by first expanding and then evaluating the  command
% line => this is necessary in order to keep the variable names in the objects and make
% them available as properties
str = 'mhandle = gw.input.add_module(input_name, type';

% so, first of all we add the model_options field to the model
Options = input_options;
str = [str ', Options'];


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