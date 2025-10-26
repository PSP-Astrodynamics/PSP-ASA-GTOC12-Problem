function success = uq_Reliability_test_AKMCS_ED(level)
% SUCCESS = UQ_RELIABILITY_TEST_AKMCS_ED(LEVEL)
%     Computing AK-MCS models with different specification of the initial
%     experimental design, learning function and convergence criterion

%% Start test:
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
seed = 1;

%% create the input
M = 5;
for ii = 1:M
    IOpts.Marginals(ii).Name = 'R';
    IOpts.Marginals(ii).Type = 'Gaussian';
    IOpts.Marginals(ii).Moments = [1 1];
end

% Create the input:
uq_createInput(IOpts);

%% create the computational model
MOpts.mString = 'sum(X,2)';
MOpts.isVectorized = true;
myModel = uq_createModel(MOpts);

%% AK-MCS
rng(seed)
success = 0;
try
    % for each learning function
    for ii = 1:2

        % for each convergence criterion    
        for jj = 1:2

            % for each initial experimental design setting    
            for kk = 1:4
                clear akopts
                akopts.Type = 'Reliability';
                akopts.Method = 'AKMCS';
                akopts.Simulation.BatchSize = 1e3;
                akopts.Simulation.MaxSampleSize = 1e3;
                akopts.AKMCS.MaxAddedED = 1;
                akopts.LimitState.Threshold = 0;
                akopts.LimitState.CompOp = '<=';
                akopts.Display = 'quiet';
                akopts.AKMCS.Kriging.Optim.Method = 'none';
                akopts.AKMCS.Kriging.Optim.InitialValue = [1 1 1 1 1];

                if ii == 1
                    akopts.AKMCS.LearningFunction = 'U';
                else
                    akopts.AKMCS.LearningFunction = 'EFF';
                end

                if jj == 1
                    akopts.AKMCS.Convergence = 'stopPf';
                else
                    akopts.AKMCS.Convergence = 'stopU';
                end

                switch kk
                    case 1
                        akopts.AKMCS.IExpDesign.N = 20;
                    case 2
                        akopts.AKMCS.IExpDesign.X = uq_getSample(20, 'LHS');
                    case 3
                       akopts.AKMCS.IExpDesign.X = uq_getSample(20, 'MC'); 
                       akopts.AKMCS.IExpDesign.G = uq_evalModel(myModel,...
                           uq_getSample(20, 'MC'));
                end

            AKAnalysis = uq_createAnalysis(akopts);
            end
        end
    end
    
    % Test will fail if any of the cases produces an error.
    success = 1;
catch me
end
%% check the results
if success == 0
    ErrStr = sprintf('\nError in uq_test_AKMCS_ED: %s\n', me.message);
    rethrow(me)
end
