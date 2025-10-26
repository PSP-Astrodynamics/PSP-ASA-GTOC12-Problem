function outputs = uq_UQLink_util_returnNaN(outputSizes)
%UQ_UQLINK_UTIL_RETURNNAN returns NaN cell array of a given dimensions.
%
%   Inputs
%   ------
%   - outputSizes: the size/dimension of each output, vector
%       each element of outputSizes determines the number of row for each
%       element of the outputs.
%
%   Output
%   ------
%   - outputs: outputs with NaN values, cell array

outputs = arrayfun(@(x) NaN * ones(1,x), outputSizes,...
    'UniformOutput', false);

end
