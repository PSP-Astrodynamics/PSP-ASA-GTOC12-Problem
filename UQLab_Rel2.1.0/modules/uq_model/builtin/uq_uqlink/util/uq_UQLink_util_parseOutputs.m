function parsedOutputs = uq_UQLink_util_parseOutputs(...
    outputFiles, outputParser, numOfOutArgs)
%UQ_UQLINK_UTIL_PARSEOUTPUTS parses the output files.
%
%   Inputs
%   ------
%   - outputFiles: list of output files, cell array
%   - outputParser: function used to parse the output files, handle
%   - numOfOutArgs: number of output arguments, scalar integer
%
%   Outputs
%   -------
%   - parsedOutputs: the results from parsing, cell array
%       the number of elements in this cell array is the same as the number
%       of elements in the 'outputFiles' cell array. Each element may
%       contain a multidimensional array.

%% Verify inputs
if ~iscell(outputFiles)
    outputFiles = {outputFiles};
end

%% Parse the output files
parsedOutputs = cell(1,numOfOutArgs);

% Always store the parsed outputs in a cell array. If there are multiple
% are multiple output files, then there are multiple number of elements in
% the cell array.
if length(outputFiles) == 1
    [parsedOutputs{1:numOfOutArgs}] = outputParser(outputFiles{1});
else
    [parsedOutputs{1:numOfOutArgs}] = outputParser(outputFiles);
end
             
end
