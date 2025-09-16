function success = uq_Reliability_test_print_and_display( level )
% SUCCESS = UQ_RELIABILITY_TEST_RELIABILITY_PRINT_AND_DISPLAY(LEVEL):
%     Testing the fuctionality of uq_print and uq_display in the context of
%     reliability analyses
%
% See also UQ_SELFTEST_UQ_RELIABILITY

%% Start test:
uqlab('-nosplash');
close all;
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
rng(1)

%% create the input
IOpts.Marginals(1).Type = 'Gaussian';
IOpts.Marginals(1).Parameters = [0, 5];
IOpts.Marginals(2).Type = 'Gaussian';
IOpts.Marginals(2).Parameters = [0, 5];

uq_createInput(IOpts);

%% create the computational model
MOpts.mFile = 'uq_fourbranch_separate';
MOpts.Parameters = 7;
MOpts.isVectorized = true;

uq_createModel(MOpts);

%% Use a number of simple structural reliability analyses
% Monte Carlo Simulation
mopts.Type = 'reliability';
mopts.Method = 'MC';
mopts.Simulation.BatchSize = 500;
mopts.Simulation.MaxSampleSize = 1e3;
mopts.Display = 'quiet';
MCanalysis = uq_createAnalysis(mopts);

% FORM
fopts.Type = 'reliability';
fopts.Method = 'FORM';
fopts.Display = 'quiet';
FORManalysis = uq_createAnalysis(fopts);

% SORM
sopts.Type = 'reliability';
sopts.Method = 'SORM';
sopts.Display = 'quiet';
SORManalysis = uq_createAnalysis(sopts);

% Importance Sampling
iopts.Type = 'reliability';
iopts.Method = 'IS';
iopts.Simulation.BatchSize = 500;
iopts.Simulation.MaxSampleSize = 1e3;
iopts.Display = 'quiet';
ISanalysis = uq_createAnalysis(iopts);

% AK-MCS
aopts.Type = 'reliability';
aopts.Method = 'AKMCS';
aopts.Simulation.MaxSampleSize = 1e3;
aopts.AKMCS.MaxAddedED = 2;
aopts.Display = 'quiet';
AKanalysis = uq_createAnalysis(aopts);


%% Check up_print for errors
Error_print = {};
% MCS
try
    uq_print(MCanalysis)
    uq_print(MCanalysis, [1 3 2])
catch errorMCp
    Error_print{end+1} = errorMCp.message;
end

% FORM
try
    uq_print(FORManalysis)
    uq_print(FORManalysis, [1 4 2])
catch errorFORMp
    Error_print{end+1} = errorFORMp.message;
end

% SORM
try
    uq_print(SORManalysis)
    uq_print(SORManalysis, [4 3 1])
catch errorSORMp
    Error_print{end+1} = errorSORMp.message;
end

% IS
try
    uq_print(ISanalysis)
    uq_print(ISanalysis, [3 2 4])
catch errorISp
    Error_print{end+1} = errorISp.message;
end

% AKMCS
try
    uq_print(AKanalysis)
    uq_print(AKanalysis, [2 3 4])
catch errorAKp
    Error_print{end+1} = errorAKp.message;
end

%% Check uq_display for errors
Error_display = {};
% MCS
try
    uq_display(MCanalysis)
    uq_display(MCanalysis, [1 4])
    set(findobj('type', 'figure'), 'visible', 'off')
catch errorMCd
    Error_display{end+1} = errorMCd.message;
end

% FORM
try
    uq_display(FORManalysis)
    uq_display(FORManalysis, [1 2])
    set(findobj('type', 'figure'), 'visible', 'off')
catch errorFORMd
    Error_display{end+1} = errorFORMd.message;
end

% SORM
try
    uq_display(SORManalysis)
    uq_display(SORManalysis, [1 3])
    set(findobj('type', 'figure'), 'visible', 'off')
catch errorSORMd
    Error_display{end+1} = errorSORMd.message;
end

% IS
try
    uq_display(ISanalysis)
    uq_display(ISanalysis, [2 1])
    set(findobj('type', 'figure'), 'visible', 'off')
catch errorISd
    Error_display{end+1} = errorISd.message;
end

% AKMCS
try
    uq_display(AKanalysis)
    uq_display(AKanalysis, [3 4])
    set(findobj('type', 'figure'), 'visible', 'off')
catch errorAKd
    Error_display{end+1} = errorAKd.message;
end

close all;
%% Success
if isempty(Error_print) && isempty(Error_display)
    success = 1;
else
    success = 0;
    fprintf('\nError in uq_test_reliability_print_and_display:\n');
    for ii = 1:length(Error_print)
        fprintf(Error_print{ii});
        fprintf('\n')
    end
    for ii = 1:length(Error_display)
        fprintf(Error_display{ii});
        fprintf('\n')
    end
    ErrStr = 'Errors in uq_test_reliability_print_and_display';
    error(ErrStr);
end
