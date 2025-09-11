function [x_cand, logCorrect] = uq_getProposal(Proposal,x_curr)
% UQ_GETPROPOSAL samples from a proposal distribution
%
%   X_CAND = UQ_GETPROPOSAL(PROPOSAL, X_CURR) samples from the distribution 
%   defined by the PROPOSAL structure conditioned on the sample point 
%   X_CURR.
%
%   [X_CAND, LOGCORRECT] = UQ_GETPROPOSAL(PROPOSAL, X_CURR) additionally
%   returns the logarithm of the metropolis-hastings correction factor.
%
%   See also: UQ_CREATECONDITINPUT, UQ_INVERSION

% Initialize
nChains = size(x_curr,1);

if isfield(Proposal,'Cov')
    % Supplied covariance matrix
    % specify sampler and pdf handle
    x_cand = mvnrnd(x_curr,Proposal.Cov,nChains);
    logCorrect = zeros(nChains,1);
else
    % No supplied covariance matrix, use custom proposal
    propDist = Proposal.Distribution;
    propCond = Proposal.Conditioning;
    % switch conditioning methods
    switch lower(propCond)
        case 'global' 
            % no conditioning on current sample
            x_cand = uq_getSample(propDist,nChains);
            logCorrect = ...
                uq_evalLogPDF(x_curr,propDist) - ...
                uq_evalLogPDF(x_cand,propDist);
        case 'previous'
            % condition on current sample - create distribution objects
            propDistCurr = uq_createConditInput(propDist,'mean',x_curr);
            % sample
            x_cand = zeros(size(x_curr));
            for ii = 1:nChains
                x_cand(ii,:) = uq_getSample(propDistCurr{ii},1);
            end
            % condition on candidate sample - create distribution objects
            propDistCand = uq_createConditInput(propDist,'mean',x_cand);
            % get correction factor
            logCorrect = zeros(nChains,1);
            for ii = 1:nChains
                logCorrect(ii) = ...
                    uq_evalLogPDF(x_curr(ii,:),propDistCand{ii}) - ...
                    uq_evalLogPDF(x_cand(ii,:),propDistCurr{ii});
            end
    end
end