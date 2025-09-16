function initSizes = uq_UQLink_util_initSizes(numCols,Y)
%UQ_UQLINK_UTIL_INITSIZES initializes the size (number of columns) for each
%   element of a cell array.
%
%   Inputs
%   ------
%   - numCols: number of columns, double.
%   - Y: a cell array with row vectors as elements, cell array.
%       If given, then initialization is based on the actual content of Y.
%
%   Outputs
%   -------
%   - initSizes: initial sizes for each columns.
%
%   Examples
%   --------
%       uq_UQLink_util_initSizes()  % 1
%
%       uq_UQLink_util_initSizes(5)  % [1 1 1 1 1]
%
%       Y = {rand(1,2) rand(1,7) rand(1,3)};
%       uq_UQLink_util_initSizes(3,Y)  % [2 7 3]
%
%       Y = {rand(1,2) rand(1,7) rand(1,3)};
%       uq_UQLink_util_initSizes(2,Y)  % [2 7]

%% Verify inputs
if nargin < 2
    Y = {};
end

if nargin < 1
    numCols = 1;
end

%% Initialize the sizes

initSizes = ones(1,numCols);

if ~isempty(Y)
    for i = 1:numCols
        initSizes(i) = size(Y{i},2);
    end
end

end
