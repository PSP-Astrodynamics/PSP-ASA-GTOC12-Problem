function success = uq_PCK_test_multioutput( level )
%This test function checks whether PC-Kriging works well for a multi
%component output model

success = 0;
rng(1)

%% start a new session
uqlab('-nosplash');

%% a computational model with several response values
mopts.mFile = 'uq_fourbranch_separate';
mopts.isVectorized = 1;
myModel = uq_createModel(mopts, '-private');

%% and an input model
iopts.Marginals(1).Type = 'Gaussian';
iopts.Marginals(1).Moments = [0,1];
iopts.Marginals(2) = iopts.Marginals(1);
myInput = uq_createInput(iopts, '-private');

%% a simple sequential PC-Kriging model with low degree trend
sopts.Type = 'Metamodel';
sopts.MetaType = 'PCK';

%switch the mode to check for both variants
% sopts.Mode = 'sequential';
sopts.Mode = 'optimal';

sopts.Input = myInput;
sopts.FullModel = myModel;

sopts.ExpDesign.Sampling = 'LHS';
sopts.ExpDesign.NSamples = 20;

sopts.PCE.Method = 'LARS';
sopts.PCE.Degree = 2;

sopts.Display = 0;

mySPCK = uq_createModel(sopts);

%% check a validation set too
x = uq_getSample(myInput, 10, 'MC');
[ym, ys2] = uq_evalModel(mySPCK, x);


%% checks
switch false
    %check the dimensionality of the response vector
    case size(ym, 2) == 4
        ErrMsg = sprintf('prediction mean');
    case size(ys2,2) == 4
        ErrMsg = sprintf('prediction standard deviation');
        
    %check the dimensionality of the returned metamodel
    case length(mySPCK.PCK) == 4
        ErrMsg = sprintf('PCK output structure');
        
    %check some statistics of the metamodel
    % first make sure the beta arrays have the same format (needed for old
    % MATLAB versions)
    for ii=1:length(mySPCK.PCK)
        if ~iscolumn(mySPCK.PCK(ii).beta)
            mySPCK.PCK(ii).beta = mySPCK.PCK(ii).beta';
        end
    end
    
    case  sum(abs(sort(abs(mySPCK.PCK(1).beta)) - sort(abs(mySPCK.PCK(2).beta)))) <= 1e-12
        ErrMsg = sprintf('Kriging in dimensions 1 and 2 do not coincide');
    case  sum(abs(sort(abs(mySPCK.PCK(3).beta)) - sort(abs(mySPCK.PCK(4).beta)))) <= 1e-12
        ErrMsg = sprintf('Kriging in dimensions 1 and 2 do not coincide');
        
    %otherwise the test fails    
    otherwise
        success = 1;
        fprintf('\nTest uq_PCK_test_multioutput finished successfully!\n')
end

if success == 0
    ErrStr = sprintf('\nError in uq_PCK_test_multioutput while comparing the %s\n', ErrMsg);
    error(ErrStr);
end

