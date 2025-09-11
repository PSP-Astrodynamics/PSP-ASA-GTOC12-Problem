function uq_listJobs(DispatcherObj,varargin)
%UQ_LISTJOBS lists the Jobs associated with a Dispatcher object.
%
%   UQ_LISTJOBS(DISPATCHEROBJ) lists the Jobs associated with the 
%   Dispatcher object DISPATCHEROBJ. By default, the status of each Job
%   will not be updated.
%
%   UQ_LISTJOBS(DISPATCHEROBJ,JOBIDX) lists the Jobs associated with
%   DISPATCHEROBJ selected by their index JOBIDX. By default, JOBIDX is
%   '-all', that is, all associated Jobs are selected.
%
%   UQ_LISTJOBS(..., 'UpdateStatus', true) list the Jobs associated with
%   DISPATCHEROBJ after updating each of their status on the remote
%   machine.
%
%   See also UQ_PRINT.

%% Parse and Verify Inputs

if nargin < 1
    current_dispatcher = uq_getDispatcher;
else
    if ~isa(DispatcherObj,'uq_dispatcher')
        error('%s only applies to a Dispatcher unit!',mfilename)
    end
    current_dispatcher = DispatcherObj;
end

if ~isprop(current_dispatcher,'Jobs') || isempty(current_dispatcher.Jobs)
    error('No job associated with the Dispatcher object!')
end

% Update status
[updateStatus,varargin] = uq_parseNameVal(varargin, 'UpdateStatus', false);

numJobs = numel(current_dispatcher.Jobs);
if numel(varargin) > 1
    if isnumeric(varargin{1})
        jobIdc = varargin{1};
    elseif strcmpi(varargin{1},'-all')
        jobIdc = 1:numJobs;
    else
        jobIdc = uq_findJobs(DispatcherObj,varargin{:});
    end
    varargin = {};
else
    jobIdc = 1:numJobs;
end

% Throw warning if varargin is not exhausted
if ~isempty(varargin)
    warning('There is %s Name/Value argument pairs.',num2str(numel(varargin)))
end

%% Update the status of the selected Jobs
if updateStatus
    for i = jobIdc
        uq_updateStatus(current_dispatcher,i)
    end
end

%% Compute the Maximum Column Width
jobIDColWidthMax = max(max_columnWidth({current_dispatcher.Jobs.JobID}),6);
statusChar = uq_map(@(i) uq_getStatusChar(current_dispatcher.Jobs(i).Status),...
    1:numel(current_dispatcher.Jobs));
statusColWidthMax = max_columnWidth(statusChar);
remoteFolderColWidthMax = ...
    max_columnWidth({current_dispatcher.Jobs.RemoteFolder});
finishDateTimeColWidthMax = ...
    max(max_columnWidth({current_dispatcher.Jobs.FinishDateTime}),...
    numel('Finish Date Time (UTC)'));
tagColWidthMax = max_columnWidth({current_dispatcher.Jobs.Tag});
numColWidthMax = max(length(num2str(numJobs)),3);

% Sum and add 6 additional spaces in between column elements
colWidthMax = jobIDColWidthMax + statusColWidthMax ...
    + remoteFolderColWidthMax + finishDateTimeColWidthMax ...
    + tagColWidthMax + numColWidthMax + 8;

%% Print Job-relevant Information

headers = {'No.', 'Job ID', 'Status', 'Tag', 'Finish Date Time (UTC)', 'Remote Folder'};

% Print Dispatcher Name
fprintf('\nDispatcher Object: %s\n\n',current_dispatcher.Name)

% Print Header
headerFmt = sprintf('%%%ds  %%-%ds  %%-%ds  %%-%ds  %%-%ds  %%-%ds\n',...
    numColWidthMax,...
    jobIDColWidthMax,...
    statusColWidthMax,...
    tagColWidthMax,...
    finishDateTimeColWidthMax,...
    remoteFolderColWidthMax);
fprintf(headerFmt,headers{:});
fprintf('%s\n',repmat('-',1,colWidthMax));

if isempty(jobIdc)
    fprintf('No job found\n')
else
    for jobIdx = jobIdc
        Job = current_dispatcher.Jobs(jobIdx);
        infoLine = {num2str(jobIdx),...
            Job.JobID,...
            uq_getStatusChar(Job.Status),...
            Job.Tag,...
            Job.FinishDateTime,...
            Job.RemoteFolder};
        fprintf(headerFmt, infoLine{:});
    end
end

fprintf('\n');

end


%% ------------------------------------------------------------------------
function maxColWidth = max_columnWidth(cellInput)

maxColWidth = max(cellfun(@length,cellInput));

end
