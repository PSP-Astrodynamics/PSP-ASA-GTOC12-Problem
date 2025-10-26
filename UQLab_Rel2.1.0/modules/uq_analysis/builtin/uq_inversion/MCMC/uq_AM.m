function [Sample,Accept,Time, ForwardModel, LogLikeliEval] = uq_AM(Steps, ...
                                      Seed, T0, Epsilon, Proposal, LogPrior, ...
                                      LogLikelihood, Visualize, StoreModel)
% UQ_AM implements the adaptive Metropolis MCMC algorithm described in 
%   HAARIO et al. (2001) to sample from a posterior distribution.
%
%   SAMPLE = UQ_AM(STEPS, SEED, T0, EPSILON, PROPOSAL, LOGPRIOR, 
%   LOGLIKELIHOOD, VISUALIZE, STOREMODEL) samples from the posterior distribution 
%   defined by the product: LOGPRIOR*LOGLIKELIHOOD. The algorithm tuning 
%   parameters are T0 and EPSILON. A handle to the proposal distribution is 
%   specified by PROPOSAL. STEPS is the number of undertaken MCMC 
%   iterations starting from the SEED points. VISUALIZE is a structure 
%   containing options to show trace plots of the sample chains at runtime. 
%   STOREMODEL is a logical variable determining if the forward 
%   model evaluations are stored at runtime. SAMPLE is a 3D array containing
%   the produced sample points.
%   
%   [SAMPLE, ACCEPT, TIME, FORWARDMODEL, LOGLIKELIEVAL] = UQ_AM(STEPS, SEED,
%   T0, EPSILON, PROPOSAL, LOGPRIOR, LOGLIKELIHOOD, VISUALIZE, STOREMODEL) 
%   additionally returns the acceptance rate ACCEPT per chain, the total 
%   required execution time TIME, the forward model runs FORWARDMODEL and
%   the corresponding log-likelihood evaluations LOGLIKELIEVAL.
%
%   References:
%
%   - H. Haario, E., Saksman, J. Tamminen. An adaptive Metropolis algorithm.
%     Bernoulli. 7:223-242, 2001
%
%   See also: UQ_INVERSION, UQ_TRACEPLOT, UQ_AIES, UQ_MH, UQ_HMC

% CHECK INPUT
if or((numel(Steps) ~= 1),(mod(Steps,1) ~= 0))
  error('The number of steps is not an integer!');
end
if or((numel(T0) ~= 1),(mod(T0,1) ~= 0))
  error('The number of initial steps is not an integer!');
end

%%%%%%%%%%%%%%%%%%
% INITIALIZATION %
%%%%%%%%%%%%%%%%%%
nPlotStep = Visualize.Interval; %plot steps  
plotParameters = Visualize.Parameters; %plot variable
Time1 = tic;
[~,nDim,nChains] = size(Seed);
Accept = zeros(nChains,1);

% adaptivity parameters
C_ad = zeros(nDim,nDim,nChains); %initialize adaptive covariance
SampleMean = reshape(Seed,nDim,nChains).'; %initialize mean for recursive mean computation
SampleMean_Prev = reshape(Seed,nDim,nChains).';
sd = 2.38^2/nDim; %scaling parameter (see Haario et al 2001)
eps = Epsilon;%ensures non-singularity of covariance matrix

% preallocation
Sample = zeros(Steps,nDim,nChains);
Sample_Curr = zeros(nChains,nDim);
Sample_Cand = zeros(nChains,nDim);

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

    % adaptive covariance proposal
    if ii > 2
        % change proposal covariance for each chain
        for jj = 1:nChains
            % get current and previous sample/mean
            currSample = Sample_Curr(jj,:).';
            prevSampleMean = SampleMean_Prev(jj,:).';
            currSampleMean = SampleMean(jj,:).';
            % update covariance to iith recursive covariance estimator
            t = ii-2;
            C_curr = C_ad(:,:,jj)*(t-1)/t + ...
                sd/t*(t*prevSampleMean*prevSampleMean.'-(t+1)*currSampleMean*currSampleMean.' + currSample*currSample.');
%             Test that covariance recursion formula is correct
%             norm(sd*cov(Sample(1:ii-1,:,jj))-C_curr)
            % ensure symmetry
            C_ad(:,:,jj) = (C_curr + C_curr.')/2;       
        end
    end

    % proposal
    if ii <= T0
        % use initially specified proposal
        [Sample_Cand, logCorrection] = Proposal(Sample_Curr);
    else
        % use adaptive proposal
        for jj = 1:nChains
            try
                % add diagonal term to correlation matrix to avoid singularity
                C_eps = C_ad(:,:,jj) + eps*eye(nDim);
                Sample_Cand(jj,:) = mvnrnd(Sample_Curr(jj,:),C_eps);
            catch
                error('Possibly increase epsilon constant in AM sampler.')
            end
        end
        % no correction for symmetric proposal (Gaussian)
        logCorrection = zeros(nChains,1);
    end
    
    % prior Evaluation
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
            logLKLHD_Cand(~outOfBounds) = ...
                LogLikelihood(Sample_Cand(~outOfBounds,:));
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

    % update sample mean
    SampleMean_Prev = SampleMean;
    SampleMean(acceptedChains,:) = ...
        SampleMean(acceptedChains,:)*(ii-1)/ii + Sample_Cand(acceptedChains,:)/ii; %mean for accepted
    SampleMean(~acceptedChains,:) = ...
        SampleMean(~acceptedChains,:)*(ii-1)/ii + Sample_Curr(~acceptedChains,:)/ii; %mean for rejected

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
    
    % assign sample points
    Sample(ii,:,:) = uq_MCMC_assignSample(Sample_Cand,Sample_Curr,acceptedChains);
    
    % assign forward model runs
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