function [out, forwardModel] = uq_inversion_likelihood(x,Internal,type)
% UQ_INVERSION_LIKELIHOOD provides the likelihood function used in the
%   Inversion module. 
%
%   OUT = UQ_INVERSION_LIKELIHOOD(X, INTERNAL, TYPE) depending on the TYPE
%   evaluates the likelihood or loglikelihood at parameter point X. This
%   function evaluates the forward models.
%
%   [OUT, FORWARDMODEL] = UQ_INVERSION_LIKELIHOOD(X, INTERNAL, TYPE) also
%   returns the runs of the forward models.
%
%   See also: UQ_INITIALIZE_UQ_INVERSION

%% retrieve model parameters and run forward model
paramDiscrepancyID = Internal.paramDiscrepancyID;
modelParams = x(:,paramDiscrepancyID==0);
for ii = 1:Internal.nForwardModels
    %retreive relevant model params
    modelParamsCurr = modelParams(:,Internal.ForwardModel_WithoutConst(ii).PMap);
    
    %forwardModel(ii).evaluation = uq_evalModel(Internal.ForwardModel_WithoutConst(ii).Model,modelParamsCurr,'hpc');
    forwardModel(ii).evaluation = uq_evalModel(Internal.ForwardModel_WithoutConst(ii).Model,modelParamsCurr);
end

% check that he model runs fit the supplied MOMap
% loop over data groups
for ii = 1:Internal.nDataGroups
    ModelIDCurr = Internal.Data(ii).MOMap(1,:);
    OutputIDCurr = Internal.Data(ii).MOMap(2,:);
    % loop over forward models
    for jj = 1:Internal.nForwardModels
        % get current model runs
        modelRunsCurr = forwardModel(jj).evaluation;
        if max(OutputIDCurr(ModelIDCurr==jj)) > length(modelRunsCurr)
            error('MOMap does not match model output')
        end
    end
end

%% loop over data groups and fill likelihood and logLikelihood vector
nReals = size(x,1); % parameter realizations

switch type % what functions to evaluate
    case 'Likelihood'
        out = ones(nReals,1);
    case 'LogLikelihood'
        out = zeros(nReals,1); 
    otherwise
        error('Wrong likelihood type specified')
end

% loop over data groups
for ii = 1:Internal.nDataGroups
    % extract discrepancy from struct
    discrepancyCurr = Internal.Discrepancy(ii);
    % retrieve relevant model outputs
    ModelIDCurr = Internal.Data(ii).MOMap(1,:);
    OutputIDCurr = Internal.Data(ii).MOMap(2,:);
    
    % fill modelRunsCurr
    modelRunsCurr = nan(size(x,1),length(OutputIDCurr));
    for jj = 1:Internal.nForwardModels
        OutputIDCurrModel = OutputIDCurr(ModelIDCurr == jj);
        modelRunsCurr(:,ModelIDCurr == jj) = forwardModel(jj).evaluation(:,OutputIDCurrModel);
    end
    
    % check that all modelRuns were filled
    if any(isnan(modelRunsCurr(:)))
        error('Some data points were not assigned model outputs')
    end
        
    % get discrepancy param
    if discrepancyCurr.ParamKnown % known parameters
        discrepancyParam = discrepancyCurr.Parameters;
    else
        currID = paramDiscrepancyID == ii;
        discrepancyParam = x(:,currID);
    end

    % evaluate
    switch type % what functions to evaluate
        case 'Likelihood'
            likelihood_curr = discrepancyCurr.likelihood_g(modelRunsCurr,discrepancyParam);
            out = out.*likelihood_curr;
        case 'LogLikelihood'
            logLikelihood_curr = discrepancyCurr.logLikelihood_g(modelRunsCurr,discrepancyParam);
            out = out + logLikelihood_curr;
    end
end
