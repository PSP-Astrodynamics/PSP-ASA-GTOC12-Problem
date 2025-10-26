function success = uq_Reliability_test_ALR_BlockComb_ED(level)
% SUCCESS = UQ_RELIABILITY_TEST_ALR_BLOCKCOMB_ED(LEVEL)
%     Computing active learning models with different combinations of
%     Surrogate model, reliability analysis, learning function and stopping
%     criterion plus various specifications of the initial ED

%% Start test:
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
seed = 1;

%% create the input
M = 2;
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
    for ii = 1:5
        
        clear alropts
        alropts.Type = 'Reliability';
        alropts.Method = 'ALR';
        alropts.Simulation.BatchSize = 1e3;
        alropts.Simulation.MaxSampleSize = 1e3;
        alropts.ALR.MaxAddedED = 1;
        alropts.LimitState.Threshold = 0;
        alropts.LimitState.CompOp = '<=';
        alropts.Display = 'quiet';
        
        if ii == 1
            % test Kriging - MC - ED with N
            alropts.ALR.Metamodel = 'Kriging' ;
            alropts.ALR.Reliability = 'MC';
            
            alropts.ALR.IExpDesign.N = 20;
            
        elseif ii == 2
            % test PCK with subset + EFF with X given but not G
            alropts.ALR.Metamodel = 'PC-Kriging' ;
            alropts.ALR.Reliability = 'Subset';
            alropts.ALR.LearningFunction = 'EFF' ;
            alropts.ALR.Convergence = 'StopPfBound' ;
            alropts.ALR.IExpDesign.X = uq_getSample(20, 'LHS');
            
        elseif ii == 3
            % test PCE with IS + X and Y given
            alropts.ALR.Metamodel = 'PCE' ;
            alropts.ALR.Reliability = 'IS';
            alropts.ALR.IExpDesign.X = uq_getSample(20, 'MC');
            alropts.ALR.IExpDesign.G = uq_evalModel(myModel,...
                uq_getSample(20, 'MC'));
        elseif ii == 4
            % test SVR with stopping criterion stopBeta
            alropts.ALR.Metamodel = 'SVR' ;
            alropts.ALR.Reliability = 'MC';
            alropts.ALR.Convergence = 'StopBetaStab' ;

            
        else
            % test ALR with another stopping criterion
            alropts.ALR.Metamodel = 'LRA' ;
            alropts.ALR.Reliability = 'MC';
            alropts.ALR.Convergence = 'StopPfStab' ;

        end
        
        % to avoid any print on the screen use evalc
        [~,ALRAnalysis] = evalc('uq_createAnalysis(alropts)');

    end
    
    % Test will fail if any of the cases produces an error.
    success = 1;
catch me
end
%% check the results
if success == 0
    ErrStr = sprintf('\nError in uq_Reliability_test_ALR_ED: %s\n', me.message);
    rethrow(me)
end
