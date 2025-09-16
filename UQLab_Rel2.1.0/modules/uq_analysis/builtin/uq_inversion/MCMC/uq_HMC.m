function [Sample,Accept,Time,ForwardModel,LogLikeliEval] = uq_HMC( Steps, ...
                                        LeapfrogSteps, LeapfrogSize, Mass, ...
                                        Seed, LogPrior, LogLikelihood, ...
                                        Visualize, StoreModel, Marginals)
% UQ_HMC implements the Hamiltonian Monte Carlo MCMC algorithm 
%   described in NEAL (2010) to sample from a posterior distribution.
%
%   SAMPLE = UQ_HMC(STEPS, LEAPFROGSTEPS, LEAPFROGSIZE, MASS, SEED, 
%   LOGPRIOR, LOGLIKELIHOOD, VISUALIZE, STOREMODEL, MARGINALS) samples from
%   the posterior distribution defined by the product: LOGPRIOR*LOGLIKELIHOOD. 
%   The algorithm tuning parameters are the number of leapfrog integrator 
%   steps LEAPFROGSTEPS, step size LEAPFROGSIZE and the mass matrix MASS. 
%   STEPS is the number of undertaken MCMC iterations starting from the 
%   SEED points. VISUALIZE is a structure containing options to show trace 
%   plots of the sample chains at runtime. STOREMODEL is a logical variable 
%   determining if the forward model evaluations are stored at runtime.
%   MARGINALS are the prior marginals used to scale the gradient
%   estimation. SAMPLE is a 3D array containing the produced sample points.
%   
%   [SAMPLE, ACCEPT, TIME, FORWARDMODEL, LOGLIKELIEVAL] = UQ_HMC(STEPS, 
%   LEAPFROGSTEPS, LEAPFROGSIZE, MASS, SEED, LOGPRIOR, LOGLIKELIHOOD, 
%   VISUALIZE, STOREMODEL, MARGINALS) additionally returns the acceptance
%   rate ACCEPT per chain, the total required execution time TIME, the 
%   forward model runs FORWARDMODEL and the corresponding log-likelihood 
%   evaluations LOGLIKELIEVAL.
%
%   References:
%
%   - R.M. Neal. MCMC using Hamiltonian dynamics. Handbook of Markov Chain
%     Monte Carlo, 54:113-162, 2010
%
%   See also: UQ_INVERSION, UQ_TRACEPLOT, UQ_AM, UQ_MH, UQ_AIES                                    
                                    
% CHECK INPUT
if or((numel(Steps) ~= 1),(mod(Steps,1) ~= 0))
  error('The number of steps is not an integer!');
end
if or((numel(LeapfrogSteps) ~= 1),(mod(LeapfrogSteps,1) ~= 0))
  error('The number of leapfrog steps is not an integer!');
end
if ~and(size(LeapfrogSize,1) == 1,size(LeapfrogSize,2) == 1)
  error('Size has to be a scalar!');
end

%%%%%%%%%%%%%%%%%%
% INITIALIZATION %
%%%%%%%%%%%%%%%%%%

nPlotStep = Visualize.Interval; %plot steps  
plotParameters = Visualize.Parameters; %plot variable
Time1 = tic;
[~,nDim,nChains] = size(Seed);
Accept = zeros(nChains,1);
% compute inverse of mass matrix
if isdiag(Mass)
    invMass = diag(1./diag(Mass));
else
    invMass = inv(Mass);
end

% handle to U
U = @(x) -LogPrior(x) -LogLikelihood(x);

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
    % current state with finite difference
    Sample_Curr(:,:) = permute(Sample(ii-1,:,:),[1 3 2]);
    % compute gradient
    [U_Curr_Grad,U_Curr] = ...
        uq_gradient(Sample_Curr, U, 'forward', 'relative', 1e-3, -LogPrior(Sample_Curr)-logLKLHD_Curr, Marginals);
    % check if out of bounds, compute with backwards option
    outOfBoundsGradient = any(isinf(U_Curr_Grad),2);
    if ~all(~outOfBoundsGradient)
        U_Curr_Grad(outOfBoundsGradient,:) = ...
        uq_gradient(Sample_Curr(outOfBoundsGradient,:), U, 'backward', 'relative', 1e-3, -LogPrior(Sample_Curr)-logLKLHD_Curr, Marginals);
    end
    % draw momentum from standard normal
    Momentum_Curr = normrnd(0,1,[nChains,nDim]);

    %%%%%%%%%%%%%%%%%%%%%
    %   LEAPFROG LOOP   %
    %%%%%%%%%%%%%%%%%%%%%
    % initialize
    Sample_Cand = Sample_Curr;
    outOfBounds = false(size(Sample_Cand,1),1);
    % make half step for momentum
    Momentum_Cand = Momentum_Curr - U_Curr_Grad/2*LeapfrogSize;
    for h = 1:LeapfrogSteps
        % current state with finite difference
        Sample_Cand = Sample_Cand + Momentum_Cand*invMass*LeapfrogSize;
        % get samples that have an infinite log prior (out of bounds)
        outOfBounds = logical(outOfBounds + isinf(LogPrior(Sample_Cand)));
        % compute gradient
        U_Cand_Grad = zeros(nChains,nDim);
        if ~all(outOfBounds)
            U_Cand_Grad(~outOfBounds,:) = ...
                uq_gradient(Sample_Cand(~outOfBounds,:), U, ...
                'forward', 'relative', 1e-3, Marginals);
            % check if out of bounds, compute with backwards option
            outOfBoundsGradient = any(isinf(U_Cand_Grad),2);
            if ~all(~outOfBoundsGradient)
                U_Cand_Grad(outOfBoundsGradient,:) = ...
                uq_gradient(Sample_Cand(outOfBoundsGradient,:), U, ...
                'backward', 'relative', 1e-3, Marginals);
            end
        else
            % stop leapfrog integration
            break
        end

        if (h~=LeapfrogSteps)
            % make full momentum step
            Momentum_Cand = Momentum_Cand - U_Cand_Grad*LeapfrogSize;
        end
    end
    % put the out of bounds candidates back to their original position
    Sample_Cand(outOfBounds,:) = Sample_Curr(outOfBounds,:);

    % compute U_CAND (with likelihood evaluation)
    if StoreModel
        [logLKLHD_Cand, forwardModel_Cand] = LogLikelihood(Sample_Cand);
    else
        logLKLHD_Cand = LogLikelihood(Sample_Cand);
    end
    U_Cand = -LogPrior(Sample_Cand) - logLKLHD_Cand;

    % make half step for momentum at end
    Momentum_Cand = Momentum_Cand - U_Cand_Grad*LeapfrogSize/2;

    % negate momentum for symmetry
    Momentum_Cand = -Momentum_Cand;

    % evaluate energies at end and beginning of hamiltonian step
    % for performance distinguish between diagonal and full mass matrix
    if isdiag(Mass)
        % faster
        MassDivisor = repmat(diag(invMass).',nChains,1);
        K_Curr = sum((Momentum_Curr.^2).*MassDivisor,2)/2;
        K_Cand = sum((Momentum_Cand.^2).*MassDivisor,2)/2;
    else
        % slower
        K_Curr = zeros(nChains,1); 
        K_Cand = zeros(nChains,1);
        for jj = 1:nChains
            K_Curr(jj) = (Momentum_Curr(jj,:)*invMass)*Momentum_Curr(jj,:).'/2;
            K_Cand(jj) = (Momentum_Curr(jj,:)*invMass)*Momentum_Cand(jj,:).'/2;
        end
    end

    % hmc alpha
    logAlpha = U_Curr-U_Cand+K_Curr-K_Cand;
    alpha = exp(logAlpha);

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
    
    % assign sample points
    Sample(ii,:,:) = uq_MCMC_assignSample(Sample_Cand,Sample_Curr,acceptedChains);

    % assign forward model runs
    if StoreModel
        % loop over forward models
        for mm = 1:nForwardModels
            % get model runs of current state
            ModelEval_Curr = ForwardModel(mm).evaluation(ii-1,:,:);
            ModelEval_Cand = forwardModel_Cand(mm).evaluation;
            % assign
            ForwardModel(mm).evaluation(ii,:,:) = ...
                uq_MCMC_assignForwardRun(ModelEval_Cand, ModelEval_Curr, acceptedChains);
        end
    end

    % update progressbar
    if Visualize.Display > 0
        if mod(ii,ceil(Steps/nProgressBarRefresh)) == 0 || ii == Steps
            uq_textProgressBar(ii/Steps)
        end
    end
    
    % plot function
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
Accept = Accept / Steps; 