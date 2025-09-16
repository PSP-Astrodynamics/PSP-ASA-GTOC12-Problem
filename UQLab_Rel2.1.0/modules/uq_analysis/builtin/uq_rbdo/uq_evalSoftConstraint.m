function Y = uq_evalSoftConstraint(X, current_analysis )
% UQ_EVALSOFTCONSTRAINTS evaluates the soft constraints for an optimization
% problem

Y = uq_evalModel( current_analysis.Internal.Constraints.SoftConstModel, X ) ;
end