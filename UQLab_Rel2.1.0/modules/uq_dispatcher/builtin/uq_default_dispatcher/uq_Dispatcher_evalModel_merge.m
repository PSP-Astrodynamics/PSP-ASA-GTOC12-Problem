function varargout = uq_Dispatcher_evalModel_merge(parsedResults,mergeParams)


%% Parse and verify inputs
numOfOutArgs = mergeParams.NumOfOutArgs;
if nargout > numOfOutArgs
    error('Number of requested output arguments is larger than number of available output.')
end

%% Merge the results
mergedResults = cell(1,numOfOutArgs);

for i = 1:numOfOutArgs
    % It is assumed that the parsed results from 'uq_evalModel' is of
    % homogeneous data type. Therefore, they can be easily concatenated.
    mergedResults{i} = cellfun(@(c) c{i}, parsedResults,...
        'UniformOutput', false);
    mergedResults{i} = vertcat(mergedResults{i}{:});
end

%% Return the merged results
[varargout{1:nargout}] = mergedResults{1:nargout};

end
