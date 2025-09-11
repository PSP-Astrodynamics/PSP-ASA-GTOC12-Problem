function varargout = uq_Dispatcher_map_merge(parsedResults,mergeParams)
%UQ_DISPATCHER_MAP_MERGE merges the parsed mapping results and reconstruct
%   the output such that it conforms with the shape of the input.

%% Set local variables
inputSize = mergeParams.InputSize;
numOfOutArgs = mergeParams.NumOfOutArgs;

%% Merge the results
if numOfOutArgs > 1
    mergedResults = cell(1,numOfOutArgs);
    for i = 1:numOfOutArgs
        mergedResults{i} = cell(inputSize);
        % Combine a given output output from all parallel processes
        output = arrayfun(...
            @(j) parsedResults{j}{i},...
            1:numel(parsedResults),...
            'UniformOutput', false);
        % Reshape the output according to the shape of the input
        mergedResults{i} = reshape(vertcat(output{:}),inputSize);
    end
    [varargout{1:nargout}] = mergedResults{1:nargout};
else
    % If no multiple outputs, simply concatenate the cell arrays vertically
    mergedResults = vertcat(parsedResults{:});
    mergedResults = vertcat(mergedResults{:});
    mergedResults = reshape(mergedResults,inputSize);
    varargout{1} = mergedResults;
end

end
