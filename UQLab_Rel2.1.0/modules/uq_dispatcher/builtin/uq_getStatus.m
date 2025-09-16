function [jobStatus,jobStatusID] = uq_getStatus(DispatcherObj,varargin)
%UQ_GETSTATUS gets the status of a Job(s) in a DISPATCHER unit.
%
%   JOBSTATUS = uq_getStatus(DISPATCHEROBJ) gets the status of the lastly
%   created Job in the DISPATCHEROBJ. The status will automatically be
%   updated with the current state of the Job in the remote machine.
%
%   JOBSTATUS = uq_getStatus(DISPATCHEROBJ,JOBIDX) gets the status of the
%   Job selected by its index JOBIDX.
%
%   JOBSTATUS = uq_getStatus(DISPATCHEROBJ,JOBIDC) gets the status of
%   multiple Jobs selected by their indices JOBIDC given as a vector.
%
%   JOBSTATUS = uq_getStatus(DISPATCHEROBJ,'-all') gets the status of all
%   Jobs associated with the Dispatcher object DISPATCHEROBJ.
%
%   jobStatus = uq_getStatus(DispatcherObj, NAME, VALUE) gets the status of
%   of Job(s) selected by uq_findJob helper function.
%
%   jobStatus = uq_getStatus(..., 'Update', false) gets the status of
%   Job(s) without updating it based on the current state of the Job in the
%   remote machine.
%
%   [jobStatus,jobStatusID] = uq_getStatus(...) also returns the integer
%   identification number of the status.
%
%   NOTE:
%   Updating the Status of a Job(s) will modify the DISPATCHER object
%   in-place.
%
%   See also UQ_UPDATESTATUS, UQ_FINDJOB.

%% Parse and verify inputs

% Get the number of Jobs in the DISPATCHER unit
numJobs = numel(DispatcherObj.Jobs);

% Check if there's a Job to update its status in the first place
if  numJobs == 0
    error('No Job is associated with DISPATCHER unit **%s**.',...
        DispatcherObj.Name)
end

% Check if the Job status needs to be updated
[updateStatus,varargin] = uq_parseNameVal(varargin, 'UpdateStatus', true);

% If no particular Job is specified, use the lastly created Job
if numel(varargin) == 0
    jobIdx = numJobs;
else
    % Multiple Job indices are given
    if isnumeric(varargin{1})
        jobIdx = varargin{1};
        allIndices = 1:numJobs;
        if ~all(ismember(jobIdx,allIndices))
            error('One or more specified jobIdx is out-of-bound.')
        end
        % Remove the index selection from varargin
    elseif strcmpi(varargin{1},'-all')
        % Select all associated Jobs
        jobIdx = 1:numJobs;
        % Remove the index selection from varargin
    else
        % Get the selected indices from findJob function
        [jobIdx,~] = uq_findJobs(DispatcherObj,varargin{:});
    end
    varargin = {};

    if isempty(jobIdx)
        error('No Job can be found.')
    end
    
end

% Throw warning if varargin is not exhausted
if ~isempty(varargin)
    warning('There is %s Name/Value argument pairs.',num2str(numel(varargin)))
end

%% Update the Job status (if asked)
if updateStatus
    uq_updateStatus(DispatcherObj,jobIdx)
end

%% Switch between different types of Dispatcher unit and get the status

dispatcherType = lower(DispatcherObj.Type);

switch dispatcherType
    case 'uq_default_dispatcher'
        if numel(jobIdx) > 1
            jobStatus = cell(numel(jobIdx),1);
            jobStatusID = zeros(numel(jobIdx),1);
            for i = 1:numel(jobIdx)
                [jobStatus{i},jobStatusID(i)] = ...
                    uq_getStatus_uq_default_dispatcher(DispatcherObj,jobIdx(i));
            end
        else
            [jobStatus,jobStatusID] = ...
                    uq_getStatus_uq_default_dispatcher(DispatcherObj,jobIdx);
        end
    
    otherwise
        error(...
            'Getting Job status for Dispatcher Type *%s* is not supported!',...
            dispatcherType)
end

end
