function ihandle = uq_getInput(module)
% UQ_GETINPUT   retrieve a UQLab INPUT object from the current session.
%    myInput = UQ_GETINPUT returns the currently selected INPUT object
%    myInput from the UQLab session.
%
%    myInput = UQ_GETINPUT(INPUTNAME) returns the INPUT object with the
%    specified name INPUTNAME, if it exists in the UQLab session.
%    Otherwise, it returns an error.
%    
%    myInput = UQ_GETINPUT(N) returns the Nth INPUT object stored in the
%    UQLab session.
%
%    To print a list of the currently existing INPUT objects, their 
%    numbers and the currently selected one, use the <a href="matlab:help uq_listInputs">uq_listInputs</a> command.
%
%    See also: uq_createInput, uq_listInputs, uq_selectInput, uq_getSample,
%              uq_getModel, uq_getAnalysis 
%

%% session retrieval
CORE_MODULE = 'input';

if ~nargin || isempty(module)
   ihandle = uq_retrieveSession(CORE_MODULE);
   return;
end

UQ = uq_retrieveSession('UQ');
%% checking the input arguments
if ischar(module)
    mname = module;
elseif isa(module, 'uq_input')
    ihandle = module;
    return;
elseif isa(module, 'double') % a number if provided
    if module <= length(UQ.(CORE_MODULE).modules)
        mname = UQ.(CORE_MODULE).modules{module}.Name;
    else
        error('The specified input does not exist');
    end
else
    error('The MODULE argument must be either a string or an object!')
end


ihandle = UQ.(CORE_MODULE).get_module(mname);
if isempty(ihandle)
    error('The specified input does not exist');
end

% remove the output if it is not returned
if ~nargout
    clear('ihandle');
end
