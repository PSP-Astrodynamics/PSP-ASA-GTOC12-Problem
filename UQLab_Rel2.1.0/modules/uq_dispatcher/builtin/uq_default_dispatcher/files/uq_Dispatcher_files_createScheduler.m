function uq_Dispatcher_files_createScheduler(location, JobObj, DispatcherObj)
%UQ_DISPATCHER_FILES_CREATESCHEDULER Summary of this function goes here
%   Detailed explanation goes here

schedulerScript = uq_Dispatcher_scripts_createScheduler(...
    JobObj,DispatcherObj);
schedulerFile = fullfile(...
    location,DispatcherObj.Internal.RemoteFiles.JobScript);
uq_Dispatcher_util_writeFile(schedulerFile,schedulerScript);

end

