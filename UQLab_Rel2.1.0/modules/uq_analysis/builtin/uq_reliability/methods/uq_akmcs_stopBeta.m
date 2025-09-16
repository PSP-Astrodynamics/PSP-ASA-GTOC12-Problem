function status = uq_akmcs_stopBeta(CurrentAnalysis)
% status = UQ_AKMCS_STOPPF(CurrentAnalysis) computes stopping criterion 
%     with respect to the estimated failure probability as described in
%     Schobi et al, 2016, Rare event estimation using Polynomial-Chaos-Kriging,
%     ASCE-ASME Journal of Risk and Uncertainty in Engineering Systems, PArt A:
%     Civil Engineering, D4016002
% 
% See also: UQ_AKMCS, UQ_AKMCS_STOPU, UQ_AKMCS_STOPPF

gmean = CurrentAnalysis.Internal.Runtime.gmean;
gs = CurrentAnalysis.Internal.Runtime.gs;
g = CurrentAnalysis.Internal.Runtime.g;

MCSampleSize = length(gmean) + length(CurrentAnalysis.Internal.Runtime.g(CurrentAnalysis.Internal.AKMCS.IExpDesign.N+1:end)); 

%Estimate the current Pf and Pf+ and Pf-
Pf = (sum(gmean <= 0) + sum(g(CurrentAnalysis.Internal.AKMCS.IExpDesign.N+1:end) <= 0))/MCSampleSize;
Beta = -norminv(Pf);
Pfplus = (sum(gmean-1.96*gs <= 0) + sum(g(CurrentAnalysis.Internal.AKMCS.IExpDesign.N+1:end) <= 0))/MCSampleSize;
BetaMinus = -norminv(Pfplus);

Pfminus = (sum(gmean+1.96*gs <= 0) + sum(g(CurrentAnalysis.Internal.AKMCS.IExpDesign.N+1:end) <= 0))/MCSampleSize;
BetaPlus = -norminv(Pfminus);

delta = 0.05;

%Check whether convergence has been reached for the second time in a row
if isfield(CurrentAnalysis.Internal.Runtime, 'Betastop')
    if (BetaPlus-BetaMinus)/ Beta <= delta && CurrentAnalysis.Internal.Runtime.Betastop == 1
        status = 1;
    else
        if (BetaPlus-BetaMinus)/ Beta <= delta
            status = 0;
            CurrentAnalysis.Internal.Runtime.Betastop = 1;
        else
            status = 0;
            CurrentAnalysis.Internal.Runtime.Betastop = 1;
        end
    end
else
    if (BetaPlus-BetaMinus)/ Beta <= delta
        CurrentAnalysis.Internal.Runtime.Betastop = 1;
        status = 0;
    else
        status = 0;
        CurrentAnalysis.Internal.Runtime.Betastop = 0;
    end
end