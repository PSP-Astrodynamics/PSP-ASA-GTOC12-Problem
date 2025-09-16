function success = uq_Reliability_test_SSER(level)
% SUCCESS = UQ_RELIABILITY_TEST_SSER(LEVEL):
%     Comparing the results of SSER to the analytical failure
%     probabilities.
%
% See also UQ_SELFTEST_UQ_RELIABILITY

success = 0;

%% Start test:
uqlab('-nosplash');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
seed = 100;
rng(seed)

%% create the input and model

for ii = 1:2
    inputOpts.Marginals(ii).Type = 'Gaussian';
    inputOpts.Marginals(ii).Parameters = [0 1];
end
myInput = uq_createInput(inputOpts,'-private');

%% create the computational model
MOpts.mFile = 'uq_fourbranch';
MOpts.isVectorized = true;

myModel = uq_createModel(MOpts);

% add constant
% to input
inputOpts = myInput.Options;
inputOpts.Marginals(3).Type = 'Constant';
inputOpts.Marginals(3).Parameters = rand(1);
myInput = uq_createInput(inputOpts);

%% analytical failure probability and reliabiltiy index
BetaRef = 2.62;
PFRef = 4.46e-3;

%% SSER analysis
% create reliability model
SSEROptions.Type = 'Reliability';           
SSEROptions.Method = 'SSER';                
SSEROptions.Model = myModel;                
SSEROptions.Input = myInput;                
SSEROptions.Display = 'standard';
SSEROptions.SSER.ExpOptions.TruncOptions.MaxInteraction = 2;
SSEROptions.SSER.ExpOptions.TruncOptions.qNorm = 0.7;
SSEROptions.SSER.ExpOptions.Degree = 0:2;
SSEROptions.SSER.Refine.NExp = 15;

% Experimental design
SSEROptions.SSER.ExpDesign.Sampling = 'Sequential';
SSEROptions.SSER.ExpDesign.NSamples = 250;
SSEROptions.SSER.ExpDesign.NEnrich = 15;

SSEROptions.Display = 1;

mySSERAnalysis = uq_createAnalysis(SSEROptions);
SSERResults = mySSERAnalysis.Results;

%% check the results
% check if reference failure probability is within bounds
if SSERResults.PfCI(1)> PFRef || SSERResults.PfCI(2)< PFRef
    error('probability estimate.\nSSER: %s\nAnalytic: %s', uq_sprintf_mat(SSERResults.Pf), uq_sprintf_mat(PFRef));
elseif SSERResults.BetaCI(1)> BetaRef || SSERResults.BetaCI(2)< BetaRef
    error('reliability index\nSSER: %s\nAnalytic: %s', uq_sprintf_mat(SSERResults.Beta), uq_sprintf_mat(BetaRef));  
end

% verify that bootstrap replications and History field in non-terminal
% domains have been removed
mySSE = mySSERAnalysis.Results.SSER.SSE;
for dd = 1:mySSE.Graph.numnodes
    currSuccessors = successors(mySSE.Graph, dd);
    needNoHistory = true;
    % loop over successors 
    if isempty(currSuccessors)
        % terminal domain
        needNoHistory = false;
    else
        for ss = currSuccessors'
            currExpansion = mySSE.Graph.Nodes.expansions{ss};
            % check for expansion
            if isempty(currExpansion)
                needNoHistory = false;
                break
            elseif all(currExpansion.PCE.Coefficients == 0)
            % check for nonzero expansion
                needNoHistory = false;
                break
            end
        end
    end
    if needNoHistory
        % if no history needed, check whether no history is stored
        currHistory = mySSE.Graph.Nodes.History(dd);
        if ~isempty(currHistory.Y) || ~isempty(currHistory.Yrepl) || ~isempty(currHistory.U) 
            error('Some History fields have not been removed')
        end
    end
end

% display and print
H = uq_display(mySSERAnalysis);
close(H{:})

uq_print(mySSERAnalysis)

% SUCCESS
fprintf('\nTest uq_Reliability_test_SSER finished successfully!\n');
success = 1;
end
