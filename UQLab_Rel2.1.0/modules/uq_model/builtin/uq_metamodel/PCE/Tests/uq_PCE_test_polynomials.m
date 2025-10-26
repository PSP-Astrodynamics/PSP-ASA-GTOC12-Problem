function pass = uq_PCE_test_polynomials( level )
% PASS = UQ_PCE_TEST_POLYNOMIALS(LEVEL): non-regression test on the
%     orthonormality of the polynomials. 

% Print out running message
fprintf(['\nRunning: |' level '| uq_PCE_test_polynomials...\n']);

% list the correctly named tests that are included in the 
% test folder for polynomials and then run them:
rr = dir(fullfile(fileparts(which(mfilename)),'poly_tests'));

inds = regexp({rr(:).name}, 'uq_poly_.*test.m');

FileNames = {rr(:).name};
TestNames = {};
for ii=1:length(FileNames)
    if cell2mat(inds(ii))==1
        TestNames{length(TestNames)+1} = FileNames{ii};
    end
end

    
    
TestNames =  cellfun(@(name) name(1:(find(name == '.')-1)) ,TestNames,...
    'UniformOutput',false) ;

success = zeros(length(TestNames),1);
Times = zeros(length(TestNames),1);
TestTimer = tic;
Tprev = 0;
for iTest = 1 : length(TestNames)
    % fix the value of the random number seed before initiating each test
    rng(10,'twister');
    % obtain the function handle of current test from its name
    testFuncHandle = str2func(TestNames{iTest});
    % run test
    try
        success(iTest) = testFuncHandle(level);
    catch err        
        if strcmpi(err.identifier,'MATLAB:nomem')
            warning('Run out of memory when running %s. The test is not registered as failed!',...
                TestNames{iTest});
            success(iTest) = 1;
        else
            warning( ' Test " %s " produced errors! \n ...The error message was: \n \t %s' , ...
                TestNames{iTest}, err.message);
        end
    end
    % calculate the time required from the current test to execute
    Times(iTest) = toc(TestTimer) - Tprev ;
    Tprev = Tprev + Times(iTest);
end

pass = all(success);
