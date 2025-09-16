function Y = uq_UQLink_util_reshapeCellWithNaNs(Y, numRows, numCols, numCells)
%UQ_UQLINK_UTIL_RESHAPECELLWITHNANS reshapes array elements of cell array.
%
%   Inputs
%   ------
%   - Y: input Y, cell array
%   - numRows: number of rows for all elements of Y to reshape, scalar int.
%   - numCols: number of columns per element of Y to reshape, vector int.
%   - numCells: number of cells to reshape, scalar int.
%
%   Output
%   ------
%   - Y: reshaped Y, cell array
%
%   Examples
%   --------
%       Y = {[NaN; NaN; NaN]}
%       Y = uq_UQLink_test_util_reshapeCellwithNaNs(Y, 2, 3, 1)
%           % {[NaN NaN NaN; NaN NaN NaN]}
%
%       Yinp = {[NaN; NaN] [NaN; NaN] [NaN; NaN]};
%       Yout = uq_UQLink_util_reshapeCellWithNaNs(Yinp, 2, [3 5 1], 3)
%           % {...
%           %   [NaN NaN NaN; NaN NaN NaN],...
%           %   [NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN],...
%           %   [NaN; NaN]}

%%
for oo = 1:numCells
    Y{oo} = NaN * ones(numRows,numCols(oo));
end

end
