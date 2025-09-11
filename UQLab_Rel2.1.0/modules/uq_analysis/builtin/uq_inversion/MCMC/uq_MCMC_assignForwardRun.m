function ModelEval = uq_MCMC_assignForwardRun(ModelEval_Cand, ModelEval_Curr, ...
                                           acceptedChains, outOfBounds)                                    
% UQ_MCMC_ASSIGNFORWARDRUN assigns the accepted and rejected forward runs
%   to the full forard runs matrix
%
%   MODELEVAL = UQ_MCMC_ASSIGNFORWARDRUN(MODELEVAL_CAND, MODELEVAL_CURR,
%   ACCEPTEDCHAINS) takes the sample points stored in MODELEVAL_CAND and 
%   MODELEVAL_CURR and correctly assigns them to the MODELEVAL 3D-ARRAY
%   based on the ACCEPTEDCHAINS logical vector
%
%   MODELEVAL = UQ_MCMC_ASSIGNFORWARDRUN(MODELEVAL_CAND, MODELEVAL_CURR,
%   ACCEPTEDCHAINS, OUTOFBOUNDS) additionally considers that some 
%   OUTOFBOUNDS sample points were removed initially.
%
%   See also: UQ_MH, UQ_AIES, UQ_AM, UQ_HMC  

if nargin > 3
    % OUTOFBOUNDS given, modify accepted Chains
    acceptedChains_mod = acceptedChains(~outOfBounds);
else
    acceptedChains_mod = acceptedChains;
end

% initialize
Nout = max(size(ModelEval_Cand,2), size(ModelEval_Curr,2));
ModelEval = zeros(1,Nout,length(acceptedChains));

% accepted Chains
% get indices of accepted not out of bounds sample points
ModelEval(1,:,acceptedChains) = ModelEval_Cand(acceptedChains_mod,:).';
% rejected Chains
ModelEval(1,:,~acceptedChains) = ModelEval_Curr(1,:,~acceptedChains);
