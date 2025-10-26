function jobIdx = uq_createJob(JobDef,DispatcherObj)
%UQ_CREATEJOB creates a local Job folder structure.
%
%   UQ_CREATEJOB(DISPATCHEROBJ) creates a new Job inside the Dispatcher
%   unit DISPATCHEROBJ. The new Job has a status 'pending', ready for
%   submission in the remote machine. DISPATCHEROBJ is updated in-place.
%
%   JOBIDX = UQ_CREATEJOB(...) returns the index of the new Job.
%
%   See also UQ_SUBMITJOB.

%% Parse and verify inputs

switch lower(DispatcherObj.Type)
    case 'uq_default_dispatcher'
        jobIdx = uq_createJob_uq_default_dispatcher(JobDef,DispatcherObj);
    otherwise
        error('Creating a Job for Dispatcher Type *%s* is not supported!',...
            DispatcherObj.Type)
end

end
