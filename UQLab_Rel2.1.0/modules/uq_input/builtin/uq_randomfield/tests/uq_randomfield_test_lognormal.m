function pass = uq_randomfield_test_lognormal( level )
% PASS = uq_RF_exponential_1D: test for 1D gaussian analytical function
% .
eps = 1e-12;
% Initialize test:
pass = 1;
evalc('uqlab');


%% INPUT
% values taken from the default phimecasoft example
% Define the RFINPUT model.
RFInput.Type = 'RandomField';
RFInput.RFType = 'Lognormal';
RFInput.DiscScheme = 'EOLE' ;
RFInput.Mesh = linspace(0,10,50)';

RFInput.Corr.Family = 'exponential';
RFInput.Corr.Length = 2 ;

RFInput.Mean = 1 ;
RFInput.Std = 1 ;

RFInput.ExpOrder = 10 ;

evalc('myRF = uq_createInput(RFInput)') ;

rng(1) ;
[X,W] = uq_getSample(1) ;

% Calculate this by hand 
myRF.Internal.LNStd=myRF.Internal.Std;
myRF.Internal.LNMean=myRF.Internal.Mean;

% update the mean and the standard deviations and switch to Gaussian
RFInput.Std = sqrt(log((myRF.Internal.LNStd ./ myRF.Internal.LNMean).^2 +1)) ;
RFInput.Mean =  log( myRF.Internal.LNMean.^2 / sqrt(myRF.Internal.LNMean.^2+myRF.Internal.LNStd.^2) ) ;
RFInput.RFType = 'Gaussian';
evalc('myRF = uq_createInput(RFInput)') ;

rng(1);
[ Y,W2] = uq_getRFSample( myRF, 1) ;
Y = exp(Y) ;

if abs(max(W-W2)) < eps && abs(max(X-Y)) < eps
    pass = 1;
else
    pass = 0;
end

end
