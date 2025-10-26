function SUCCESS = uq_removeModule(mname,core_module)
% UQ_REMOVEMODULE(MNAME,COREMODULE) remove the module with identifier MNAME
% from the core module specified in COREMODULE 


% Retrieve the core module
UQ = uq_retrieveSession('UQ');

% Remove the specified module
try
    UQ.(core_module).remove_module(mname);
    SUCCESS = 1;
catch me
    SUCCESS = 0;
end
