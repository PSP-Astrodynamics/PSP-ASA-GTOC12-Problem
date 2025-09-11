function nodeRankWorld = uq_Dispatcher_matlab_getNodeRankWorld(SchedulerVars,cpuPerNode)
%UQ_DISPATCHER_MATLAB_GETNODERANKWORLD get the node number, rank number,
%   and world size. It also includes the cpuIdx both as integer and char. 

nodeRankWorld = {};

%% Get the node number from the environment variable
if strcmp(SchedulerVars.NodeNo,'0')
    nodeRankWorld{end+1} = sprintf('nodeNo = %s;',SchedulerVars.NodeNo);
else
    nodeNo = strrep(SchedulerVars.NodeNo,'$','');
    nodeRankWorld{end+1} = sprintf(...
        'nodeNo = str2double(getenv(''%s''));',nodeNo);
end

% Get the MPI current CPU Rank number from the environment variable
rankNo = strrep(SchedulerVars.RankNo,'$','');
nodeRankWorld{end+1} = sprintf(...
    'rankNo = str2double(getenv(''%s''));',rankNo);

% Get the MPI World Size from the environment variable
worldNo = strrep(SchedulerVars.WorldNo,'$','');
nodeRankWorld{end+1} = sprintf(...
    'worldNo = str2double(getenv(''%s''));',worldNo);

% Compute the current CPU index used to identify remote worker.
% Depending on how nodes are treated, the ID is computed using
% the local rank above shifted by the node.
nodeRankWorld{end+1} = sprintf(...
    'cpuIdx = nodeNo*%s + (rankNo+1);', num2str(cpuPerNode));
% Save the variable also as a char in 4 digits (padded with zero)
nodeRankWorld{end+1} = sprintf('cpuIdxStr = sprintf(''%%.4d'',cpuIdx);');

nodeRankWorld = [sprintf('%s\n',nodeRankWorld{1:end-1}),nodeRankWorld{end}];

end
