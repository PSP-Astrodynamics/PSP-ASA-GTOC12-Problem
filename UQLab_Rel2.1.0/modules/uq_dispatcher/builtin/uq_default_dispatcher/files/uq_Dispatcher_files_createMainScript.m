function uq_Dispatcher_files_createMainScript(location,JobObj,DispatcherObj)
%UQ_DISPATCHER_FILES_CREATEMAINSCRIPT Summary of this function goes here

%   Detailed explanation goes here

%% Decide case
    
%% Create the content of main script
if strcmpi(JobObj.Task.Type,'uq_evalModel')
    % 1. uq_evalModel
    scriptMATLAB = uq_Dispatcher_scripts_createEvalModel(...
        JobObj,DispatcherObj);
    matlabFile = fullfile(...
        location,DispatcherObj.Internal.RemoteFiles.MATLAB);
    uq_Dispatcher_util_writeFile(matlabFile,scriptMATLAB)

elseif strcmpi(JobObj.Task.Type,'uq_map') && JobObj.Task.MATLAB
    
    % 2. uq_map (remote matlab)
    scriptMATLAB = uq_Dispatcher_scripts_createMapMATLAB(...
        JobObj,DispatcherObj);
    matlabFile = fullfile(...
        location,DispatcherObj.Internal.RemoteFiles.MATLAB);
    uq_Dispatcher_util_writeFile(matlabFile,scriptMATLAB)
    
elseif strcmpi(JobObj.Task.Type,'uq_map') && ~JobObj.Task.MATLAB

    % 3. uq_map (bash)
    scriptBash = uq_Dispatcher_scripts_createMapBash(...
        JobObj,DispatcherObj);
    bashFile = fullfile(...
        location,DispatcherObj.Internal.RemoteFiles.Bash);
    uq_Dispatcher_util_writeFile(bashFile,scriptBash)

else
    error('Unknown main script')
end

%% Write to a file
end
