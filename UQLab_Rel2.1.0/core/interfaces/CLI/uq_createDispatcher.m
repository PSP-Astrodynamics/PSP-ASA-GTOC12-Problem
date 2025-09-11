function dhandle = uq_createDispatcher(dispatcher_options, varargin)
%UQ_CREATEDISPATCHER creates a UQLab DISPATCHER object.
%
%   myDispatcher = UQ_CREATEDISPATCHER(DISPATCHEROPTS) creates and stores
%   in the current UQLab session an object of type DISPATCHER based on the
%   configuration options given in the DISPATCHEROPTS structure. 
%
%   myDispatcher = UQ_CREATEDISPATCHER(DISPATCHEROPTS,'-private') creates
%   an object of type DISPATCHER based on the configuration options given
%   in the DISPATCHEROPTS structure, without storing it in the current 
%   UQLab session.
%
%   Note that dispatching a MODEL evaluation using <a
%   href="matlab:uq_evalModel">uq_evalModel</a> cannot be
%   carried out using a 'private' DISPATCHER object.
%
%   For more details about specifying the configuration options, please
%   refer to <a href="matlab:uq_DispatcherOptions">uq_DispatcherOptions</a>.
%
%   See also uq_DispatcherOptions, uq_getDispatcher, uq_listDispatchers,
%            uq_createModel, uq_createInput, uq_createAnalysis, uq_doc.

% return if no argument is given
if ~nargin
   error('No options given, cannot build dispatcher!');
end

% retrieve the necessary information
gw = uq_gateway.instance();

% First let's check if the model options are available and are a structure

if ~isstruct(dispatcher_options) 
    error('The options given are not recognized as valid, bailing out');
end

% assume by default it's a default_dispatcher
type = 'uq_default_dispatcher'; % the default dispatcher type

% and overwrite if needed
if isfield(dispatcher_options, 'Type')
    type = dispatcher_options.Type;
end



% now let's check if a name was given. If it wasn't we create one now
if ~isfield(dispatcher_options, 'Name') || isempty(dispatcher_options.Name)
    ndispatchers = length(gw.dispatcher.available_modules);
    dispatcher_name = sprintf('Dispatcher %d', ndispatchers); % note: dispatchers start from 0, as the first dispatcher is empty and is always createds
else
    dispatcher_name = dispatcher_options.Name;
end

% let's now create the dispatcher module, by first expanding and then evaluating the  command
% line => this is necessary in order to keep the variable names in the objects and make
% them available as properties

% only assign output argument if requested
if nargout 
    str = 'dhandle = ';
else
    str = 'dummy = ';
end

str = [str 'gw.dispatcher.add_module(dispatcher_name, type'];

% so, first of all we add the model_options field to the model
Options = dispatcher_options;
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
