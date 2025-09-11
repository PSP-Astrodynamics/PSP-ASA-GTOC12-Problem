function Proposal = uq_initialize_uq_inversion_proposal(Proposal,PriorVariance)
% UQ_INITIALIZE_UQ_INVERSION_PROPOSAL initializes the proposal distribution
%   used in some MCMC algorithms.
%
%   See also: UQ_INITIALIZE_UQ_INVERSION, UQ_AM, UQ_MH

if isfield(Proposal,'Distribution')
    %custom proposal distribution
    if ~isa(Proposal.Distribution,'uq_input')
        error('Specified proposal distribution is not a uq_input object')
    end
    if isfield(Proposal,'Conditioning')
        % prop cond specified - check
        if ~or(strcmpi(Proposal.Conditioning,'Previous'),...
                strcmpi(Proposal.Conditioning,'Global'))
            error('Specified proposal conditioning is not recognized')
        end
    else
        % use global as default
        Proposal.Conditioning = 'Global';
    end
elseif isfield(Proposal,'Cov')
    %check if size is consistent
    if ~all(size(Proposal.Cov) == length(PriorVariance))
        error('The supplied proposal covariance matrix does not match the full prior distribution')
    end
elseif isfield(Proposal,'PriorScale')
    %check if scalar
    if ~all(size(Proposal.PriorScale) == 1)
        error('The supplied PriorScale is not a scalar')
    end
    %create Cov field that contains the scaled prior variance
    Proposal.Cov = Proposal.PriorScale*diag(PriorVariance);
else
    error('Need to specify custom properties, a Gaussian covariance matrix or a prior scale!');
end
% get proposal handle
Proposal.Handle = @(x) uq_getProposal(Proposal,x);