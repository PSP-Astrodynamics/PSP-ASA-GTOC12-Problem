function uq_updateStatus(DispatcherObj,jobIdx)
%UQ_UPDATESTATUS updates the status of a Job.
%
%   uq_updateStatus(DISPATCHEROBJ) updates the status of the lastly created
%   Job associated with a Dispatcher object DISPATCHEROBJ based on the
%   current of the Job in the remote machine. The update on DISPATCHEROBJ
%   happens in-place (i.e., as a side effect).
%
%   uq_updateStatus(DISPATCHEROBJ,JOBIDX) updates the status of the Job
%   selected by its index JOBIDX.
%
%   uq_updateStatus(DISPATCHEROBJ,JOBIDC) updates the status of multiple
%   Jobs selected by their indices JOBIDC given as a vector.
%
%   uq_updateStatus(DISPATCHEROBJ,'-all') updates the status of all Jobs
%   associated with a Dispatcher object DISPATCHEROBJ.
%
%   NOTE:
%   The update on DISPATCHEROBJ happens in-place (i.e., as a side effect).
%   The function does not return any value.
%
%   See also uq_getStatus.

%% Parse and verify inputs
if nargin > 2
    error('Too many inputs.')
end

% No Job index is given, take the lastly created Job
if nargin == 1
    jobIdx = numel(DispatcherObj.Jobs);
end

% Get the number of Jobs in the DISPATCHER unit
numJobs = numel(DispatcherObj.Jobs);

% Multiple Job indices are given
if nargin == 2
    if isnumeric(jobIdx)
        allIndices = 1:numJobs;
        if ~all(ismember(jobIdx,allIndices))
            error('One or more specified jobIdx is out-of-bound.')
        end
    end
    
    if strcmpi(jobIdx,'-all')
        jobIdx = 1:numJobs;
    end
end

%% Switch to different types of Dispatcher object
switch lower(DispatcherObj.Type)
    case 'uq_default_dispatcher'
        for idx = jobIdx
            uq_updateStatus_uq_default_dispatcher(DispatcherObj,idx)
        end
    otherwise
        error(['Status update for a Job of Dispatcher Type *%s* ',...
            'is not supported!'],...
            DispatcherObj.Type)
end

end
