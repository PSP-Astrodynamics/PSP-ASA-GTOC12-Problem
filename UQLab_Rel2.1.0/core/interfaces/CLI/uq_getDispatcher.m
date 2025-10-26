function mhandle = uq_getDispatcher(module)
% UQ_GETDISPATCHER retrieves a DISPATCHER object from the UQLab session.
%   
%   myDispatcher = UQ_GETDISPATCHER returns the currently selected 
%   DISPATCHER object from the UQLab session.
%
%   myDispatcher = UQ_GETDISPATCHER(DISPATCHERNAME) returns the DISPATCHER
%   object with the specified name DISPATCHERNAME, if it exists in the
%   UQLab session. Otherwise, it returns an error.
%    
%   myDispatcher = UQ_GETDISPATCHER(N) returns the Nth DISPATCHER object
%   stored in the UQLab session. Note that, the 1st DISPATCHER object is
%   the 'empty' DISPATCHER object.
%
%   To print a list of the currently existing DISPATCHER object in the
%   UQLab session, their corresponding numbers and the currently selected
%   one, use the <a href="matlab:help uq_listDispatchers">uq_listDispatchers</a> command.
%
%   See also uq_createDispatcher, uq_listDispatchers, uq_selectDispatcher.

%% session retrieval
CORE_MODULE = 'dispatcher';

if ~nargin || isempty(module)
   mhandle = uq_retrieveSession(CORE_MODULE);
   return;
end

UQ = uq_retrieveSession('UQ');
%% checking the input arguments
if ischar(module)
    mname = module;
elseif isa(module, 'uq_dispatcher')
    mname = module.Name;
elseif isa(module, 'double') % a number if provided
    if module <= length(UQ.(CORE_MODULE).modules)
        mname = UQ.(CORE_MODULE).modules{module}.Name;
    else
        error('The specified model does not exist');
    end
else
    error('The MODULE argument must be either a string or an object!')
end


mhandle = UQ.(CORE_MODULE).get_module(mname);
if isempty(mhandle)
    error('The specified model does not exist');
end

% remove the output if it is not returned
if ~nargout
    clear('mhandle');
end
