function pass = uq_GLaM_test_Custom( level )
% UQ_GLAM_TEST_CUSTOM( LEVEL ): non-regression testing for custom PCE
% (predictor only)

 
% Summary:
%   Test for the generalized lambda model calculation 
%   for a 'Custom' definition. No calculation takes place.
% 
% Settings:
%   LEVEL = { 'normal', 'detailed' }
% 
% Details:
%    Asserts that it is possible to set a custom lambdas
%    (user defined coefficients - without calculation) for a GLaM meta-model.
%    First a GLaM meta-model is calculated for the geometric Brownian motion
%    defined as:
%    
%        Y(x) ~ \mathcal{LN}(x_1-x_2^2/2,x_2).
%    
%    A random uniform distribution is chosen for $ X_1 , X_2 $ and a 
%    metamodel is calculated with the full regression method. The coefficients 
%    calculated with "FullReg" are set to the metamodel with 
%    "custom" as method of calculation and the same results 
%    are retrieved as with the regression model. 

% Initialize test:
uqlab('-nosplash');
rng(100,'twister');
pass = 1;

% if nargin < 1
%     level = 'normal'; % TBD: Time that the tests will take
% end
% fprintf(['\nRunning: |' level '| uq_GLaM_test_Custom...\n']);

%% INPUT
Input.Marginals(1).Name = 'mu';
Input.Marginals(1).Type = 'Uniform';
Input.Marginals(1).Parameters = [0,0.2]; 

Input.Marginals(2).Name = 'sigma';
Input.Marginals(2).Type = 'Uniform';
Input.Marginals(2).Parameters = [0.1,0.3];

myInput = uq_createInput(Input, '-private');
%% MODEL
modelopts.mFile = 'uq_GBM'; % specify the function name
modelopts.isStochastic = true; % specify the model being stochastic
myModel = uq_createModel(modelopts, '-private');        % create the model object


%% PCE Metamodel: create an original metamodel
clear metaopts

metaopts.Type = 'Metamodel';
metaopts.MetaType = 'GLaM';
metaopts.Input = myInput ;
metaopts.FullModel = myModel;

metaopts.Method = 'FullReg';           % Or can be set to StepReg as well
metaopts.Lambda(1).Degree = 0:3;
metaopts.Lambda(1).PolyTypes = {'arbitrary','legendre'};

metaopts.ExpDesign.Sampling = 'Sobol';
metaopts.ExpDesign.NSamples = 1e3;

% Test also that the 'arbitrary' option does not break the 
% 'custom' PCE:
myGLaM = uq_createModel(metaopts);
%% GENERATE A NEW CUSTOM PCE MODEL JUST TO EVALUATE THE PREDICTOR
clear predopts;
predopts.Type = 'Metamodel';
predopts.MetaType = 'GLaM';
% specify the "Custom" PCE method
predopts.Method = 'Custom';

% specify the same input as for the other PCE
predopts.Input = myInput;

% specify the basis for the PCE
for ilam=1:4
    predopts.Lambda(ilam).Basis.Indices = myGLaM.GLaM(ilam).Basis.Indices;
    predopts.Lambda(ilam).Basis.PolyTypes = myGLaM.GLaM(ilam).Basis.PolyTypes;
    predopts.Lambda(ilam).Basis.PolyTypesParams= myGLaM.GLaM(ilam).Basis.PolyTypesParams;
    
    predopts.Lambda(ilam).Coefficients = myGLaM.GLaM(ilam).Coefficients;
end

% make it multidimensional just for the sake of testing
predopts.Lambda = [predopts.Lambda,predopts.Lambda];

% generate the metamodel
customGLaM = uq_createModel(predopts);

%% COMPARE PREDICTIONS FROM THE TWO MODEL
% get a validation sample
X = uq_getSample(1e5);
% predict the responses with the original metamodel
YPC = uq_evalModel(myGLaM,X);
% predict the same responses with the "custom" metamodel
YPCpred = uq_evalModel(customGLaM,X);

%% TEST RESULTS (PREDICTORS IDENTICAL TO MACHINE PRECISION)
pass = pass & (max(abs(YPC-YPCpred(:,1))) < eps);
