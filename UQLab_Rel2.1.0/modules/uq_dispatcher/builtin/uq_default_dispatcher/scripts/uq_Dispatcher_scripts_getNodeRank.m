function nodeRank = uq_Dispatcher_scripts_getNodeRank(...
    scriptType, SchedulerVars, MPIVars, cpusPerNode)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if strcmpi(scriptType,'MATLAB')
    nodeRank = getNodeRankMATLAB(SchedulerVars, MPIVars, cpusPerNode);
elseif strcmpi(scriptType,'Bash')
    nodeRank = getNodeRankBash(SchedulerVars, MPIVars, cpusPerNode);
else
    error('Script type not supported!')
end

end

%% ------------------------------------------------------------------------
function nodeRank = getNodeRankMATLAB(SchedulerVars, MPIVars, cpusPerNode)

nodeRank = {};

% Get the node number from the environment variable
if strcmp(SchedulerVars.NodeNo,'0')
    nodeRank{end+1} = sprintf('nodeNo = %s;',SchedulerVars.NodeNo);
else
    nodeNo = strrep(SchedulerVars.NodeNo,'$','');
    nodeRank{end+1} = sprintf(...
        'nodeNo = str2double(getenv(''%s''));',nodeNo);
end

% Get the MPI current CPU Rank number from the environment variable
rankNo = strrep(MPIVars.RankNo,'$','');
nodeRank{end+1} = sprintf(...
    'rankNo = str2double(getenv(''%s''));',rankNo);

% Compute the current CPU index
% This index identifies a remote worker used in, for example,
% polling and merging results.
nodeRank{end+1} = sprintf(...
    'cpuIdx = nodeNo*%s + (rankNo+1);', num2str(cpusPerNode));
% Save the variable also as a char in 4 digits (padded with zero)
nodeRank{end+1} = sprintf('cpuIdxStr = sprintf(''%%.4d'',cpuIdx);');

nodeRank = sprintf('%s\n',nodeRank{:});

end

%% ------------------------------------------------------------------------
function nodeRank = getNodeRankBash(SchedulerVars,MPIVars,cpusPerNode)

nodeRank = {};

% Get the node number from the environment variable
nodeRank{end+1} = sprintf('nodeNo=%s',SchedulerVars.NodeNo);

% Get the MPI current CPU Rank number from the environment variable
nodeRank{end+1} = sprintf('rankNo=%s',MPIVars.RankNo);

% Compute the current CPU index
% This index identifies a remote worker used in, for example,
% polling and merging results.
nodeRank{end+1} = sprintf(...
    'cpuIdx=$((nodeNo*%s + rankNo + 1))', num2str(cpusPerNode));
% Save the variable also as a string with 4 digits (padded with zero)
nodeRank{end+1} = sprintf('cpuIdxStr=`printf "%%04d" $cpuIdx`');

nodeRank = sprintf('%s\n',nodeRank{:});

end
