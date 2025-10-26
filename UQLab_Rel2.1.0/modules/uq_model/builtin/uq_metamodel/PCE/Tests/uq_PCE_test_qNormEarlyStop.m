function pass = uq_PCE_test_qNormEarlyStop( level )
% PASS = UQ_PCE_TEST_QNORMEARLYSTOP(LEVEL): test whether q-norm adaptivity, 
% in particular the option qNormEarlyStop == true (default), arrives at 
% the same solution as when the best degree and q-norm are determined 
% manually 

% Initialize test:
pass = 1;
evalc('uqlab');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_PCE_test_qNormEarlyStop...\n']);

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
rng(500);
samplesizes = 10:20:120;


for ii = 1:length(samplesizes)
    clear metaopts

    XED = uq_getSample(myInput,samplesizes(ii),'Sobol');
    YED = uq_evalModel(FullModel,XED);

    metaopts.Type = 'metamodel';
    metaopts.MetaType = 'PCE';
    metaopts.Method = 'LARS';
    metaopts.Input = myInput;
    metaopts.FullModel = FullModel;
    metaopts.DegreeEarlyStop = false; % necessary to pass the test (for N = 30)
    % here we only want to test q-norm adaptivity
    metaopts.LARS.LarsEarlyStop = true;
    metaopts.ExpDesign.X = XED;
    metaopts.ExpDesign.Y = YED;
    
    metaopts.Display = 0;

    qNormArray = 0.5:0.05:1;
    degreeArray = 5:10;

    LOO_array = zeros(numel(degreeArray), numel(qNormArray));

    %% Don't stop early
    % Use all combinations of p and q and record the LOO error
    for pp = 1:numel(degreeArray)
        for qq = 1:numel(qNormArray)
            metaopts.Degree = degreeArray(pp);
            metaopts.TruncOptions.qNorm = qNormArray(qq);

            myPCE = uq_createModel(metaopts,'-private');

            LOO_array(pp, qq) = myPCE.Error.ModifiedLOO;
        end
    end

    [min_LOO_qq, ind_min_qq] = min(LOO_array, [], 2);
    [~, ind_min_pp] = min(min_LOO_qq);

    % Use UQLab without qNormEarlyStop
    metaopts.qNormEarlyStop = false;
    metaopts.Degree = degreeArray;
    metaopts.TruncOptions.qNorm = qNormArray;
    myPCE_noEarlyStop = uq_createModel(metaopts,'-private');

    % Check if the final best of UQlab and manual computation coincide
    pass = pass & (degreeArray(ind_min_pp) == myPCE_noEarlyStop.PCE.Basis.Degree);
    pass = pass & (qNormArray(ind_min_qq(ind_min_pp)) == myPCE_noEarlyStop.PCE.Basis.qNorm);

    %% With qNormEarlyStop == true
    metaopts.qNormEarlyStop = true;
    myPCE_withEarlyStop = uq_createModel(metaopts,'-private');

    % mimic q-norm early stop
    LOO_array_copy = LOO_array;
    LOO_increase_array = (diff(LOO_array,1,2) < 0); % 1 = decrease in LOO
    for pp = 1:numel(degreeArray)
        for qq = 2:numel(qNormArray)-1
            if LOO_increase_array(pp, qq-1)+LOO_increase_array(pp, qq) == 0
                LOO_array_copy(pp, qq+1:end) = inf;
            end
        end
    end
    [min_LOO_qq, ind_min_qq] = min(LOO_array_copy, [], 2);
    [~, ind_min_pp] = min(min_LOO_qq);

    % Check if the final best of UQlab and manual computation coincide
    pass = pass & (degreeArray(ind_min_pp) == myPCE_withEarlyStop.PCE.Basis.Degree);
    pass = pass & (qNormArray(ind_min_qq(ind_min_pp)) == myPCE_withEarlyStop.PCE.Basis.qNorm);

end
