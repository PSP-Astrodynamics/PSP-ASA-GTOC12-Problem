function g_X = uq_sora_evalConstraints(d, current_analysis)
Options = current_analysis.Internal ;
Md = length(Options.Input.DesVar) ;
for jj= 1:size( current_analysis.Internal.Runtime.MPTP, 3)
    Xmptp = current_analysis.Internal.Runtime.MPTP(1, 1 : Md, jj ) ;
    Zmptp = current_analysis.Internal.Runtime.MPTP( 1,Md+1 : end, jj ) ;
    s = current_analysis.Internal.Runtime.dStar - Xmptp ;
    ShiftedX = [d - s, Zmptp] ;
    Ytemp(jj,:) = uq_evalModel(current_analysis.Internal.Constraints.Model, ShiftedX ) ;
end
if size(Ytemp,1) > 1
    M_X = diag(Ytemp)' ;
else
    M_X = Ytemp ;
end
% Limit-state options
LSOptions = Options.LimitState ;
TH = LSOptions.Threshold ;
% Determine the failures:
switch LSOptions.CompOp
    case {'<', '<=', 'leq'}
        g_X = M_X  - repmat(TH,size(M_X,1),1);
        
    case {'>', '>=', 'geq'}
        g_X = repmat(TH,size(M_X,1),1) - M_X;
end
% Update the number of model evaluations
current_analysis.Internal.Runtime.ModelEvaluations = ...
    current_analysis.Internal.Runtime.ModelEvaluations + sum(size(Ytemp)) ;
end