function pass = uq_randomfield_test_newmesh( level )
% PASS = uq_randomfield_test_newmesh
% .

eps = 1e-12;
RFMethods = {'EOLE'};
% Initialize test:
pass = 1;
evalc('uqlab');


%% INPUT
% values taken from the default phimecasoft example
% Define the RFINPUT model.
RFInput.Type = 'RandomField';
RFInput.RFType = 'Gaussian';
RFInput.DiscScheme = 'EOLE' ;
RFInput.Mesh = linspace(0,10,200)';

RFInput.Corr.Family = 'exponential';
RFInput.Corr.Length = 2 ;

RFInput.Mean = 1 ;
RFInput.Std = 1 ;

myRF = uq_createInput(RFInput) ;

newmesh = linspace(0,10,20)';

% if no error, here then the test is passed
try
X = uq_getSample(1e4,'MC','Mesh',newmesh);
catch
    pass = 0 ; 
end
end
