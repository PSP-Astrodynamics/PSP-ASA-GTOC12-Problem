function status = uq_akmcs_stopU(CurrentAnalysis)
% UQ_AKMCS_STOPU checks the convergence of the AK-MCS based on the 
% U-function of each sample
% 
% See also: UQ_AKMCS, UQ_AKMCS_STOPPF, UQ_AKMCS_STOPBETA

minU = min(abs(CurrentAnalysis.Internal.Runtime.gmean./CurrentAnalysis.Internal.Runtime.gs));

if minU >= 2
    status = 1;
else
    status = 0;
end