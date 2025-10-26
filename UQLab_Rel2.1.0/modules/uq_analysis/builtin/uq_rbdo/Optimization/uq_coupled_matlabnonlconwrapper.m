function [c, ceq] = uq_coupled_matlabnonlconwrapper( d, current_analysis )
% Wrapper with format appropriate for using fmincon and ga in matlab

% Check whether the point is new or not for further processing (e.g.
% computation of alpha vector in SLA or recording of the constraints)
% [isnewpoint,isfirstiteration] = uq_IsDesignNew( d, current_analysis ) ;
% Save this for use in other functions
if ~isfield(current_analysis.Internal.Runtime,'isfirstiteration') || ...
        isempty(current_analysis.Internal.Runtime.isfirstiteration)
    current_analysis.Internal.Runtime.isfirstiteration = true ;
    current_analysis.Internal.Runtime.isnewpoint = true ;
else
    current_analysis.Internal.Runtime.isfirstiteration = false ;
end
isnewpoint = current_analysis.Internal.Runtime.isnewpoint ;

switch lower( current_analysis.Internal.Method )
    % For now only available when using Simulation-base ddouble loop
    % methods
    case {'two level', 'two-level','qmc'}
        % For two-level, ria, pma: c = bar(beta) - b or bar(Pf) - Pf
        % For qmc, ...
        hc = uq_twolevel_evalConstraints( d, current_analysis ) ;
        
        
        % May be will extend for deterministic optimization at some point
        %     case 'deterministic'
        %         g_X = uq_deterministic_evalConstraints(d, current_analysis) ;
        %         hc = - g_X ;
        
end
% Soft constraints
sc = [] ;
if isfield(current_analysis.Internal.Constraints,'SoftConstModel')
    sc = uq_evalSoftConstraint(d, current_analysis ) ;
end
c = [hc,   sc] ;

%% RECORDING
% Save current model response in terms of Pf, beta and g (if deterministic)
if isnewpoint
    % Hard constraints
    RecordedConstraints = uq_recordconstraints( hc, current_analysis ) ;
    current_analysis.Internal.Runtime.RecordedConstraints = [current_analysis.Internal.Runtime.RecordedConstraints; RecordedConstraints ] ;
    % Soft constraints
    current_analysis.Internal.Runtime.RecordedSoftConstraints = [current_analysis.Internal.Runtime.RecordedSoftConstraints; sc ] ;
    
    % Save this point as previous one for further use
    current_analysis.Internal.Runtime.previousd = d ;
end

% Now check that the point satisfies
if isnewpoint
    crit = uq_computeBetaBounds(d, hc,current_analysis) ;
    
    %     if crit > current_analysis.Internal.Metamodel.Enrichment.LocalConvThreshold
    if crit > 0.1
        % This means we need to do enrichment
        current_analysis.Internal.Runtime.RestartFminCon = true ;
        current_analysis.Internal.Runtime.CurrentXC = ...
            current_analysis.Internal.Runtime.XC ;
    end
    
end
% set back isnewpoint flag to false. It will be changed as soon as the
% persistent variable History changes size
current_analysis.Internal.Runtime.isnewpoint = false ;

% Now check that
% No equality constraints (It is necessary to use [] though for Matlab
% optimizer)
ceq = [] ;
end
