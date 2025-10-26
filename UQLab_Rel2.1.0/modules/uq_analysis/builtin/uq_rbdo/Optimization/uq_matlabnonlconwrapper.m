function [c, ceq] = uq_matlabnonlconwrapper( d, current_analysis )
% Wrapper with format appropriate for using fmincon and ga in matlab

% Check whether the point is new or not for further processing (e.g.
% computation of alpha vector in SLA or recording of the constraints)
% [isnewpoint,isfirstiteration] = uq_IsDesignNew( d, current_analysis ) ;
% Save this for use in other functions
if ~isfield(current_analysis.Internal.Runtime,'isfirstiteration') || ...
        isempty(current_analysis.Internal.Runtime.isfirstiteration)
    current_analysis.Internal.Runtime.isfirstiteration = true ;
    current_analysis.Internal.Runtime.isnewpoint = true ;
    % Use first point lock to make sure that once a point has been defined
    % as not initial point, it won't be changed again
    current_analysis.Internal.Runtime.firstpointlock = true ;
else
    % A point is not first point if it is also defined as a new point
    % (finite difference points are not considered as new points)
    %     if current_analysis.Internal.Runtime.firstpointlock && current_analysis.Internal.Runtime.isnewpoint
    %         current_analysis.Internal.Runtime.isfirstiteration = false ;
    %         current_analysis.Internal.Runtime.firstpointlock = false ;
    %
    %     end
    if  current_analysis.Internal.Runtime.isnewpoint
        current_analysis.Internal.Runtime.isfirstiteration = false ;
    end
end
isnewpoint = current_analysis.Internal.Runtime.isnewpoint ;

switch lower( current_analysis.Internal.Method )
    case {'two level', 'two-level', 'ria', 'pma','qmc'}
        % For two-level, ria, pma: c = bar(beta) - b or bar(Pf) - Pf
        % For qmc, ...
        % For two level and REliabiliy = iform, c = -Gmptp
        hc = uq_twolevel_evalConstraints( d, current_analysis ) ;

    case {'decoupled', 'sora'}
        g_X = uq_sora_evalConstraints( d, current_analysis ) ;
        % Use the opposite, as for matlab the constraint is s.t. nonlcon <
        % 0 while in uq failure is g_x < 0
        hc = - g_X ;

    case 'sla'
        g_X = uq_sla_evalConstraints( d, current_analysis ) ;
        % Use the opposite, as for matlab the constraint is s.t. nonlcon <
        % 0 while in uq failure is g_x < 0
        hc = - g_X ;

    case 'deterministic'
        g_X = uq_deterministic_evalConstraints(d, current_analysis) ;
        hc = - g_X ;

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

% set back isnewpoint flag to false. It will be changed as soon as the
% persistent variable History changes size
current_analysis.Internal.Runtime.isnewpoint = false ;

% No equality constraints (It is necessary to use [] though for Matlab
% optimizer)
ceq = [] ;
end
