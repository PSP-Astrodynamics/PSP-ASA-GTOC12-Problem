function [jobIdx,Job] = uq_findJobs_uq_default_dispatcher(...
    DispatcherObj, JobRef, operator)
%UQ_FINDJOB_UQ_DEFAULT_DISPATCHER finds a Job(s) according to the values of
%   its properties for default dispatcher type.

%% Set local variables
Jobs = DispatcherObj.Jobs;

% Get the fieldnames from JobRef struct for supported property names
propNames = fieldnames(JobRef);

% Property Names with regexp support
propNamesRegexp = {'Name', 'Tag', 'SubmitDateTime', 'StartDateTime',...
    'FinishDateTime', 'RunningDuration', 'QueueDuration'};

%%
filteredPropNames = propNames;
for i = 1:numel(propNames)
    if isempty(JobRef.(propNames{i}))
        filteredPropNames = setdiff(filteredPropNames,propNames{i});
    end
end
if isempty(filteredPropNames)
    jobIdx = 1:numel(Jobs);
    Job = Jobs(jobIdx);
    return
end
    
%% Find Job(s)
propNamesExact = setdiff(propNames,propNamesRegexp);
jobIdx1 = getJobExactProp(Jobs, JobRef, propNamesExact, operator);
jobIdx2 = getJobRegexpProp(Jobs, JobRef, propNamesRegexp, operator);

if strcmpi(operator,'and')
    jobIdx = intersect(jobIdx1,jobIdx2);
else
    jobIdx = union(jobIdx1,jobIdx2);
end

Job = Jobs(jobIdx);

if iscolumn(jobIdx)
    jobIdx = transpose(jobIdx);
end

end


%% ------------------------------------------------------------------------
function jobIdx = getJobExactProp(Jobs, JobRef, propNames, operator)

filteredPropNames = propNames;
for i = 1:numel(propNames)
    if isempty(JobRef.(propNames{i}))
        filteredPropNames = setdiff(filteredPropNames,propNames{i});
    end
end

% Loop over remaining properties used to find Job(s)
for i = 1:numel(filteredPropNames)

%     if ~iscell(JobRef.(filteredPropNames{i}))
%         JobRef.(filteredPropNames{i}) = {JobRef.(filteredPropNames{i})};
%     end

    JobIdx.(filteredPropNames{i}) = [];
    for j = 1:numel(Jobs)
%        for k = 1:numel(JobRef.(filteredPropNames{i}))
            if isequal(Jobs(j).(filteredPropNames{i}),JobRef.(filteredPropNames{i}))
                JobIdx.(filteredPropNames{i}) = [JobIdx.(filteredPropNames{i}) j];
            end
%        end
    end
end

% Return the output
if strcmpi(operator,'and')
    jobIdx = 1:numel(Jobs);
    for i = 1:numel(filteredPropNames)
        % Return only the intersection between matching indices
        jobIdx = intersect(jobIdx,JobIdx.(filteredPropNames{i}));
    end
else
    jobIdx = [];
    for i = 1:numel(filteredPropNames)
        % Return only the intersection between matching indices
        jobIdx = union(jobIdx,JobIdx.(filteredPropNames{i}));
    end
end

% if jobIdx becomes empty, make it a 0-by-0 array
if isempty(jobIdx)
    jobIdx = [];
end    

end


%% ------------------------------------------------------------------------
function jobIdx = getJobRegexpProp(Jobs, JobRef, propNames, operator)

filteredPropNames = propNames;
for i = 1:numel(propNames)
    if isempty(JobRef.(propNames{i}))
        filteredPropNames = setdiff(filteredPropNames,propNames{i});
    end
end

% Loop over remaining properties used to find Job(s)
for i = 1:numel(filteredPropNames)
    JobIdx.(filteredPropNames{i}) = [];
    for j = 1:numel(Jobs)
        if any(regexpi(Jobs(j).(filteredPropNames{i}),JobRef.(filteredPropNames{i})))
            JobIdx.(filteredPropNames{i}) = [JobIdx.(filteredPropNames{i}) j];
        end
    end
end

% Return the output
if strcmpi(operator,'and')
    jobIdx = 1:numel(Jobs);
    for i = 1:numel(filteredPropNames)
        % Return only the intersection between matching indices
        jobIdx = intersect(jobIdx,JobIdx.(filteredPropNames{i}));
    end
else
    jobIdx = [];
    for i = 1:numel(filteredPropNames)
        % Return only the intersection between matching indices
        jobIdx = union(jobIdx,JobIdx.(filteredPropNames{i}));
    end
end

% if jobIdx becomes empty, make it a 0-by-0 array
if isempty(jobIdx)
    jobIdx = [];
end

end
