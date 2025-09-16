function [jobStatus,jobStatusID] = uq_getStatus_uq_default_dispatcher(...
    DispatcherObj,jobIdx)
%UQ_GETSTATUS returns the status of a Job as char and numerical ID.

jobStatusID = DispatcherObj.Jobs(jobIdx).Status;
jobStatus = uq_getStatusChar(jobStatusID);

end
