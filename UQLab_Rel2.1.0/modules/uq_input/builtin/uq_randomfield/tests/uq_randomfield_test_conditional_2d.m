function pass = uq_randomfield_test_conditional_2d( level )
% PASS = uq_randomfield_test_conditional_2d: test for 1D gaussian analytical function
% .

eps = 1e-6;
RFMethods = {'KL','EOLE'};
% Initialize test:
pass = 1;
evalc('uqlab');

rng(1) ;
%% INPUT
% values taken from the default phimecasoft example
% Define the RFINPUT model.
RFInput.Type = 'RandomField';
RFInput.RFType = 'Gaussian'; 
RFInput.Corr.Family='Gaussian';
RFInput.RFData.X = [-.5,0,0.5;-.5,0,0.5]'; 
RFInput.RFData.Y = [-.5,1.0,1.5]'; 
x = linspace(-1,1,20);
y= linspace(-1,1,20);
[X,Y] = meshgrid(x,x);  
RFInput.Mesh= [X(:) Y(:)]; % 2-D mesh 
RFInput.Corr.Length=[0.2,0.5]; 
RFInput.ExpOrder=10; 
RFInput.Std=1;
RFInput.Mean=1;

%% RF module
for ii = 1 : length(RFMethods)
    switch lower(RFMethods{ii})
            case 'kl' 
                RFInput.DiscScheme=RFMethods{ii};
                eigenValue_ref = [0.180829583770244   0.175997660176260   0.140062645279413   0.129021393012427   0.115688794131119]' ;

            case 'eole' 
                RFInput.DiscScheme=RFMethods{ii};
                eigenValue_ref = [93.590200399024880  91.208614870683277  72.943905464165567  67.893214528755024  60.833579298193207]';
    end 
                
   evalc('myRF = uq_createInput(RFInput)');
%% Validation: Test the eigenvalues
eigenValue = myRF.RF.Eigs(1:5); % a test for the eigenvalues
pass = pass & ( max(abs(eigenValue - eigenValue_ref)) < eps ) ;

end