function pass = uq_randomfield_test_discschemes_1d( level )
% PASS = UQ_RANDOMFIELD_TEST_DISCSCHEMES_1D: test for 1D RF using
% exponential kernel.

%% 1. Regression test
% EOLE values - values calculated beforehand: The test henceforth only
% validtaes that there is no change with respect to the initial set-up.
% Note that these values have been validated against another code...
Exponential_eigenValue_EOLE =  [
    8.391882325144257
    5.444558676084492
    3.287195423185886
    2.051165377987276
    1.360572574955902
    0.957239946153840
    0.707814753447094
    0.545154586247183
    0.434155412406988
    0.355493087981704
    ] ;

Exponential_eigenVec_EOLE = [
    -0.107690845869928
    -0.126366510937388
    -0.144050198514156
    -0.160603091599601
    -0.175895249933247
    -0.189806630026210
    -0.202228027502945
    -0.213061934355923
    -0.222223304383784
    -0.229640220804272
    -0.235254460801192
    -0.239021952573693
    -0.240913121300037
    -0.240913121300037
    -0.239021952573693
    -0.235254460801192
    -0.229640220804272
    -0.222223304383784
    -0.213061934355923
    -0.202228027502944
    -0.189806630026209
    -0.175895249933247
    -0.160603091599601
    -0.144050198514156
    -0.126366510937388
    -0.107690845869928
    ] ;

Exponential_eigenValue_KL = [
    3.309206128856896
    2.097761014573813
    1.239058158425747
    0.759653855947207
    0.496218289914295
    0.343888410969825
    0.250236354461147
    0.189359346446023
    0.147873265025392
    0.118466802475832
    ] ;

Exponential_eigenVec_KL = [
    0.161095442654743
    0.202223879116871
    0.240432424541322
    0.275169389435069
    0.305933210120706
    0.332279690765885
    0.353828417083995
    0.370268249099260
    0.381361813666768
    0.386948931880357
    0.386948931880357
    0.381361813666768
    0.370268249099260
    0.353828417083995
    0.332279690765885
    0.305933210120706
    0.275169389435069
    0.240432424541322
    0.202223879116871
    0.161095442654743
    ] ;
eps = 1e-12;
RFMethods = {'EOLE','KL'};
% Initialize test:
pass = 1;
evalc('uqlab');


%% INPUT
% values taken from the default phimecasoft example
% Define the RFINPUT model.
RFInput.Type = 'RandomField';
RFInput.RFType = 'Gaussian';
RFInput.Mesh = linspace(0,10,20)';

RFInput.Corr.Family = 'exponential';
RFInput.Corr.Length = 2 ;
RFInput.ExpOrder = 10;

RFInput.Mean = 1 ;
RFInput.Std = 1 ;


%% RF module
for ii = 1 : length(RFMethods)
    
    RFInput.DiscScheme=RFMethods{ii};
    
    evalc('myRF = uq_createInput(RFInput)');
    
    %% Validation: Test the eigenvalues and eigenvectors
    Exponential_eigenValue = myRF.RF.Eigs; % a test for the eigenvalues
    Exponential_eigenVec = myRF.RF.Phi(:,1); % a test for the first  eigenfunctions
    
    switch lower(RFInput.DiscScheme)
        case 'eole'
            
            % Compare the eigenvalues and first eigenvector with a reference
            % one
            pass = pass & ( max(abs(Exponential_eigenValue_EOLE - Exponential_eigenValue)) < eps ) & ...
                ( max(abs(Exponential_eigenVec_EOLE - Exponential_eigenVec)) < eps ) ;
            
            % Compare a sample directly from uq_getSample and one obtained by
            % transforming a reduced random variables
            [X1,xi] = uq_getSample(1) ;
            X2 = uq_RF_Xi_to_X(myRF,xi) ;
            
            pass = pass & ( max(abs(X2-X1)) < eps );
            
            
        case 'kl'
            pass = pass & ( max(abs(Exponential_eigenValue_KL - Exponential_eigenValue)) < eps ) & ...
                ( max(abs(Exponential_eigenVec_KL - Exponential_eigenVec)) < eps ) ;
            
            % Compare a sample directly from uq_getSample and one obtained by
            % transforming a reduced random variables
            [X1,xi] = uq_getSample(1) ;
            X2 = uq_RF_Xi_to_X(myRF,xi) ;
            
            pass = pass & ( max(abs(X2-X1)) < eps );
    end
end
%% 2. Comparisonwith analytical solution
% Solve the problem with a different solver and compared to analytical KL
% using the reconstructed correlation matrix
RFInput.DiscScheme = 'KL' ;
RFInput.KL.Method = 'analytical' ;
RFInput.Mesh = linspace(0,10,500)';
RFInput.ExpOrder = 25 ;

evalc('myRF = uq_createInput(RFInput)');

R0 = myRF.RF.Phi * ( myRF.RF.Phi * diag(myRF.RF.Eigs) )' ;

RFInput.KL.Method = 'Nystrom' ;
RFInput.KL.SPD = 100 ;
evalc('myRF = uq_createInput(RFInput)');

R1 = myRF.RF.Phi * ( myRF.RF.Phi * diag(myRF.RF.Eigs) )';

RFInput.KL.Method = 'Discrete' ;
evalc('myRF = uq_createInput(RFInput)');

R2 = myRF.RF.Phi*(myRF.RF.Phi*diag(myRF.RF.Eigs))';

pass = pass & (max(max(R1-R0)) < 1e-2) & (max(max(R2-R0)) < 1e-2) ;
end

