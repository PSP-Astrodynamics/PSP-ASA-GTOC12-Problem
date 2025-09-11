function pass = uq_PCE_test_constant_PolyTypes(level)
% pass = UQ_PCE_TEST_CONSTANT_POLYTYPES(LEVEL): Non-regression test to 
% assert that constant dimensions are assigned the right PolyType (even
% when the user manually tries to specify another PolyType)
% 
%
% What is tested:
% 
%   1) The constant variables are recognised
%   2) Constant variables are assigned PolyType "zero" and the
%   corresponding PolyTypeParam is set to the constant value
%   3) If the user specifies any other PolyType for a constant variable, a 
%   warning is generated and its PolyType is set to "zero"


%% Input setup:

% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_constant_PolyTypes...\n']);

%% INPUT
Input.Marginals(1).Type = 'Uniform' ;
Input.Marginals(1).Parameters = [1, 3] ;
Input.Marginals(2).Type = 'Constant' ;
Input.Marginals(2).Parameters = 2.0;
Input.Marginals(3).Type = 'Gaussian' ;
Input.Marginals(3).Parameters = [3.0, 0] ;

myInput = uq_createInput(Input);

if ~all(myInput.nonConst == [1])
    error('The constant variables were not recognized during PCE input creation.')
end

% take a small sample and assert that the fixed constant variables are what
% they should be:
evalc('test_sample = uq_getSample(100);');
if ~all(test_sample(:,2) == 2.0) || ~all(test_sample(:,3)==3.0)
    error('The constant variables are not set correctly during the input module creation.')
end

%% Model
mopts.mHandle = @(X) X(:,1).^(3/2).*sin(X(:,2)) + sqrt(X(:,3));
myModel = uq_createModel(mopts);

%% PCE with auto-retrieved PolyTypes
clear metaopts

metaopts.Display = 0;

metaopts.Type = 'metamodel';
metaopts.MetaType = 'PCE';
metaopts.Method = 'OLS';
metaopts.Input = myInput;
metaopts.FullModel = myModel;
metaopts.Degree = 3;

X = uq_getSample(myInput, 100);
Y = uq_evalModel(myModel, X);

metaopts.ExpDesign.X = X;
metaopts.ExpDesign.Y = Y;

myPCE = uq_createModel(metaopts);

pass = pass & strcmpi(myPCE.PCE.Basis.PolyTypes{1}, 'legendre') ...
    & strcmpi(myPCE.PCE.Basis.PolyTypes{2}, 'zero') ...
    & strcmpi(myPCE.PCE.Basis.PolyTypes{3}, 'zero');

pass = pass & (myPCE.PCE.Basis.PolyTypesParams{2} == Input.Marginals(2).Parameters(1)) ...
    & (myPCE.PCE.Basis.PolyTypesParams{3} == Input.Marginals(3).Parameters(1));

coeffs = myPCE.PCE.Coefficients;

%% User-specified PolyTypes I
metaopts.PolyTypes = {'legendre', 'Zero', 'zero'};
myPCE = uq_createModel(metaopts);

pass = pass & strcmpi(myPCE.PCE.Basis.PolyTypes{1}, 'legendre') ...
    & strcmpi(myPCE.PCE.Basis.PolyTypes{2}, 'zero') ...
    & strcmpi(myPCE.PCE.Basis.PolyTypes{3}, 'zero');

pass = pass & (myPCE.PCE.Basis.PolyTypesParams{2} == Input.Marginals(2).Parameters(1)) ...
    & (myPCE.PCE.Basis.PolyTypesParams{3} == Input.Marginals(3).Parameters(1));

pass = pass & (norm(coeffs - myPCE.PCE.Coefficients) < 1e-12);

%% User-specified PolyTypes II
metaopts.PolyTypes = {'legendre', 'legendre', 'arbitrary'};

myPCE = uq_createModel(metaopts);

pass = pass & strcmpi(myPCE.PCE.Basis.PolyTypes{1}, 'legendre') ...
    & strcmpi(myPCE.PCE.Basis.PolyTypes{2}, 'zero') ...
    & strcmpi(myPCE.PCE.Basis.PolyTypes{3}, 'zero');

pass = pass & (myPCE.PCE.Basis.PolyTypesParams{2} == Input.Marginals(2).Parameters(1)) ...
    & (myPCE.PCE.Basis.PolyTypesParams{3} == Input.Marginals(3).Parameters(1));

pass = pass & (norm(coeffs - myPCE.PCE.Coefficients) < 1e-12);

end