function success = uq_LRA_test_multiple_outputs(level)
% UQ_LRA_TEST_MULTIPLE_OUTPUTS(LEVEL)
% 
% Summary:  
%   Tests if the multiple output functionality works
%
% Settings:
%   LEVEL = { 'normal', 'slow' }
%
% Details:
%   The multiple output LRA should compute an LRA model independently for
%   each output variable Yi from the input variables Xi.
%   
%   Assert that:
%     1) The model is initialized and its coefficients computed correctly
%     2) The structure of the output is consistent

success = 0;
rng(1)

%% start a new session
uqlab('-nosplash');

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
    
end
switch level
    case 'normal'
        nRankOnes = 9;
        degrees = 3;
        NED = 20;
    otherwise
        nRankOnes = 1:100;
        degrees = 15;
        NED = 100;
end

%% a computational model with several response values
mopts.mFile = 'uq_fourbranch_separate';
mopts.isVectorized = 1;
myModel = uq_createModel(mopts, '-private');

%% and an input model
iopts.Marginals(1).Type = 'Gaussian';
iopts.Marginals(1).Moments = [0,1];
iopts.Marginals(2) = iopts.Marginals(1);
myInput = uq_createInput(iopts, '-private');

%% LRA model options
sopts.Type = 'Metamodel';
sopts.MetaType = 'LRA';

sopts.Input = myInput;
sopts.FullModel = myModel;

sopts.ExpDesign.Sampling = 'LHS';
sopts.ExpDesign.NSamples = NED;

sopts.Degree = degrees ;
sopts.Rank = nRankOnes ;

sopts.Display = 0;

myLRA = uq_createModel(sopts);

%% check a validation set too
x = uq_getSample(myInput, 10, 'MC');
ym= uq_evalModel(myLRA, x);

%% checks
switch false
    %check the dimensionality of the response vector
    case size(ym, 2) == 4
        ErrMsg = sprintf('prediction mean');
        
    %check the dimensionality of the returned metamodel
    case length(myLRA.LRA) == 4
        ErrMsg = sprintf('LRA output structure');
        
    case size(ym,2) == 4
        ErrMsg = sprintf('LRA predicted output size') ;
        
    %otherwise the test fails    
    otherwise
        success = 1;
        fprintf('\nTest uq_LRA_test_multiple_outputs finished successfully!\n')
end

if success == 0
    ErrStr = sprintf('\nError in uq_LRA_test_multiple_outputs while comparing the %s\n', ErrMsg);
    error(ErrStr);
end
