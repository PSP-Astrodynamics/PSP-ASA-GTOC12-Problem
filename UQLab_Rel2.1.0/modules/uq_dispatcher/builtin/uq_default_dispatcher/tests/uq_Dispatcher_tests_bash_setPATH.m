function pass = uq_Dispatcher_tests_bash_setPATH(level)

%% Initialize test
if nargin < 1
    level = 'normal';
end

uqlab('-nosplash')

fprintf('Running: | %s | %s...', level, mfilename)

%% Get all local test functions
testFunctions = localfunctions;

%% Execute all test functions
for i = 1:numel(testFunctions)
    feval(testFunctions{i})
end

%% Return the results
fprintf('PASS\n')

pass = true;

end

%% ------------------------------------------------------------------------
function testNoInput()
refChar = 'export PATH=$PATH';

assert(strcmp(refChar,uq_Dispatcher_bash_setPATH()))
end

%% ------------------------------------------------------------------------
function testOneEmptyInput()
refChar = 'export PATH=$PATH';

assert(strcmp(refChar,uq_Dispatcher_bash_setPATH({})))
end

%% ------------------------------------------------------------------------
function testTwoEmptyInputs()
refChar = 'export PATH=$PATH';

assert(strcmp(refChar,uq_Dispatcher_bash_setPATH({},{})))
end

%% ------------------------------------------------------------------------
function testOneInput()
addToPath = {'~/programs/bin','~/usr/bin'};

refChar = sprintf(...
    'PATH="$PATH:%s:%s"\n\nexport PATH=$PATH', addToPath{:});

assert(strcmp(refChar,uq_Dispatcher_bash_setPATH(addToPath)))
end

%% ------------------------------------------------------------------------
function testTwoInputs()
addToPath = {'~/programs/bin','~/usr/bin'};
addTreeToPath = {'~/apps','~/usr/local/bin'};

refChar = sprintf(...
    ['PATH="$PATH:%s:%s"\n\n',...
    'subfolders=`find %s -type d`\n',...
    'for folder in $subfolders; do PATH="$PATH:$folder"; done\n'....
    'subfolders=`find %s -type d`\n',...
    'for folder in $subfolders; do PATH="$PATH:$folder"; done\n\n'....
    'export PATH=$PATH'], addToPath{:}, addTreeToPath{:});

assert(strcmp(refChar,uq_Dispatcher_bash_setPATH(addToPath,addTreeToPath)))
end
