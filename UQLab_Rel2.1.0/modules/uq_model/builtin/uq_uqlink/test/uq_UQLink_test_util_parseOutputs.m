function pass = uq_UQLink_test_util_parseOutputs(level)
%UQ_UQLINK_TEST_UTIL_PARSEOUTPUTS tests the utility function to parse
%   outputs from 3rd-party code execution.

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
function testOneOutputFileOneDimension()
% Test for one output file, has one dimension.

% Set up the case
Y = randi(10,1).^2;  % Use integer for easy comparison
[~,fname] = fileparts(tempname);
outputFile = [fname '.dat'];
dlmwrite(outputFile, Y, 'precision', 6)

outputParser = @(filename) dlmread(filename);

% Parse the outputs
Yparsed = uq_UQLink_util_parseOutputs(outputFile, outputParser, 1);

try 
    % Assertion
    assert(isequal(Y,Yparsed{1}))
catch ME
    % Clean up
    delete(outputFile)
    rethrow(ME)
end

% Clean up
delete(outputFile)
    
end


%% ------------------------------------------------------------------------
function testOneOutputFileMultipleDimensions()
% Test for one output file, has multiple dimensions.

% Set up the case
Y = randi(10,1,1000).^2;  % Use integer for easy comparison
[~,fname] = fileparts(tempname);
outputFile = [fname '.dat'];
dlmwrite(outputFile, Y, 'precision', 6)

outputParser = @(filename) dlmread(filename);

try 
    % Parse the outputs
    Yparsed = uq_UQLink_util_parseOutputs(outputFile, outputParser, 1);
    % Assertion
    assert(isequal(Y,Yparsed{1}))
catch ME
    % Clean up
    delete(outputFile)
    rethrow(ME)
end

% Clean up
delete(outputFile)
    
end


%% ------------------------------------------------------------------------
function testMultipleOutputFilesOneNumOfOutArgs()
% Test for multiple output files, each has one single output.

% Set up the case
Y = cell(1,3);  % Output will be in a row vector
outputFiles = cell(1,3);
for i = 1:3
    Y{i} = randi(10,1).^(i+1);  % Use integer for easy comparison
    [~,fname] = fileparts(tempname);
    outputFiles{i} = [fname '.dat'];
    dlmwrite(outputFiles{i}, Y{i}, 'precision', 6)
end

outputParser = @uq_read_testMultipleOutputs;

try
    % Parse the outputs
    Yparsed = uq_UQLink_util_parseOutputs(outputFiles, outputParser, 3);
    % Assertion
    assert(isequal(Y,Yparsed))
catch ME
    % Clean up
    cellfun(@(x) delete(x), outputFiles)
    rethrow(ME)
end

% Clean up
cellfun(@(x) delete(x), outputFiles)

end


%% ------------------------------------------------------------------------
function testMultipleOutputFilesMultipleNumOfOutArgs()
% Test for multiple output files, each has different number of outputs.

% Set up the case
Y = cell(1,3);  % Output will be in a row vector
outputFiles = cell(1,3);
for i = 1:3
    Y{i} = randi(10,1,i*2).^(i+1);  % Use integer for easy comparison
    [~,fname] = fileparts(tempname);
    outputFiles{i} = [fname '.dat'];
    dlmwrite(outputFiles{i}, Y{i}, 'precision', 6)
end

outputParser = @uq_read_testMultipleOutputs;

% Parse the outputs
Yparsed = uq_UQLink_util_parseOutputs(outputFiles, outputParser, 3);

try 
    % Assertion
    assert(isequal(Y,Yparsed))
catch ME
    % Clean up
    cellfun(@(x) delete(x), outputFiles)
    rethrow(ME)
end

% Clean up
cellfun(@(x) delete(x), outputFiles)

end
