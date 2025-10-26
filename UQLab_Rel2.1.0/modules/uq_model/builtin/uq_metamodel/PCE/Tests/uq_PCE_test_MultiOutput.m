function pass = uq_PCE_test_MultiOutput( level )
% PASS = UQ_PCE_TEST_MULTIOUTPUT(LEVEL): check if the PCE set-up works for
% different kinds of PCE's


eps = 1e-6;
pceMethods = {'OLS','LARS','OMP','Quadrature','Smolyak', 'SP', 'BCS'};
% Initialize test:
pass = 0;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_MultiOutput...\n']);

%% INPUT
% values taken from the default phimecasoft example
% Define the probabilistic model.
for ii = 1:3
    Input.Marginals(ii).Type = 'Uniform' ;
    Input.Marginals(ii).Parameters = [-pi, pi] ;
end

myInput = uq_createInput(Input);

%% MODEL
% Physical model: Ishigami function
modelopts.Name = 'ishigami multiout test';
modelopts.mFile = 'uq_ishigami_various_outputs' ;
evalc('FullModel = uq_createModel(modelopts)');


%% PCE Metamodel
for ii = 1 : length(pceMethods)
    clear metaopts
    
    metaopts.Type = 'metamodel';
    metaopts.MetaType = 'PCE';
    metaopts.Input = myInput ;
    metaopts.FullModel = FullModel;
    
    metaopts.Method = pceMethods{ii};
    metaopts.Degree = 5:10;
    
    switch lower(metaopts.Method)
        case {'ols', 'lars', 'omp', 'bcs', 'sp'}
            metaopts.ExpDesign.Sampling = 'Sobol';
            metaopts.ExpDesign.NSamples = 250;
            metaopts.TruncOptions.qNorm = 0.75;
        case 'quadrature'
            metaopts.Method = 'Quadrature';
            metaopts.Quadrature.Type = 'Full';
        case 'smolyak'
            metaopts.Method = 'Quadrature';
            metaopts.Quadrature.Type = 'Smolyak';
    end
    try
        evalc('myPCE = uq_createModel(metaopts)');
        evalc('uq_print(myPCE,1)');
        evalc('uq_print(myPCE,2)');
        evalc('H = uq_display(myPCE,[1 2])');
    catch ME
        rethrow(ME)
    end
end
close all
pass=1;

