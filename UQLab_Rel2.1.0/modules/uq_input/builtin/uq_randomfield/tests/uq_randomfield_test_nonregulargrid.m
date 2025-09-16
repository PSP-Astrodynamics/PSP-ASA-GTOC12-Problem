function pass = uq_randomfield_test_nonregulargrid( level )
% PASS = uq_randomfield_test_nonregulargird: test that both KL and EOLE run
% on non-regular user-given grid.

% In the v2.0 release the error in this setting is around 0.07 for both
% cases - Set an error slightly aboved to pass the test
eps = 0.1;
rng(1) ;
RFMethods = {'KL','EOLE'};
% Initialize test:
pass = 1;
evalc('uqlab');

% Random field options
RFInput.Type = 'RandomField';
RFInput.RFType = 'Gaussian';
RFInput.Corr.Family='exponential';
RFInput.Corr.Length=0.3;
RFInput.ExpOrder=10;
RFInput.Std=1;
RFInput.Mean=1;

% Random field discretization mesh: For EOLE, this is only used for display
RFInput.Mesh = rand(150,1) ;
% Random field discretization coordinates used within EOLE only
RFInput.RFCoor = rand(150,1) ;
%% RF module
for ii = 1 : length(RFMethods)
    switch lower(RFMethods{ii})
        case 'kl'
            RFInput.DiscScheme=RFMethods{ii};
        case 'eole'
            RFInput.DiscScheme=RFMethods{ii};
    end
    
    evalc('myRF = uq_createInput(RFInput)');
    
    %% Validation: Check the variance error
    pass = pass &  mean(myRF.RF.VarError) < eps ;
    
end

end