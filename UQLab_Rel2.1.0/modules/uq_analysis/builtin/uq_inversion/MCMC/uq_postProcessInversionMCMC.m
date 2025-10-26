function module = uq_postProcessInversionMCMC(module, varargin)
% UQ_POSTPROCESSINVERSIONMCMC post-processes an inverse analysis carried out
%    with the Bayesian inversion module of UQLab and any MCMC solver.
%
%    UQ_POSTPROCESSINVERSIONMCMC(MODULE, NAME, VALUE) allows to choose
%    more post processing options by specifying Name/Value pairs:
%
%       Name                  VALUE
%       'burnIn'              Removes the burn in from the sample,
%                             specified as a fraction (between 0 and 1) or
%                             an Integer smaller than the number of
%                             MCMC iterations
%                             - Double or Integer
%                             default : 0.5
%       'badChains'           Removes chains specified by their id from the
%                             sample
%                             - Integer
%                             default : []
%       'pointEstimate'       Computes a point estimate based on the
%                             supplied sample.
%                             - String : ('Mean','MAP','None')
%                             - n x M Double 
%                             - Cell array of the above
%                             default : 'Mean'
%       'dependence'          Estimates the posterior correlation and
%                             covariance matrix
%                             - Logical 
%                             default : true
%       'percentiles'         Computes dimension-wise percentiles of 
%                             supplied sample.
%                             - Double
%                             default : [0.025, 0.975]
%       'gelmanRubin'         Computes the Rubin-Gelman scale reduction
%                             factor
%                             - Logical
%                             default : false
%       'prior'               Samples specified number of sample points 
%                             from the prior distribution.
%                             - Integer
%                             default : 1,000
%       'priorPredictive'     Samples specified number of sample points 
%                             from the prior predictive distribution. This 
%                             requires additional calls to the forward 
%                             models
%                             - Integer
%                             default : 0
%       'posteriorPredictive' Samples specified number of sample points 
%                             from the posterior predictive distribution.
%                             - Integer
%                             default : 1,000
%                          
% See also: UQ_PRINT_UQ_INVERSION, UQ_DISPLAY_UQ_INVERSION

%% CONSISTENCY CHECKS
if ~strcmp(module.Type, 'uq_inversion')
    error('uq_postProcessInversionMCMC only operates on objects of type ''Inversion''') 
end

%check if MCMC Solver
if ~strcmp(module.Internal.Solver.Type, 'MCMC')
    error('No results to post-process')
end

% switch if custom likelihood
if module.Internal.customLikeli
    CUSTOM_LIKELI = true;
else
    CUSTOM_LIKELI = false;
end

%% INITIALIZE
% get Sample
Sample = module.Results.Sample;

% get loglikelihood
LogLikeliEval = module.Results.LogLikeliEval;

% get forward model evaluations
if ~isempty(module.Results.ForwardModel)
    forwardModelRuns_flag = true;
    ForwardModelRuns = module.Results.ForwardModel;
else
    forwardModelRuns_flag = false;
end

% number of forward models
if ~CUSTOM_LIKELI
    nForwardModels = length(module.ForwardModel);
else
    nForwardModels = 1;
end
    
% get length variables
[nIter,nDim,nChains] = size(Sample);

% get indices of discrepancy Sample excluding constants
modelIndices = find(module.Internal.paramDiscrepancyID == 0);

%% Default behavior
% Burn in
Default.burnIn_flag = true;
Default.burnIn = floor(nIter/2); %discard half the chain
% Point estimate
Default.pointEstimate_flag = true;
Default.pointEstimate = {'Mean'};
% Dependence indices
Default.dependence_flag = true;
% Prior sample
Default.prior_flag = true;
Default.nPriorSamples = 1000;
% Percentiles
Default.percentiles_flag = true;
Default.perc_probabilities = [0.025; 0.975];
if ~CUSTOM_LIKELI
    % only do predictive distributions if no user-specified likelihood
    % Posterior predictive
    Default.posteriorPredictive_flag = true;
    Default.nPostPredSamples = 1000;
    % Prior predictive
    Default.priorPredictive_flag = false;
    Default.nPriorPredSamples = 0;
else
    % Posterior predictive
    Default.posteriorPredictive_flag = false;
    Default.nPostPredSamples = 0;
    % Prior predictive
    Default.priorPredictive_flag = false;
    Default.nPriorPredSamples = 0;
end
% Bad chains
Default.badChains_flag = false;
% Gelman Rubin
Default.gelmanRubin_flag = true;

%% Check for input arguments
%set optional arguments
parse_keys = {'burnin', 'badchains', 'pointestimate','dependence',...
    'percentiles', 'gelmanrubin', 'prior','priorpredictive', ...
    'posteriorpredictive'};
parse_types = {'p','p','p','p','p','p','p','p','p'};

if nargin > 1
    % vargin given
    % make NAME lower case
    varargin(1:2:end) = lower(varargin(1:2:end));
    [uq_cline, ~] = uq_simple_parser(varargin, parse_keys, parse_types);
else
    % no vargin, use default options
    nOpts = length(parse_keys);
    uq_cline = cell(nOpts,1);
    for ii = 1:nOpts
        uq_cline{ii} = 'false';
    end
end

% 'burnIn' option removes burnin from the sample
if ~strcmp(uq_cline{1}, 'false')
    burnIn_flag = true;
    if uq_cline{1} == 0
        burnIn_flag = false;
    elseif floor(uq_cline{1})==uq_cline{1}
        %integer passed
        burnIn = uq_cline{1};
    elseif and(uq_cline{1} >= 0, uq_cline{1} <= 1)
        %fraction passed
        burnIn = floor(uq_cline{1}*size(module.Results.Sample,1));
    else
        error('Argument of burnIn not valid.')    
    end
else
    burnIn_flag = Default.burnIn_flag;
    burnIn = Default.burnIn;
end

% 'badChains' option removes chains specified by badChains from the
% sample
if ~strcmp(uq_cline{2}, 'false')
    badChains = uq_cline{2};
    if badChains == 0
        badChains = [];
    end
    if islogical(badChains)
        badChains = find(badChains);
        if size(badChains,1) > size(badChains,2)
            badChains = badChains';
        end
    end


    badChains_flag = true;
    if max(badChains > nChains)
        error('Argument of badChains not valid.')    
    end
else
    badChains_flag = Default.badChains_flag;
end

% 'pointEstimate' option adds a point estimate
[pointEstimate, pointEstimate_flag, pointParamIn, Results] = .....
    uq_postProcessInversion_initPointEstimate(uq_cline{3}, Default, module.Results, nDim);
module.Results = Results;

% 'dependence' estimates the correlation matrix from the available sample
if ~strcmp(uq_cline{4}, 'false')
    dependence_flag = uq_cline{4};
    if dependence_flag == false
        % remove possibly existing dependence field
        if isfield(module.Results,'PostProc')
            if isfield(module.Results.PostProc,'Dependence')
                module.Results.PostProc = rmfield(module.Results.PostProc,'Dependence');
            end
        end
    end
else
    dependence_flag = Default.dependence_flag;
end

% 'percentiles' computes the dimensionwise percentiles of the sample
if ~strcmp(uq_cline{5}, 'false')
    percentiles_flag = true;
    perc_probabilities = uq_cline{5};
    if isempty(perc_probabilities)
        percentiles_flag = false;
        % remove possibly existing percentiles field
        if isfield(module.Results,'PostProc')
            if isfield(module.Results.PostProc,'Percentiles')
                module.Results.PostProc = rmfield(module.Results.PostProc,'Percentiles');
            end
        end
    elseif or(max(perc_probabilities) > 1, min(perc_probabilities) < 0)
        % supplied percentiles are out of bounds
        error('The percentiles are not between [0,1].')
    end
else
    percentiles_flag = Default.percentiles_flag;
    perc_probabilities = Default.perc_probabilities;
end

% 'gelmanRubin' computes the Gelman-Rubin scale reduction factor 
if ~strcmp(uq_cline{6}, 'false')
    gelmanRubin_flag = uq_cline{6};
    if ~gelmanRubin_flag
        % remove possibly existing gelman rubin field
        if isfield(module.Results,'PostProc')
            if isfield(module.Results.PostProc,'MPSRF')
                module.Results.PostProc = rmfield(module.Results.PostProc,'MPSRF');
            end
        end
    end
else
    gelmanRubin_flag = Default.gelmanRubin_flag;
end

% 'prior' draws samples from the prior distribution
if ~strcmp(uq_cline{7}, 'false')
    nPriorSamples = uq_cline{7};
    if nPriorSamples > 0
        prior_flag = true;
    else
        prior_flag = false;
        % and remove possibly existing prior sample
        if isfield(module.Results,'PostProc')
            if isfield(module.Results.PostProc,'PriorSample')
                module.Results.PostProc = rmfield(module.Results.PostProc,'PriorSample');
            end
        end
    end
else
    prior_flag = Default.prior_flag;
    nPriorSamples = Default.nPriorSamples;
end

% 'priorPredictive' draws samples from the prior predictive
% distribution
if ~strcmp(uq_cline{8}, 'false')
    if CUSTOM_LIKELI
        error('Predictive distributions are not supported with user-specified likelihood functions.')
    end
    nPriorPredSamples = uq_cline{8};
    if nPriorPredSamples > 0
        priorPredictive_flag = true;
    else
        priorPredictive_flag = false;
        % and remove possibly existing prior predictive sample
        if isfield(module.Results,'PostProc')
            if isfield(module.Results.PostProc,'PriorPredSample')
                module.Results.PostProc = rmfield(module.Results.PostProc,'PriorPredSample');
            end
        end
    end
else
    priorPredictive_flag = Default.priorPredictive_flag;
    nPriorPredSamples = Default.nPriorPredSamples;
end

% 'postPredictive' draws samples from the posterior predictive
% distribution
if ~strcmp(uq_cline{9}, 'false')
    if CUSTOM_LIKELI
        error('Predictive distributions are not supported with user-specified likelihood functions.')
    end
    nPostPredSamples = uq_cline{9};
    if nPostPredSamples > 0 
        if forwardModelRuns_flag
            posteriorPredictive_flag = true;
        else
            warning('Forward model evaluations were not stored by MCMC sampler, cannot produce predictive sample.')
        end
    else
        posteriorPredictive_flag = false;
        % and remove possibly existing posterior predictive sample
        if isfield(module.Results,'PostProc')
            if isfield(module.Results.PostProc,'PostPredSample')
                module.Results.PostProc = rmfield(module.Results.PostProc,'PostPredSample');
            end
        end
    end
    % check if sufficient samples are available
    if nPostPredSamples > (nIter-burnIn)*nChains
        % too many posterior predictive samples requested, just use
        % nSamples
        warning('Requested posterior predictive sample exceeds available sample size, using available sample instead...')
        nPostPredSamples = (nIter-burnIn)*nChains;
    end
else
    posteriorPredictive_flag = Default.posteriorPredictive_flag;
    if ~forwardModelRuns_flag
        % turn off if no samples were generated by MCMC sampler
        posteriorPredictive_flag = false;
    end
    nPostPredSamples = min(Default.nPostPredSamples, (nIter-burnIn)*nChains);
end

%% PREPROCESSING - MODIFICATIONS OF SAMPLE
if burnIn_flag
    % preprocessing was chosen
    % remove the burn in
    % ensure that burnIn is smaller than the number of Sample
    if burnIn >= size(Sample,1)
        error('Burn in as large or larger than number of sample points per chain')
    end
    Sample = Sample(burnIn+1:end,:,:);
    
    % logliklihood evaluations
    LogLikeliEval = LogLikeliEval(burnIn+1:end,:);
    
    if forwardModelRuns_flag
        % model evaluations
        for mm = 1:nForwardModels
            ForwardModelRuns(mm).evaluation = ...
                ForwardModelRuns(mm).evaluation(burnIn+1:end,:,:);
        end
    end
end

if badChains_flag
    % preprocessing was chosen
    % remove the bad chains
    goodChains = 1:nChains; 
    goodChains(badChains) = [];
    Sample = Sample(:,:,goodChains);
    
    % logliklihood evaluations
    LogLikeliEval = LogLikeliEval(:,goodChains);
    
    if forwardModelRuns_flag
        % model evaluations
        for mm = 1:nForwardModels
            ForwardModelRuns(mm).evaluation = ...
                ForwardModelRuns(mm).evaluation(:,:,goodChains);
        end
    end
    
    % return bad chains index to analysis object
    module.Results.PostProc.ChainsQuality.BadChains = badChains;
    module.Results.PostProc.ChainsQuality.GoodChains = goodChains;
end

%Return to analysis object
module.Results.PostProc.PostSample = Sample;
module.Results.PostProc.PostLogLikeliEval = LogLikeliEval;
if forwardModelRuns_flag
    module.Results.PostProc.PostModel = ForwardModelRuns;
end

%% Combine chains
% Sample
Sample3D = Sample;
Sample2D = reshape(permute(Sample,[2 1 3]),nDim,[]).';

% LogLikelihood
LogLikelihood3D = LogLikeliEval;
LogLikelihood2D = reshape(LogLikeliEval,[],1);

if forwardModelRuns_flag
    % Forward model
    ForwardModelRuns3D = ForwardModelRuns;
    for mm = 1:nForwardModels
        nOut = size(ForwardModelRuns(mm).evaluation,2);
        ForwardModelRuns2D(mm).evaluation = ...
            reshape(permute(ForwardModelRuns(mm).evaluation,[2 1 3]),nOut,[]).';
    end
end

%% Further operations
if pointEstimate_flag
    % loop over point estimators
    for pp = 1:length(pointEstimate)
        switch lower(pointEstimate{pp})
            case 'mean'
                % set to posterior mean
                pointParam{pp} = uq_inversion_mean(Sample3D);
            case 'map'
                % take the sample with the maximum (unnormalized) posterior
                % density as the MAP
                LogLikelihood = LogLikelihood2D;
                LogPrior = uq_evalLogPDF(Sample2D,module.Internal.FullPrior);
                [~,maxIndex] = max(LogLikelihood + LogPrior);
                % maximum sample is the MAP
                pointParam{pp} = Sample2D(maxIndex,:);            
            case 'custom'
                % do nothing
                pointParam{pp} = pointParamIn{pp};
        end
    end
    
    % if any predictive distribution samples are computed, add also point
    % prediction
    if priorPredictive_flag || posteriorPredictive_flag
        for pp = 1:length(pointEstimate)
            % loop over forward models
            for mm = 1:nForwardModels
                % get current PMap
                PMapCurr = module.Internal.ForwardModel_WithoutConst(mm).PMap;
                % get relevan parameter and remove discrepancy terms
                pointParamModel = pointParam{pp}(:,modelIndices);
                pointParamCurrModel = pointParamModel(:,PMapCurr);
                % evaluate forward model at this point
                ForwardRun{pp}(mm).Out = uq_evalModel(module.Internal.ForwardModel_WithoutConst(mm).Model,pointParamCurrModel);
                ForwardRun{pp}(mm).Type = pointEstimate{pp};
            end
        end
        % Return to analysis object
        module.Results.PostProc.PointEstimate.ForwardRun = ForwardRun;
    end
    
    % Return to analysis object
    module.Results.PostProc.PointEstimate.X = pointParam;
    module.Results.PostProc.PointEstimate.Type = pointEstimate;
end

if dependence_flag
    % use Sample2D to compute the correlation matrix
    covariance = cov(Sample2D);
    correlation = corr(Sample2D);
    
    % return results
    module.Results.PostProc.Dependence.Corr = correlation;
    module.Results.PostProc.Dependence.Cov = covariance;
end

if percentiles_flag
   % compute percentiles from supplied sample
   percentiles = uq_inversion_percentiles(Sample3D, perc_probabilities);
   % compute also mean and variance
   [perc_mean, perc_var] = uq_inversion_mean(Sample3D);
   
   % return percentiles to analysis object
   module.Results.PostProc.Percentiles.Values = percentiles;
   module.Results.PostProc.Percentiles.Probabilities = perc_probabilities;
   module.Results.PostProc.Percentiles.Mean = perc_mean;
   module.Results.PostProc.Percentiles.Var = perc_var;
end

if gelmanRubin_flag
    % compute potential scale reduction factor (if at least two 
    % chains are available)
    [nSamples,nDim,nChains] = size(Sample3D);
    if nChains > 1
        %within-sequence variance 
        W = zeros(nDim);
        chainMeans = zeros(nChains,nDim);
        for ii = 1:nChains
            samplesCurr = squeeze(Sample3D(:,:,ii));
            W = W+cov(samplesCurr);
            chainMeans(ii,:) = mean(samplesCurr);
        end
        W = W/nChains;

        %between-sequence variance
        B = cov(chainMeans);

        %scale reduction factor
        try
            tempMat = W\B;
            MPSRF = nSamples/(nSamples+1)+(nChains+1)/nChains*eigs(tempMat,1);
        catch
            disp('Gelman-Rubin MPSRF could not be calculated, probably due to poor conditioning')
            MPSRF = NaN;
        end
    else
        disp('At least two chains are required to compute the Gelman-Rubin scale reduction factor!')
    end
    %Return to analysis object
    module.Results.PostProc.MPSRF = MPSRF;
end

%% SAMPLING FROM DISTRIBUTIONS

if prior_flag
    % draw prior samples
    nSamples = nPriorSamples;
    PriorSample = uq_getSample(module.Internal.FullPrior ,nSamples);
    
    % Return to analysis object
    module.Results.PostProc.PriorSample = PriorSample;
end

if priorPredictive_flag
    % compute the prior predictive
    % prior Sample
    priorSample = uq_getSample(module.PriorDist,nPriorPredSamples);
    priorSampleModel = priorSample(:,modelIndices);
    
    % loop over forward models
    for mm = 1:nForwardModels
        % get current PMap
        PMapCurr = module.Internal.ForwardModel_WithoutConst(mm).PMap;
        % prior Runs
        priorSampleCurrModel = priorSampleModel(:, PMapCurr);
        model(mm).priorRuns = uq_evalModel(module.Internal.ForwardModel_WithoutConst(mm).Model,priorSampleCurrModel);
    end
    
    %loop over data groups
    for ii = 1:module.Internal.nDataGroups
        % get currents
        yCurr = module.Internal.Data(ii).y;
        discrepancyCurr = module.Internal.Discrepancy(ii);
        %get model output index
        MOMap = module.Internal.Data(ii).MOMap;
        %use MOMap to extract prior runs relevant for the current
        %data group
        modelEvals = zeros(nPriorPredSamples,size(yCurr,2));
        predSample = zeros(nPriorPredSamples,size(yCurr,2));
        for mm = 1:module.Internal.nForwardModels
            MIndex = MOMap(1,:)==mm;
            OMapCurr = MOMap(2,MIndex);
            if any(MIndex)
                modelEvals(:,MIndex) = model(mm).priorRuns(:,OMapCurr);
            end
        end
        %add discrepancy from likelihood Sample to the current prior/priorerior runs 
        if strcmp(discrepancyCurr.Type,'Gaussian')
            if discrepancyCurr.ParamKnown
                % Known discrepancy
                discrParamCurr = discrepancyCurr.Parameters;
                % draw Sample from the conditional distribution
                % loop over nPriorPredSamples
                for kk = 1:nPriorPredSamples
                    predSample(kk,:) = ...
                        discrepancyCurr.likelihoodSamples_g(modelEvals(kk,:), discrParamCurr);
                end
            else
                % Unknown discrepancy
                %get index
                currParamIndex = module.Internal.paramDiscrepancyID == ii;
                discrParamCurr = priorSample(:,currParamIndex);
                %loop over sample points
                for kk = 1:nPriorPredSamples
                    predSample(kk,:) = ...
                        discrepancyCurr.likelihoodSamples_g(modelEvals(kk,:), discrParamCurr(kk,:));
                end
            end
            % compute discrepancy
            discrepancy = predSample - modelEvals;
        else
            error('Prior predictive samples cannot be drawn for the current discrepancy model')
        end
        
        % Store in priorRuns and priorPredictive structure
        PredSample(ii).ModelEvaluations = modelEvals;
        PredSample(ii).Sample = predSample;
        PredSample(ii).Discrepancy = discrepancy;
    end
    
    % Return to analysis object
    module.Results.PostProc.PriorPredSample = PredSample;
end

%clear model variable
clear model Runs

if posteriorPredictive_flag
    % compute the post predictive
    nSamples = size(Sample2D,1);
    % extract nPostPredSamples from posterior sample
    usedIndices = ceil(rand(nPostPredSamples,1)*nSamples);
    % posterior samples
    postSample = Sample2D(usedIndices,:);
    
    %loop over forward models
    for mm = 1:nForwardModels
        % post Runs
        model(mm).postRuns = ForwardModelRuns2D(mm).evaluation(usedIndices,:);
        model(mm).postPredRuns = zeros(size(model(mm).postRuns));
    end
    
    %loop over data groups
    for ii = 1:module.Internal.nDataGroups
        % get currents
        yCurr = module.Internal.Data(ii).y;
        discrepancyCurr = module.Internal.Discrepancy(ii);
        %get model output index
        MOMap = module.Internal.Data(ii).MOMap;
        %use MOMap to extract posterior runs relevant for the current
        %data group
        modelEvals = zeros(nPostPredSamples,size(yCurr,2));
        predSample = zeros(nPostPredSamples,size(yCurr,2));
        for mm = 1:module.Internal.nForwardModels
            MIndex = MOMap(1,:)==mm;
            OMapCurr = MOMap(2,MIndex);
            if any(MIndex)
                modelEvals(:,MIndex) = model(mm).postRuns(:,OMapCurr);
            end
        end
        %add discrepancy from likelihood Sample to the current posterior runs 
        if strcmpi(discrepancyCurr.Type,'gaussian')
            if discrepancyCurr.ParamKnown
                % Known discrepancy
                % draw Sample from the conditional distribution
                % loop over nPostPredSamples Sample
                for kk = 1:nPostPredSamples
                    predSample(kk,:) = ...
                        discrepancyCurr.likelihoodSamples_g(modelEvals(kk,:),discrepancyCurr.Parameters);
                end
            else
                % Unknown discrepancy
                %get index
                currParamIndex = module.Internal.paramDiscrepancyID == ii;
                postSamplesDiscrepancyCurr = postSample(:,currParamIndex);
                %loop over sample points
                for kk = 1:nPostPredSamples
                    predSample(kk,:) = ...
                        discrepancyCurr.likelihoodSamples_g(modelEvals(kk,:),postSamplesDiscrepancyCurr(kk,:));
                end
            end
            % compute discrepancy
            discrepancy = predSample - modelEvals;
        else
            error('This discrepancy model is not supported for this computation')
        end
        
        % Store in postRuns and postPred structure
        PredSample(ii).ModelEvaluations = modelEvals;
        PredSample(ii).Sample = predSample;
        PredSample(ii).Discrepancy = discrepancy;
    end
    
    % Return to analysis object
    module.Results.PostProc.PostPredSample = PredSample;
end