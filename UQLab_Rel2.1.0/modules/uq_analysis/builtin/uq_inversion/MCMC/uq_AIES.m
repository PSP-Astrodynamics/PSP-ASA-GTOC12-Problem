function [Sample,Accept,Time,ForwardModel, LogLikeliEval] = uq_AIES(Steps, ...
                                        Seed, a, LogPrior, LogLikelihood, ... 
                                        Visualize, StoreModel)
% UQ_AIES implements the affine invariant ensemble MCMC algorithm 
%   described in GOODMAN et al. (2010) to sample from a posterior 
%   distribution.
%
%   SAMPLE = UQ_AIES(STEPS, SEED, A, LOGPRIOR, LOGLIKELIHOOD, VISUALIZE, 
%   STOREMODEL) samples from the posterior distribution defined by the product: 
%   LOGPRIOR*LOGLIKELIHOOD. The algorithm tuning parameter is A. STEPS is 
%   the number of undertaken MCMC iterations starting from the SEED points. 
%   VISUALIZE is a structure containing options to show trace plots of the 
%   sample chains at runtime. STOREMODEL is a logical variable determining 
%   if the forward model evaluations are stored at runtime. SAMPLE is a 
%   3D array containing the produced sample points.
%   
%   [SAMPLE, ACCEPT, TIME, FORWARDMODEL, LOGLIKELIEVAL] = UQ_AIES(STEPS, 
%   SEED, A, LOGPRIOR, LOGLIKELIHOOD, VISUALIZE) additionally returns the 
%   acceptance rate ACCEPT per chain, the total required execution time 
%   TIME, the forward model runs FORWARDMODEL and the corresponding 
%   log-likelihood evaluations LOGLIKELIEVAL.
%
%   References:
%
%   - J. Goodman, J., Weare. Ensemble samplers with affine invariance.
%     Comm. Appl. Math. Comp. Sci. 5:65-80, 2010
%
%   See also: UQ_INVERSION, UQ_TRACEPLOT, UQ_AM, UQ_MH, UQ_HMC

% CHECK INPUT
if size(Seed,3) < 2
  error('The AIES algorithm requires at least 2 parallel chains!');
end
if or((numel(Steps) ~= 1),(mod(Steps,1) ~= 0))
  error('The number of steps is not an integer!');
end
if (numel(a) ~= 1)
  error('The parameter a is a matrix!');
end
if (a < 1)
  error('The parameter a is smaller than 1!');
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

% initialize ensemble parameters
zConst1 = 1/(2*sqrt(a)-2/sqrt(a)); %normalization for z pdf
zConst2 = 2*zConst1*sqrt(1/a); %normalization for z cdf (F(z)=0@ z=1/a)

% initial state
Sample(1,:,:) = Seed;

% first likelihood evaluation
if StoreModel
    [logLKLHD_Curr, forwardModel_Curr] = LogLikelihood(reshape(Seed,nDim,nChains).');
else
    logLKLHD_Curr = LogLikelihood(reshape(Seed,nDim,nChains).');
    % Return empty object
    ForwardModel = [];
end

% preallocate likelihood evaluations
LogLikeliEval = zeros(Steps,nChains);
LogLikeliEval(1,:) = logLKLHD_Curr.';

% preallocate and store model runs
if StoreModel
    % save number of forward models
    nForwardModels = length(forwardModel_Curr);
    % loop over forward models
    for mm = 1:length(forwardModel_Curr)
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
    Sample_Curr(:,:) = permute(Sample(ii-1,:,:),[1 3 2]);

    %%%%%%%%%%%%%%%%%%%%%%%%
    %      CHAIN LOOP      %
    %%%%%%%%%%%%%%%%%%%%%%%%

    for ll = 1:nChains
        % extract log likelihood for current chain
        logLKLHD_CurrChain = logLKLHD_Curr(ll);

        % pick random chain from complementary ensemble
        ensembleIndices = 1:nChains;
        ensembleIndices(ll) = []; %remove current chain
        ensembleChain = randsample(ensembleIndices,1);

        Sample_Compl = Sample_Curr(ensembleChain,:);
        Sample_CurrChain = Sample_Curr(ll,:);

        % sample z~q(z) through inverse cummulative distribution
        u = rand;
        z = ((u+zConst2)/(2*zConst1)).^2;

        % proposal
        Sample_Cand = Sample_Compl + z*(Sample_CurrChain-Sample_Compl);

        % prior evaluation
        logPrior_Cand = LogPrior(Sample_Cand);
        logPrior_Curr = LogPrior(Sample_CurrChain);

        % if prior is 0 don't evaluate likelihood
        if isinf(logPrior_Cand)
            logLKLHD_Cand = -Inf; %reject
        else
            if StoreModel
                [logLKLHD_Cand,  forwardModel_Cand] = LogLikelihood(Sample_Cand);
            else
                logLKLHD_Cand = LogLikelihood(Sample_Cand);
            end

        end

        % alpha
        logAlpha = (logLKLHD_Cand + logPrior_Cand) ...
                - (logLKLHD_CurrChain + logPrior_Curr)...
                + (nDim-1)*log(z);
        alpha    = exp(logAlpha);

        % metropolis-hastings acceptance
        u = rand;
        acceptChain = (u <= alpha);
        
        % update acceptance counter
        Accept(ll) = Accept(ll) + acceptChain;
        
        % accept or reject
        if acceptChain
            % accept 
            Sample_Curr(ll,:) = Sample_Cand;
            % update log likelihood 
            logLKLHD_Curr(ll) = logLKLHD_Cand;
        end
        
        % store loglikelihood evaluations
        LogLikeliEval(ii,ll) = logLKLHD_Curr(ll);
        
        %%%%%%%%%%%%%%%%%%%%%%%
        % STORE FORWARD MODEL %
        %%%%%%%%%%%%%%%%%%%%%%%
        if StoreModel
            % loop over forward models
            for mm = 1:nForwardModels
                % get model runs of current state
                ModelEval_Curr = ForwardModel(mm).evaluation(ii-1,:,ll);
                % check if prior was rejected or not
                if ~isinf(logPrior_Cand)
                    ModelEval_Cand = forwardModel_Cand(mm).evaluation;
                else
                    ModelEval_Cand = [];
                end
                % assign
                ForwardModel(mm).evaluation(ii,:,ll) = ...
                    uq_MCMC_assignForwardRun(ModelEval_Cand, ModelEval_Curr, acceptChain);
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    % STORE SAMPLE HISTORY %
    %%%%%%%%%%%%%%%%%%%%%%%%
    Sample(ii,:,:) = uq_MCMC_assignSample(Sample_Curr);
    
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

% FINALIZATION
Time = toc(Time1);
Accept = (Accept / Steps).';