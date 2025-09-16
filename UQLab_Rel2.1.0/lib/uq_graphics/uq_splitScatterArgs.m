function [histArg, scatterArg, uqArg] = uq_splitScatterArgs(inputArg)
%% UQ_SPLITSCATTERARGS splits the provided input args according to a prefix
%   The arguments with prefix hist_ are assigned to HISTARG and those with
%   prefix scatter_ are assigned to SCATTERARG. Name arguments without prefix
%   are assigned to UQARG.

histArg = cell(2,0); scatterArg = cell(2,0); uqArg = cell(2,0);

% loop over inputArg and split
for ii = 1:2:length(inputArg)
    currName = inputArg{ii};
    currArg = inputArg{ii+1};
    if length(currName) > 5
        if strcmpi(currName(1:5),'hist_')
            % hist_ prefix - assign to histogram
            histArg(:,end+1) = {currName(6:end); currArg};
            continue
        end
    end
    if length(currName) > 8
        if strcmpi(currName(1:8),'scatter_')
        % scatter_ prefix - assign to scatter
            scatterArg(:,end+1) = {currName(9:end); currArg};
            continue
        end
    end
    
    % no prefix - assign to uqArg
    uqArg(:,end+1) = {currName;currArg};
end