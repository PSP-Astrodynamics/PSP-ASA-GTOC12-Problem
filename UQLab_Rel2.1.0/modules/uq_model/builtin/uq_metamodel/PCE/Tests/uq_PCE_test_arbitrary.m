function success = uq_PCE_test_arbitrary(level)
% success = UQ_PCE_TEST_ARBITRARY(LEVEL): non-regression test for the
% functionality of the 'arbitrary' option in PCE PolyTypes.
%
% What is tested:
%
%  1) it forces numerical integration of recurrence terms for known 
%     PDFs and understands and respects the bounds set in the input 
%     marginals
% 
%  2) it allows for the usage of mixed PolyTypes parameters and the 
%     previous functionality was not affected,
%
%  3) after the PCE initialization, all the information about what happened
%     is somehow encoded. That is: 
%       3.1) Numerical integration was performed to compute the recurrence terms 
%       3.2) The distribution used in order to compute the recurrence terms is given.
%       3.3) if the distribution had a name (named inputs) the name was retained.

evalc('uqlab');

if(nargin < 1 )
    % not really that type of test... 
    % we can set the degree though:
    maxdegree = 15;
else
    if strcmpi(level,'normal')
        maxdegree = 15;
    else
        maxdegree = 22;
    end
end

success = 0;
%% Test setup:

% Keep test results somewhere:
test = {};
% create an input and a PCE model
% Make a truncated distribution
Input.Marginals(1).Type       = 'Uniform' ;
Input.Marginals(1).Parameters = [0 1] ;
Input.Marginals(1).Bounds     = [0 0.9];
Input.Marginals(1).Name       = 'FoobarUniform';

Input.Marginals(2).Type       = 'Gaussian' ;
Input.Marginals(2).Parameters = [0.1 0.7] ;
Input.Marginals(2).Name       = 'FoobarGaussian';

% A distribution that needs parameters:
Input.Marginals(3).Type       = 'Gamma' ;
Input.Marginals(3).Parameters = [15, 3] ;
Input.Marginals(3).Name       = 'FoobarGamma';

myInput = uq_createInput(Input);


%% Model initialization:
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'PCE';
metaopts.Method = 'ols';
metaopts.Degree = 2:maxdegree;
metaopts.Input = myInput;

% Specify a sparse truncation scheme: hyperbolic norm with q = 0.75
metaopts.TruncOptions.qNorm = 1;
metaopts.ExpDesign.NSamples = 500;
metaopts.ExpDesign.Sampling = 'LHS';

% Create a model object that uses the Ishigami function:
modelopts.mFile    = 'uq_ishigami' ;      % specify the function name
FullModel          = uq_createModel(modelopts); % create and add the model object to UQLab


metaopts.FullModel = FullModel;



%% 1) Check that numerical determintatino of recurrence terms 
%%    is performed during PCE initialization:
metaopts_1           = metaopts;
metaopts_1.PolyTypes = {'arbitrary','arbitrary','arbitrary'};

test_model_1 = uq_createModel(metaopts_1);

test{1,1} = {all(cellfun(@(x) strcmpi(x, 'arbitrary'),test_model_1.PCE.Basis.PolyTypes )), 'Basis in PCE output is set to arbitrary'};

test{2,1} = {strcmpi(test_model_1.PCE.Basis.PolyTypesParams{1}.pdfname,'Uniform') && ...
             strcmpi(test_model_1.PCE.Basis.PolyTypesParams{2}.pdfname, 'Gaussian') && ...
             strcmpi(test_model_1.PCE.Basis.PolyTypesParams{3}.pdfname, 'Gamma') , 'The correct distributions were used for the integration.'};

test{3,1} = {all(test_model_1.PCE.Basis.PolyTypesParams{1}.bounds == [0 0.9]) && ...
             all(test_model_1.PCE.Basis.PolyTypesParams{1}.parameters == [0 1]) && ...
             all(test_model_1.PCE.Basis.PolyTypesParams{2}.parameters == [0.1 0.7]) && ...
             all(test_model_1.PCE.Basis.PolyTypesParams{3}.parameters == [15 3]) && ...
             all(test_model_1.PCE.Basis.PolyTypesParams{3}.bounds == [0 inf]) , 'The correct parameters and bounds were used.'};

%% 2) Mixed PolyTypes and PolyTypesParams definition test
metaopts_2 = metaopts;
metaopts_2.PolyTypes = {'arbitrary','Hermite','Laguerre'};
% The Hermite parameters should be taken from the Marginal. 
% The Laguerre parameters should be taken from here!
metaopts_2.PolyTypesParams = {[],[], [14 2.5]};
test_model_2 = uq_createModel(metaopts_2);
test{4,1} = {strcmpi(test_model_2.PCE.Basis.PolyTypes{1},'arbitrary') && ...
    strcmpi(test_model_2.PCE.Basis.PolyTypes{2},'Hermite') && ...
    strcmpi(test_model_2.PCE.Basis.PolyTypes{3},'Laguerre'),'PolyTypes gives results consistent and backwards compatible'};

test{5,1} = {strcmpi(test_model_2.PCE.Basis.PolyTypesParams{1}.pdfname,'Uniform') && ...
    all(test_model_2.PCE.Basis.PolyTypesParams{2} == [] ) && ...
    all(test_model_2.PCE.Basis.PolyTypesParams{3} == [14 2.5]) ,'The parameters of the polynomials are properly passed around.'};

%% Return the test results
success = all(cellfun(@(x) x{1} == 1,test));
