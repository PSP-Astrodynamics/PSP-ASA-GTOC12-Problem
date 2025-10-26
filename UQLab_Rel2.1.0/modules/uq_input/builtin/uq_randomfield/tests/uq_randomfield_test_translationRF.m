function pass = uq_randomfield_test_translationRF( level )
% PASS = UQ_RANDOMFIELD_TEST_TRANSLATIONRF: test for 1D non-Gaussian
% translation RF using various marginals.


eps = 1e-12;
RFMethods = {'EOLE'};
% Initialize test:
pass = 1;
evalc('uqlab');
% RFTypes, other than Gaussian
RFTypes = {'Lognormal','Exponential','Uniform','Gumbel','GumbelMin','Gamma','Logistic','Laplace'};

%% INPUT
% Define the RFINPUT model.
RFInput.Type = 'RandomField';
RFInput.RFType = 'Gaussian';
RFInput.Mesh = linspace(0,10,20)';

RFInput.Corr.Family = 'exponential';
RFInput.Corr.Length = 2 ;
RFInput.ExpOrder = 10;

RFInput.Mean = 1 ;
RFInput.Std = 1 ;

% First create a Gaussian RF and sample from it
RFInput.RFType = 'Gaussian';

evalc('myRF = uq_createInput(RFInput)');

rng(1)
X = uq_getSample(1) ;

%% RF module
for ii = 1 : length(RFTypes)
    % Create th ecorresponding non-Gaussian random field
    RFInput.RFType = RFTypes{ii};
    evalc('myRF = uq_createInput(RFInput)');
    
    % Sample from it
    rng(1)
    Y = uq_getSample(1) ;
    
    % Translate the sample to the equivalenent Gaussian
    Z = uq_translateRF(Y, myRF, 'Gaussian');
    
    % Make sure they are similar
    pass = pass & max(Z-X)< eps ;
    
end

end

