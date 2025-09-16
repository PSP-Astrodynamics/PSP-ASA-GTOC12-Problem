function status = uq_activeMeta_stopLF(current_analysis)
% status = UQ_ACTIVEMETA_STOPLF(current_analysis) computes stopping
%     with respect to the learning function
%

% See also: UQ_AKMCS_STOPU, UQ_ACTIVEMETA_STOPBETA, UQ_ACTIVEMETA_STOPPF

lf = current_analysis.Internal.Runtime.lf;

switch lower(current_analysis.Internal.Metamodel.Enrichment.LearningFunction)
    
    case 'u'
        crit = min (-lf) ;
        if crit >= 2
            status = 1 ;
        else
            status = 0 ;
        end
    case 'eff'
        crit = max(lf) ;
        if crit <= 1e-3
            status = 1 ;
        else
            status = 0 ;
        end            
        
    case 'cmm'
        
    case 'fbr'
        
    otherwise
        
end

current_analysis.Internal.Runtime.Conv = crit ;

end