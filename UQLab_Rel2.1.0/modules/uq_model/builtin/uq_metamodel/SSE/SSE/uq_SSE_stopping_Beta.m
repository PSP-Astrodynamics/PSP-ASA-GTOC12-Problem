function stopBool = uq_SSE_stopping_Beta(obj)
% UQ_SSE_STOPPING_BETA returns whether stopping criterion based on the 
%    beta bounds is met or not.

% extract evolution
evolution = uq_SSE_extractPfBeta(obj);

% has converged?
thresh = 5e-2;
stoppingCrit = diff(evolution.Beta(:,2:3),[],2)./evolution.Beta(:,1) < thresh;

% init
nConsec = 3;

% check for stopping
if obj.currRef >= nConsec
    stopBool = all(stoppingCrit(end-nConsec+1:end));
else
    stopBool = false;
end

end