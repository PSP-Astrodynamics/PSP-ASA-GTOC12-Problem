function uq_Dispatcher_files_createMPI(location, JobObj, DispatcherObj)
%UQ_DISPATCHER_FILES_CREATEMPI Summary of this function goes here
%   Detailed explanation goes here

scriptMPI = uq_Dispatcher_scripts_createMPI(JobObj,DispatcherObj);
mpiFile = fullfile(location,DispatcherObj.Internal.RemoteFiles.MPI);
uq_Dispatcher_util_writeFile(mpiFile,scriptMPI);

end
