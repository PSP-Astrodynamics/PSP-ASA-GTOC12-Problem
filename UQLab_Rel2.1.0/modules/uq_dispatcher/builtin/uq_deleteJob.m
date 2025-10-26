function uq_deleteJob(DispatcherObj,jobIdx)
%UQ_DELETEJOB deletes a Job in a Dispatcher object.
%
%   uq_deleteJob(DISPATCHEROBJ,JOBIDX) deletes a Job in a Dispatcher object
%   DISPATCHEROBJ selected by its index JOBIDX (a scalar). Deleting a Job
%   removes all the remote files associated with the Job and the Job itself
%   from DISPATCHEROBJ. Only a finished Job can be deleted.
%
%   uq_deleteJob(DISPATCHEROBJ,JOBIDC) deletes multiple Jobs in a
%   Dispatcher object DISPATCHEROBJ selected by their indices JOBIDC
%   (a vector).

%% Parse and verify inputs

% Inputs are mandatory
if nargin == 1
    error('%s requires specifically refer to a Job by its index.')
end

% Jobs array should not be empty
if isempty(DispatcherObj.Jobs)
    warning('Jobs array in Dispatcher object %s is empty.',DispatcherObj.Name)
    return
end

% jobIdx must be consistent with the length of Jobs
if numel(DispatcherObj.Jobs) < max(jobIdx)
    error('Indices exceed Jobs array bounds!')
end

% Always sort the index in ascending order
jobIdx = sort(jobIdx);

%% Switch to different types of Dispatcher

dispatcherType = lower(DispatcherObj.Type);

switch dispatcherType
    case 'uq_default_dispatcher'
        uq_deleteJob_uq_default_dispatcher(DispatcherObj,jobIdx)
    otherwise
        error('Deleting a Job for Dispatcher Type *%s% is not supported!',...
            dispatcherType)
end

end
