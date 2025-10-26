function mhandle = uq_getModel(module)
% UQ_GETMODEL  retrieve a UQLab model from the current session
%    myModel = UQ_GETMODEL returns the currently selected MODEL object
%    myModel from the UQLab session.
%
%    myModel = UQ_GETMODEL(MODELNAME) returns the MODEL object with the
%    specified name MODELNAME, if it exists in the UQLab session.
%    Otherwise, it returns an error.
%    
%    myModel = UQ_GETMODEL(N) returns the Nth MODEL object stored in the
%    UQLab session.
%
%    To print a list of the currently existing models, their corresponding
%    numbers and the currently selected one, use the <a href="matlab:help uq_listModels">uq_listModels</a> command.
%
%    See also: uq_createModel, uq_evalModel, uq_listModels, uq_selectModel,
%              uq_getInput, uq_getAnalysis 
%

%% session retrieval
CORE_MODULE = 'model';

if ~nargin || isempty(module)
   mhandle = uq_retrieveSession(CORE_MODULE);
   return;
end

%% checking the input arguments
if ischar(module)
    mname = module;
    UQ = uq_retrieveSession('UQ');
elseif isa(module, 'uq_model')
    mhandle = module;
    return;
elseif isa(module, 'double') % a number if provided
    UQ = uq_retrieveSession('UQ');
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

