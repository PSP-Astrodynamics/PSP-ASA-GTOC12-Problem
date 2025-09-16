function [Sample,Accept,Time,ForwardModel,LogLikeliEval] = uq_MH(  Steps,...
                                        Seed, Proposal, LogPrior, ...
                                        LogLikelihood, Visualize,...
                                        StoreModel)                                    
% UQ_MH implements the Metropolis-Hastings MCMC algorithm described in 
%   HASTINGS (1970) to sample from a posterior distribution.
%
%   SAMPLE = UQ_MH(STEPS, SEED, PROPOSAL, LOGPRIOR, LOGLIKELIHOOD, 
%   VISUALIZE, STOREMODEL) samples from the posterior distribution defined 
%   by the product: LOGPRIOR*LOGLIKELIHOOD. A handle to the proposal 
%   distribution is specified by PROPOSAL. STEPS is the number of 
%   undertaken MCMC iterations starting from the SEED points. VISUALIZE is 
%   a structure containing options to show trace plots of the sample chains
%   at runtime. STOREMODEL is a logical variable determining if the forward 
%   model evaluations are stored at runtime. SAMPLE is a 3D array 
%   containing the produced sample points.
%   
%   [SAMPLE, ACCEPT, TIME, FORWARDMODEL, LOGLIKELIEVAL] = UQ_MH(STEPS, 
%   SEED, PROPOSAL, LOGPRIOR, LOGLIKELIHOOD, VISUALIZE, STOREMODEL) 
%   additionally returns the acceptance rate ACCEPT per chain, the total 
%   required execution time TIME, the forward model runs FORWARDMODEL and
%   the corresponding log-likelihood evaluations LOGLIKELIEVAL.
%
%   References:
%
%   - W.K. Hastings. Monte Carlo sampling methods using Markov chains and 
%     their applications. Biometrika. 57:97-109, 1970
%
%   See also: UQ_INVERSION, UQ_TRACEPLOT, UQ_AIES, UQ_AM, UQ_HMC  

% CHECK INPUT
if or((numel(Steps) ~= 1),(mod(Steps,1) ~= 0))
  error('The number of steps is not an integer!');
end

%%%%%%%%%%%%%%%%%%
% INITIALIZATION %
%%%%%%%%%%%%%%%%%%

nPlotStep = Visualize.Interval; %plot steps  
plotParameters = Visualize.Parameters; %plot variable
Time1 = tic;
[~,nDim,nChains] = size(Seed);
Accept = zeros(nChains,1);

% preallocate sample history
Sample = zeros(Steps,nDim,nChains);
Sample_Curr = zeros(nChains,nDim);

% initial state
Sample(1,:,:) = Seed;

% first likelihood evaluation
if StoreModel
    [logLKLHD_Curr, forwardModel_Curr] = LogLikelihood(reshape(Seed,nDim,nChains).');
else
    logLKLHD_Curr = LogLikelihood(reshape(Seed,nDim,nChains).');
    % return empty object
    ForwardModel = [];
end
    
logLKLHD_Cand = zeros(nChains,1);

% preallocate likelihood evaluations
LogLikeliEval = zeros(Steps,nChains);
LogLikeliEval(1,:) = logLKLHD_Curr.';

% preallocate and store model runs
if StoreModel
    % save number of forward models
    nForwardModels = length(forwardModel_Curr);
    % loop over forward models
    for mm = 1:nForwardModels
        % extract runs of current forward model
        currModelEval = forwardModel_Curr(mm).evaluation;
        Nout = size(currModelEval,2);
        % preallocate
        ForwardModel(mm).evaluation = zeros(Steps,Nout,nChains);
        % store current runs
        ForwardModel(mm).evaluation(1,:,:) = currModelEval.';
    end
end

% initialize progress bar
nProgressBarRefresh = 200;
if Visualize.Display > 0
    uq_textProgressBar(0)
end

%%%%%%%%%%%%%%%%%%
% ITERATION LOOP %
%%%%%%%%%%%%%%%%%%

for ii = 2:Steps    
    % current state
    Sample_Curr(:,:) = permute(Sample(ii-1,:,:),[1 3 2]);
    % sample candidate and compute correction
    [Sample_Cand, logCorrection] = Proposal(Sample_Curr);

    % prior evaluation
    logPrior_Cand = LogPrior(Sample_Cand);
    logPrior_Curr = LogPrior(Sample_Curr);

    % if prior is 0 don't evaluate likelihood
    outOfBounds = isinf(logPrior_Cand);

    % likelihood evaluation
    if 0 ~= sum(~outOfBounds)
        if StoreModel
            [logLKLHD_Cand(~outOfBounds), forwardModel_Cand] = ...
                LogLikelihood(Sample_Cand(~outOfBounds,:));
        else
            logLKLHD_Cand(~outOfBounds) = LogLikelihood(Sample_Cand(~outOfBounds,:));
        end
    end
    logLKLHD_Cand(outOfBounds) = -Inf; %reject

    % alpha
    logAlpha = (logLKLHD_Cand + logPrior_Cand) ...
            - (logLKLHD_Curr + logPrior_Curr) + ...
            logCorrection;
    alpha    = exp(logAlpha);

    % metropolis-hastings acceptance
    u = rand(nChains,1);
    acceptedChains = (u <= alpha);	

    % update acceptance counter
    Accept = Accept + acceptedChains;

    % update log likelihood
    logLKLHD_Curr(acceptedChains) = logLKLHD_Cand(acceptedChains);
    logLKLHD_Curr(~acceptedChains) = logLKLHD_Curr(~acceptedChains);

    %%%%%%%%%%%%%%%%%%
    % STORE  HISTORY %
    %%%%%%%%%%%%%%%%%%
    
    % store loglikelihood evaluations
    LogLikeliEval(ii,:) = logLKLHD_Curr.';
    
    % store sample points
    Sample(ii,:,:) = uq_MCMC_assignSample(Sample_Cand,Sample_Curr,acceptedChains);

    % store forward model runs
    if StoreModel
        % loop over forward models
        for mm = 1:nForwardModels
            % get model runs of current state
            ModelEval_Curr = ForwardModel(mm).evaluation(ii-1,:,:);
            % check if all out of bounds
            if 0 ~= sum(~outOfBounds)
                ModelEval_Cand = forwardModel_Cand(mm).evaluation;
            else
                ModelEval_Cand = [];
            end
            % assign
            ForwardModel(mm).evaluation(ii,:,:) = ...
                uq_MCMC_assignForwardRun(ModelEval_Cand, ModelEval_Curr, acceptedChains, outOfBounds);
        end
    end
    
    % update progressbar
    if Visualize.Display > 0
        if mod(ii,ceil(Steps/nProgressBarRefresh)) == 0 || ii == Steps
            uq_textProgressBar(ii/Steps)
        end
    end
    
    % call plot function
    if and(mod(ii,nPlotStep) == 0,plotParameters > 0)
        %plotHandle = uq_traceplot(plotHandle,ii,plotParameters,Sample);
        % labels
        for pp = 1:length(plotParameters)
            plotParametersString{pp} = sprintf('$X_{%i}$',plotParameters(pp));
        end
        if ~exist('plotHandle','var')
            % first time
            plotHandle = uq_traceplot(Sample(1:ii,plotParameters,:),...
                'labels',plotParametersString);
        else
            % later
            plotHandle = uq_traceplot(plotHandle, Sample(1:ii,plotParameters,:),...
                'labels',plotParametersString);
        end
    end
end

% finalization
Time = toc(Time1);
Accept = (Accept / Steps).';