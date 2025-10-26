function status = uq_akmcs_stopPf(CurrentAnalysis)
% status = UQ_AKMCS_STOPPF(CurrentAnalysis) computes stopping criterion 
%     with respect to the estimated failure probability as described in
%     Schobi et al, 2016, Rare event estimation using Polynomial-Chaos-Kriging,
%     ASCE-ASME Journal of Risk and Uncertainty in Engineering Systems, PArt A:
%     Civil Engineering, D4016002
% 
% See also: UQ_AKMCS, UQ_AKMCS_STOPU, UQ_AKMCS_STOPBETA

gmean = CurrentAnalysis.Internal.Runtime.gmean;
gs = CurrentAnalysis.Internal.Runtime.gs;
g = CurrentAnalysis.Internal.Runtime.g;

MCSampleSize = length(gmean) + length(CurrentAnalysis.Internal.Runtime.g(CurrentAnalysis.Internal.AKMCS.IExpDesign.N+1:end)); 

%Estimate the current Pf and Pf+ and Pf-
Pf = (sum(gmean <= 0) + sum(g(CurrentAnalysis.Internal.AKMCS.IExpDesign.N+1:end) <= 0))/MCSampleSize;
Pfplus = (sum(gmean-2*gs <= 0) + sum(g(CurrentAnalysis.Internal.AKMCS.IExpDesign.N+1:end) <= 0))/MCSampleSize;
Pfminus = (sum(gmean+2*gs <= 0) + sum(g(CurrentAnalysis.Internal.AKMCS.IExpDesign.N+1:end) <= 0))/MCSampleSize;

delta = 0.10;

%Check whether convergence has been reached for teh second time in a row
if isfield(CurrentAnalysis.Internal.Runtime, 'Pfstop')
    if (Pfplus-Pfminus)/ Pf <= delta && CurrentAnalysis.Internal.Runtime.Pfstop == 1
        status = 1;
    else if (Pfplus-Pfminus)/ Pf <= delta
            status = 0;
            CurrentAnalysis.Internal.Runtime.Pfstop = 1;
        else
            status = 0;
            CurrentAnalysis.Internal.Runtime.Pfstop = 1;
        end
    end
else
    if (Pfplus-Pfminus)/ Pf <= delta
        CurrentAnalysis.Internal.Runtime.Pfstop = 1;
        status = 0;
    else
        status = 0;
        CurrentAnalysis.Internal.Runtime.Pfstop = 0;
    end
end