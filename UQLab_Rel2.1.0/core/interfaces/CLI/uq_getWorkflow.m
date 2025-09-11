function mhandle = uq_getWorkflow(module)
% UQ_SELECT_MODEL(MODEL) makes the specified model current in UQLab. MODEL can be both a
% string ID, or a uq_model object.
% MHANDLE = UQ_SELECT_MODEL(MODEL) also returns the selected object handle

%% session retrieval
CORE_MODULE = 'workflow';

if ~nargin
   mhandle = uq_retrieveSession(CORE_MODULE);
   return;
end

UQ = uq_retrieveSession('UQ');
%% checking the input arguments
if ischar(module)
    mname = module;
elseif isa(module, 'uq_workflow')
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
