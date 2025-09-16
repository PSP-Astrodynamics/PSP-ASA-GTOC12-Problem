function status = uq_activeMeta_stopSign(current_analysis)
% status = UQ_ACTIVEMETA_STOPLF(current_analysis) computes stopping
%     with respect to sign change within successive iterations on
%     the metamodel predictions
%

% See also: UQ_AKMCS_STOPU, UQ_ACTIVEMETA_STOPBETA, UQ_ACTIVEMETA_STOPPF

% Stopping criterion threshold
delta = current_analysis.Internal.Metamodel.Enrichment.ConvThreshold ;
gmean = current_analysis.Internal.Runtime.gmean ;

% Get the criterion value in the previous step if one exists already
if isfield(current_analysis.Internal.Metamodel.Enrichment, 'Conv') ...
        && size( current_analysis.Internal.Metamodel.Enrichment.Conv,2) >= current_analysis.Internal.Runtime.CritNum
    
    if current_analysis.Internal.Runtime.CritNum == 1
        % in this case just check the last line
        crit_prev = current_analysis.Internal.Metamodel.Enrichment.Conv(end,current_analysis.Internal.Runtime.CritNum) ;
    else
        % The last line is partially filled and correspond to the current
        % iteration, so check the l'avant dernière line
        crit_prev = current_analysis.Internal.Metamodel.Enrichment.Conv(end-1,current_analysis.Internal.Runtime.CritNum) ;
    end
    
end
if isfield(current_analysis.Internal.Runtime, 'gmean_prev')
    gmean_prev = current_analysis.Internal.Runtime.gmean_prev;
    
    crit = mean(sum(gmean_prev .* gmean < 0)) / length(gmean) ;
% crit = sum( sum(gmean_prev .* gmean < 0,2) ) / length(gmean)
    if crit <= delta && crit_prev <= delta
        status = 1 ;
    else
        status = 0 ;
    end
else
    % First iteration. Can't compute sign change
    crit = NaN ;
    status = 0 ;
end

% To save history of enrichment criterion
current_analysis.Internal.Runtime.Conv = crit ;

end