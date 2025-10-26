function uq_submitJob(DispatcherObj,jobIdx)
%UQ_SUBMITJOB submits a Job for execution to the remote machine.
%
%   UQ_SUBMITJOB(DISPATCHEROBJ,JOBIDX) submits a Job in a Dispatcher object
%   DISPATCHEROBJ selected by its index JOBIDX to the remote machine.
%   Only one Job can be submitted at a time and its status must be
%   'pending'. Submitting a Job modifies the selected Job in DISPATCHEROBJ
%   in-place.

%% Parse and verify inputs
if nargin < 2
    jobIdx = numel(DispatcherObj.Jobs);
end

%% Switch to different types of Dispatcher
switch lower(DispatcherObj.Type)
    case 'uq_default_dispatcher'
        uq_submitJob_uq_default_dispatcher(DispatcherObj,jobIdx)
    otherwise
        error('Job submission for Dispatcher type *%s* is not supported!',...
            DispatcherObj.Type)
end

end
