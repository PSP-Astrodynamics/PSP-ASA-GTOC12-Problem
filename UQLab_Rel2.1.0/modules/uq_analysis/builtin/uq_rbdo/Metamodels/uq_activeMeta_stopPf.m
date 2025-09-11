function status = uq_activeMeta_stopPf(current_analysis)
% status = UQ_AKMCS_STOPPF(current_analysis) computes stopping criterion
%     with respect to the estimated failure probability as described in
%     Schobi et al, 2016, Rare event estimation using Polynomial-Chaos-Kriging,
%     ASCE-ASME Journal of Risk and Uncertainty in Engineering Systems, PArt A:
%     Civil Engineering, D4016002
%
% The only differenc ewith uq_akmcs_stopPf is that the threshold is an
% option the user can set
% See also: UQ_AKMCS_STOPPF, UQ_ACTIVEMETA_STOPBETA, UQ_ACTIVEMETA_STOPDF

gmean = current_analysis.Internal.Runtime.gmean;
gs = current_analysis.Internal.Runtime.gs;
% g = current_analysis.Internal.Runtime.g;

% MCSampleSize = length(gmean) + length(current_analysis.Internal.Runtime.g(current_analysis.Internal.AKMCS.IExpDesign.N+1:end));
%
% %Estimate the current Pf and Pf+ and Pf-
% Pf = (sum(gmean <= 0) + sum(g(current_analysis.Internal.AKMCS.IExpDesign.N+1:end) <= 0))/MCSampleSize;
% Pfplus = (sum(gmean-2*gs <= 0) + sum(g(current_analysis.Internal.AKMCS.IExpDesign.N+1:end) <= 0))/MCSampleSize;
% Pfminus = (sum(gmean+2*gs <= 0) + sum(g(current_analysis.Internal.AKMCS.IExpDesign.N+1:end) <= 0))/MCSampleSize;

MCSampleSize = length(gmean) ;

%Estimate the current Pf and Pf+ and Pf-
Pf = sum(gmean <= 0) /MCSampleSize ;
Pfplus = sum(gmean-1.96*gs <= 0) /MCSampleSize;
Pfminus = sum(gmean+1.96*gs <= 0) /MCSampleSize;

crit = mean( (Pfplus-Pfminus)./ Pf );
delta = current_analysis.Internal.Metamodel.Enrichment.ConvThreshold ;

% Check whether convergence has been reached for the second time in a row
if isfield(current_analysis.Internal.Runtime, 'Pfstop')
    if crit <= delta && current_analysis.Internal.Runtime.Pfstop == 1
        status = 1;
    else if  crit <= delta
            status = 0;
            current_analysis.Internal.Runtime.Pfstop = 1;
        else
            status = 0;
            current_analysis.Internal.Runtime.Pfstop = 0;
        end
    end
else
    if crit <= delta
        current_analysis.Internal.Runtime.Pfstop = 1;
        status = 0;
    else
        status = 0;
        current_analysis.Internal.Runtime.Pfstop = 0;
    end
end

current_analysis.Internal.Runtime.Conv = crit ;

end