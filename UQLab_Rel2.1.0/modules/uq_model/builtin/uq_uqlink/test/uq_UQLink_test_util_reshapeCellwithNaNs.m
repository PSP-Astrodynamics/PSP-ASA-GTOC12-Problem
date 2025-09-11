function pass = uq_UQLink_test_util_reshapeCellwithNaNs(level)
%UQ_UQLINK_TEST_UTIL_RESHAPECELLWITHNANS tests the utility function to
%   reshape a cell array of numeric arrays with NaN values.

%% Initialize test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...\n', level, mfilename);

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
for i = 1:numel(testFunctions)
    feval(testFunctions{i})
end

pass = true;

end


%% ------------------------------------------------------------------------
function testSingleCellSingleColumn()
% Test case single cell with a single column element.

% Set up the case
Yref = {[NaN; NaN]};

numCol = 1;
numRows = 2;
numCells = 1;
Yout = uq_UQLink_util_reshapeCellWithNaNs(Yref, numRows, numCol, numCells);

% Assert
assert(isequaln(Yout,Yref))

end


%% ------------------------------------------------------------------------
function testSingleCellMultipleColumns()
% Test case single cell with a multiple columns element.

% Set up the case
Yref = {[NaN NaN NaN; NaN NaN NaN]};

Yinp = {[NaN; NaN; NaN]};
numRows = 2;
numCols = 3;
numCells = 1;
Yout = uq_UQLink_util_reshapeCellWithNaNs(Yinp,numRows,numCols,numCells);

% Assert
assert(isequaln(Yout,Yref))

end


%% ------------------------------------------------------------------------
function testMultipleCellsSingleColumn()
% Test case for multiple cells with a single column element.

% Set up the case
Yref = {[NaN; NaN; NaN; NaN] [NaN; NaN; NaN; NaN]};

numCols = ones(1,2);
numRows = 4;
numCells = 2;
Yout = uq_UQLink_util_reshapeCellWithNaNs(Yref,numRows,numCols,numCells);

% Assert
assert(isequaln(Yout,Yref))

end


%% ------------------------------------------------------------------------
function testMultipleCellsMultipleColumns()
% Test case for multiple cells with multiple-column elements.

% Set up the case
Yref = {[NaN NaN NaN; NaN NaN NaN],...
    [NaN NaN NaN NaN NaN; NaN NaN NaN NaN NaN],...
    [NaN; NaN]};

Yinp = {[NaN; NaN] [NaN; NaN] [NaN; NaN]};
numCols = cellfun(@(x) size(x,2), Yref);
numRows = 2;
numCells = 3;
Yout = uq_UQLink_util_reshapeCellWithNaNs(Yinp,numRows,numCols,numCells);

% Assert
assert(isequaln(Yout,Yref))

end
