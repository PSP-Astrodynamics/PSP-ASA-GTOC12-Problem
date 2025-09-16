function Sample = uq_MCMC_assignSample(Sample_Cand, Sample_Curr, acceptedChains)                                    
% UQ_MCMC_ASSIGNSAMPLE assigns the accepted and rejected sample points to
%   the full sample structure
%
%   SAMPLE = UQ_MCMC_ASSIGNSAMPLE(SAMPLE_CAND) takes the sample points 
%   stored in SAMPLE_CAND reshapes them and assigns them to the SAMPLE 
%   3D-ARRAY.
%
%   SAMPLE = UQ_MCMC_ASSIGNSAMPLE(SAMPLE_CAND, SAMPLE_CURR,
%   ACCEPTEDCHAINS) takes the sample points stored in SAMPLE_CAND and
%   SAMPLE_CURR and correctly assigns them to the SAMPLE 3D-ARRAY based on
%   the ACCEPTEDCHAINS logical vector.
%
%   See also: UQ_MH, UQ_AIES, UQ_AM, UQ_HMC  

if nargin == 3
    % assign rejected and accepted sample points
    if any(acceptedChains)
        Sample(1,:,acceptedChains) = Sample_Cand(acceptedChains,:).';
    end
    if any(~acceptedChains)
        Sample(1,:,~acceptedChains) = Sample_Curr(~acceptedChains,:).';
    end
else
    % no acceptedChains passed, assign all Sample_Cand to Sample
    Sample(1,:,:) = Sample_Cand.';
end

