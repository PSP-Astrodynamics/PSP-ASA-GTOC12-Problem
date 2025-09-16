function pass = uq_PCE_test_qNormAdapt( level )
% PASS = UQ_PCE_TEST_QNORMADAPT(LEVEL): non-regression test for qNorm
% adaptive PCE, check if they get the same degree and qNorm as before.

% Initialize test:
pass = 1;
evalc('uqlab');
rng(500);
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_PCE_test_qNormAdapt...\n']);

%% INPUT
% Define the probabilistic model.
for i = 1:3
    Input.Marginals(i).Type = 'Uniform';
    Input.Marginals(i).Parameters = [-pi, pi];
end

myInput = uq_createInput(Input,'-private');

%% MODEL
% Physical model: Ishigami function
modelopts.Name = 'ishigami test';
modelopts.mFile = 'uq_ishigami';
FullModel = uq_createModel(modelopts,'-private');

%% PCE Metamodel
samplesizes = 10:20:200;
degrees = [6   10  10  8   10  10  10  10  10   10];
qnorms =  [0.5 0.7 0.5 0.6 0.7 0.9 0.7 0.5 0.75 1.0];

for ii = 1 : length(samplesizes)
    rng(500);

    clear metaopts
    
    XED = uq_getSample(myInput,samplesizes(ii),'Sobol');
    YED = uq_evalModel(FullModel,XED);
    
    metaopts.Type = 'metamodel';
    metaopts.MetaType = 'PCE';
    metaopts.Method = 'LARS';
    metaopts.Input = myInput;
    metaopts.FullModel = FullModel;
    metaopts.qNormEarlyStop = true;
    metaopts.DegreeEarlyStop = true;
    metaopts.LARS.LarsEarlyStop = true;
    metaopts.ExpDesign.X = XED;
    metaopts.ExpDesign.Y = YED;
       
    metaopts.Degree = 5:10;
    metaopts.TruncOptions.qNorm = 0.5:0.05:1;
    
    metaopts.Display = 0;    
    myPCE = uq_createModel(metaopts,'-private');
    
    %% Validation
    % check p and q
    pass = pass & myPCE.PCE.Basis.qNorm == qnorms(ii);
    pass = pass & myPCE.PCE.Basis.Degree == degrees(ii);

end
