function c = uq_cmaesnonlconwrapper( d, current_analysis )
% Wrapper of the constraintgs with format appropriate c(1+1)-CMA-ES

% Hard constraints
switch lower( current_analysis.Internal.Method )
    case {'two level', 'two-level', 'ria', 'pma','qmc'}
        hc = uq_twolevel_evalConstraints( d, current_analysis ) ;
    case {'decoupled', 'sora'}
        hc = uq_sora_evalShiftedConstraint( d, current_analysis ) ;
    case 'sla'
        hc = uq_sla_evalConstraints( d, current_analysis ) ;
    case 'deterministic'
        hc = uq_deterministic_evalConstraints(d, current_analysis) ;
end
% Soft constraints
sc = [] ;
if isfield(current_analysis.Internal.Constraints,'SoftConstModel')
    sc = uq_evalSoftConstraint(d, current_analysis ) ;
end
c = [ hc sc] ;

%% RECORDING 
% Save current model response in terms of Pf, beta and g (if deterministic)
current_analysis.Internal.Runtime.isnewpoint = true ;
% Hard constraint
RecordedConstraints = uq_recordconstraints( hc, current_analysis ) ;
current_analysis.Internal.Runtime.RecordedConstraints = [current_analysis.Internal.Runtime.RecordedConstraints; RecordedConstraints ] ;

% Soft constraints
current_analysis.Internal.Runtime.RecordedSoftConstraints = [current_analysis.Internal.Runtime.RecordedSoftConstraints; sc] ;

% Save this point as previous one for further use (Necessary for CMA-ES?)
current_analysis.Internal.Runtime.previousd = d ;


end
